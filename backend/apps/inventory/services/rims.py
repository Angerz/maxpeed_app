from collections import OrderedDict

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.catalog.choices import ItemKind, ProductCategory
from apps.catalog.models import CatalogItem, RimSpec, build_rim_sku
from apps.inventory.models import InventoryCondition, InventoryItem, PriceRecord, PriceType
from apps.inventory.services.core import set_current_price
from apps.purchases.models import StockReceipt, StockReceiptLine


class RimSpecConflictError(Exception):
    pass


class RimDeactivateForbiddenError(Exception):
    pass


class RimDeactivateValidationError(Exception):
    pass


def _build_unique_rim_sku(*, brand_name, internal_code):
    base_sku = build_rim_sku(brand_name=brand_name, internal_code=internal_code)
    candidate = base_sku
    suffix = 1
    while CatalogItem.objects.filter(sku=candidate).exists():
        suffix += 1
        candidate = f"{base_sku[:57]}-{suffix}"[:64]
    return candidate


def _rim_sort_key(rim_value):
    if not rim_value:
        return 999
    try:
        return int(str(rim_value).replace("R", ""))
    except ValueError:
        return 999


def _build_image_ref(image):
    if image is None:
        return None
    return {"id": image.id, "url": f"/api/images/{image.id}/"}


@transaction.atomic
def create_rim_stock_receipt(*, payload, user=None):
    now = timezone.now()
    internal_code = payload["internal_code"].strip()

    existing_catalog = (
        CatalogItem.objects.select_for_update()
        .filter(
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.RIM,
            brand=payload["brand"],
            code=internal_code,
        )
        .filter(Q(model__isnull=True) | Q(model=""))
        .first()
    )

    created_new_catalog_item = False

    if existing_catalog:
        rim_spec = getattr(existing_catalog, "rim_spec", None)
        if rim_spec is None:
            raise RimSpecConflictError("Existing rim catalog item has no RimSpec.")

        incoming_signature = (
            payload["rim_diameter"],
            int(payload["holes"]),
            int(payload["width_in"]),
            payload["material"],
            payload["is_set"],
        )
        current_signature = (
            rim_spec.rim_diameter,
            rim_spec.holes,
            rim_spec.width_in,
            rim_spec.material,
            rim_spec.is_set,
        )
        if incoming_signature != current_signature:
            raise RimSpecConflictError(
                "internal_code already exists with different rim specs."
            )
        if payload.get("photo_image") is not None:
            rim_spec.photo_image = payload["photo_image"]
            rim_spec.save(update_fields=["photo_image"])
        catalog_item = existing_catalog
    else:
        catalog_item = CatalogItem.objects.create(
            sku=_build_unique_rim_sku(
                brand_name=payload["brand"].name,
                internal_code=internal_code,
            ),
            code=internal_code,
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.RIM,
            brand=payload["brand"],
            model=None,
            origin=None,
            is_active=True,
        )
        RimSpec.objects.create(
            catalog_item=catalog_item,
            rim_diameter=payload["rim_diameter"],
            holes=payload["holes"],
            width_in=payload["width_in"],
            material=payload["material"],
            is_set=payload["is_set"],
            photo_image=payload.get("photo_image"),
        )
        created_new_catalog_item = True

    inventory_item, _ = InventoryItem.objects.select_for_update().get_or_create(
        catalog_item=catalog_item,
        condition=InventoryCondition.NEW,
        owner=payload["owner"],
        defaults={"stock": 0, "is_active": True},
    )

    receipt = StockReceipt.objects.create(
        supplier_name=None,
        received_at=now,
        notes=payload.get("notes"),
        created_by=user,
    )
    receipt_line = StockReceiptLine.objects.create(
        receipt=receipt,
        inventory_item=inventory_item,
        quantity=payload["quantity"],
        unit_cost=payload["unit_purchase_price"],
        notes=payload.get("notes"),
    )

    purchase_record = PriceRecord.objects.select_for_update().get(
        inventory_item=inventory_item,
        price_type=PriceType.PURCHASE,
        valid_to__isnull=True,
    )
    suggested_sale_record = set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.SUGGESTED_SALE,
        amount=payload["suggested_sale_price"],
        user=user,
        valid_from=now,
    )

    inventory_item.refresh_from_db(fields=["stock"])
    return {
        "inventory_item_id": inventory_item.id,
        "catalog_item_id": catalog_item.id,
        "created_new_catalog_item": created_new_catalog_item,
        "stock_after": inventory_item.stock,
        "prices_current": {
            "purchase": purchase_record.amount,
            "suggested_sale": suggested_sale_record.amount,
        },
        "receipt_id": receipt.id,
        "receipt_line_id": receipt_line.id,
        "movement_id": receipt_line.movement_id,
    }


def get_rim_inventory_cards_grouped():
    queryset = (
        InventoryItem.objects.filter(
            catalog_item__product_category=ProductCategory.RIM,
            condition=InventoryCondition.NEW,
            stock__gt=0,
            is_active=True,
        )
        .select_related(
            "catalog_item",
            "catalog_item__brand",
            "catalog_item__brand__logo_image",
            "catalog_item__rim_spec",
            "catalog_item__rim_spec__photo_image",
            "owner",
        )
        .order_by("catalog_item__rim_spec__rim_diameter", "catalog_item__code", "id")
    )

    grouped_cards = {}
    for inventory_item in queryset:
        rim_spec = inventory_item.catalog_item.rim_spec
        rim = rim_spec.rim_diameter
        set_label = "SET" if rim_spec.is_set else "SINGLE"
        resolved_image = rim_spec.photo_image or (
            inventory_item.catalog_item.brand.logo_image
            if inventory_item.catalog_item.brand
            else None
        )
        grouped_cards.setdefault(rim, []).append(
            {
                "inventory_item_id": inventory_item.id,
                "internal_code": inventory_item.catalog_item.code,
                "brand": inventory_item.catalog_item.brand.name if inventory_item.catalog_item.brand else None,
                "stock": inventory_item.stock,
                "details": f"{rim_spec.material} | {rim_spec.holes}H | {rim_spec.width_in}IN | {set_label}",
                "owner": {"id": inventory_item.owner.id, "name": inventory_item.owner.name},
                "image": _build_image_ref(resolved_image),
            }
        )

    ordered = OrderedDict()
    for rim in sorted(grouped_cards.keys(), key=_rim_sort_key):
        ordered[rim] = grouped_cards[rim]
    return ordered


@transaction.atomic
def deactivate_rim_inventory_item(*, inventory_item_id, reason=None, notes=None, user=None):
    inventory_item = (
        InventoryItem.objects.select_for_update()
        .select_related("catalog_item", "owner")
        .filter(id=inventory_item_id)
        .first()
    )
    if inventory_item is None:
        return None

    if inventory_item.catalog_item.product_category != ProductCategory.RIM:
        raise RimDeactivateValidationError("Only RIM inventory items can be deactivated with this endpoint.")

    if inventory_item.owner.name.upper() != "ALDO":
        raise RimDeactivateForbiddenError("Only ALDO-owned rim inventory can be deactivated.")

    if not inventory_item.is_active:
        return {
            "inventory_item_id": inventory_item.id,
            "is_active": inventory_item.is_active,
            "deactivated_at": inventory_item.deactivated_at,
            "owner": {"id": inventory_item.owner.id, "name": inventory_item.owner.name},
            "message": "already inactive",
        }

    inventory_item.is_active = False
    inventory_item.deactivated_at = timezone.now()
    inventory_item.save(update_fields=["is_active", "deactivated_at", "updated_at"])

    return {
        "inventory_item_id": inventory_item.id,
        "is_active": inventory_item.is_active,
        "deactivated_at": inventory_item.deactivated_at,
        "owner": {"id": inventory_item.owner.id, "name": inventory_item.owner.name},
        "message": "deactivated",
    }
