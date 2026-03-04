from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.catalog.choices import ItemKind, ProductCategory
from apps.catalog.models import CatalogItem, TireSpec, build_tire_sku
from apps.inventory.models import InventoryCondition, InventoryItem, PriceRecord, PriceType
from apps.inventory.services import set_current_price
from apps.purchases.models import StockReceipt, StockReceiptLine


def _normalized_model(value):
    if value is None:
        return None
    value = value.strip()
    return value or None


def _build_unique_sku(*, brand_name, width, rim_diameter, model=None, aspect_ratio=None):
    base_sku = build_tire_sku(
        brand_name=brand_name,
        width=width,
        rim_diameter=rim_diameter,
        model=model,
        aspect_ratio=aspect_ratio,
    )
    candidate = base_sku
    suffix = 1

    while CatalogItem.objects.filter(sku=candidate).exists():
        suffix += 1
        candidate = f"{base_sku[:57]}-{suffix}"[:64]

    return candidate


@transaction.atomic
def create_tire_stock_receipt(*, payload, user=None):
    normalized_model = _normalized_model(payload.get("model"))
    occurred_at = timezone.now()

    tire_query = CatalogItem.objects.select_for_update().filter(
        item_kind=ItemKind.MERCHANDISE,
        product_category=ProductCategory.TIRE,
        brand=payload["brand"],
        origin=payload["origin"],
    )
    if normalized_model is None:
        tire_query = tire_query.filter(Q(model__isnull=True) | Q(model=""))
    else:
        tire_query = tire_query.filter(model=normalized_model)

    tire_query = tire_query.filter(
        tire_spec__tire_type=payload["tire_type"],
        tire_spec__width=payload["width"],
        tire_spec__aspect_ratio=payload.get("aspect_ratio"),
        tire_spec__rim_diameter=payload["rim_diameter"],
        tire_spec__ply_rating=payload["ply_rating"],
        tire_spec__tread_type=payload["tread_type"],
        tire_spec__letter_color=payload["letter_color"],
    )

    catalog_item = tire_query.first()
    created_new_catalog_item = False

    if catalog_item is None:
        catalog_item = CatalogItem.objects.create(
            sku=_build_unique_sku(
                brand_name=payload["brand"].name,
                width=payload["width"],
                aspect_ratio=payload.get("aspect_ratio"),
                rim_diameter=payload["rim_diameter"],
                model=normalized_model,
            ),
            code=TireSpec.build_code_from_spec(
                width=payload["width"],
                aspect_ratio=payload.get("aspect_ratio"),
                rim_diameter=payload["rim_diameter"],
            ),
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.TIRE,
            brand=payload["brand"],
            model=normalized_model,
            origin=payload["origin"],
        )
        TireSpec.objects.create(
            catalog_item=catalog_item,
            tire_type=payload["tire_type"],
            width=payload["width"],
            aspect_ratio=payload.get("aspect_ratio"),
            rim_diameter=payload["rim_diameter"],
            ply_rating=payload["ply_rating"],
            tread_type=payload["tread_type"],
            letter_color=payload["letter_color"],
        )
        created_new_catalog_item = True

    inventory_item, _ = InventoryItem.objects.select_for_update().get_or_create(
        catalog_item=catalog_item,
        condition=InventoryCondition.NEW,
        defaults={"stock": 0, "is_active": True},
    )

    receipt = StockReceipt.objects.create(
        supplier_name=None,
        received_at=occurred_at,
        created_by=user,
    )
    StockReceiptLine.objects.create(
        receipt=receipt,
        inventory_item=inventory_item,
        quantity=payload["quantity"],
        unit_cost=payload["unit_purchase_price"],
    )

    purchase_record = PriceRecord.objects.select_for_update().get(
        inventory_item=inventory_item,
        price_type=PriceType.PURCHASE,
        valid_to__isnull=True,
    )
    suggested_sale_record = set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.SUGGESTED_SALE,
        amount=payload["recommended_sale_price"],
        user=user,
        valid_from=occurred_at,
    )

    inventory_item.refresh_from_db(fields=["stock"])

    return {
        "receipt_id": receipt.id,
        "catalog_item_id": catalog_item.id,
        "inventory_item_id": inventory_item.id,
        "stock_after": inventory_item.stock,
        "prices_current": {
            "purchase": purchase_record.amount,
            "suggested_sale": suggested_sale_record.amount,
        },
        "created_new_catalog_item": created_new_catalog_item,
    }
