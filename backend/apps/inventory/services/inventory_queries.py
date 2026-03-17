from collections import OrderedDict

from apps.catalog.choices import ProductCategory
from apps.inventory.models import InventoryItem, PriceRecord, PriceType


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


def _resolve_brand_images(brand):
    if not brand:
        return None, None
    full = brand.logo_image_full or brand.logo_image
    thumb = brand.logo_image_thumb or full
    return full, thumb


def get_effective_price(inventory_item, price_type, fallback_last=True):
    current = (
        PriceRecord.objects.filter(
            inventory_item=inventory_item,
            price_type=price_type,
            valid_to__isnull=True,
        )
        .order_by("-valid_from", "-created_at")
        .first()
    )
    if current:
        return current
    if not fallback_last:
        return None
    return (
        PriceRecord.objects.filter(
            inventory_item=inventory_item,
            price_type=price_type,
        )
        .order_by("-valid_from", "-created_at")
        .first()
    )


def get_inventory_cards_grouped_by_rim(*, include_zero_stock=False):
    queryset = (
        InventoryItem.objects.filter(
            catalog_item__product_category=ProductCategory.TIRE,
            is_active=True,
        )
        .select_related(
            "catalog_item",
            "catalog_item__brand",
            "catalog_item__brand__logo_image",
            "catalog_item__brand__logo_image_full",
            "catalog_item__brand__logo_image_thumb",
            "catalog_item__tire_spec",
            "owner",
        )
        .order_by("catalog_item__tire_spec__rim_diameter", "catalog_item__code", "id")
    )

    if not include_zero_stock:
        queryset = queryset.filter(stock__gt=0)

    grouped_cards = {}
    for inventory_item in queryset:
        tire_spec = getattr(inventory_item.catalog_item, "tire_spec", None)
        brand_full, brand_thumb = _resolve_brand_images(inventory_item.catalog_item.brand)
        rim = tire_spec.rim_diameter if tire_spec else "UNKNOWN"
        details = " | ".join(
            part
            for part in [
                inventory_item.catalog_item.origin,
                tire_spec.ply_rating if tire_spec else None,
                tire_spec.tread_type if tire_spec else None,
            ]
            if part
        )
        grouped_cards.setdefault(rim, []).append(
            {
                "inventory_item_id": inventory_item.id,
                "code": inventory_item.catalog_item.code,
                "brand": inventory_item.catalog_item.brand.name if inventory_item.catalog_item.brand else None,
                "stock": inventory_item.stock,
                "details": details,
                "owner": {"id": inventory_item.owner.id, "name": inventory_item.owner.name},
                "image": _build_image_ref(brand_full),
                "image_thumb": _build_image_ref(brand_thumb),
            }
        )

    ordered = OrderedDict()
    for rim in sorted(grouped_cards.keys(), key=_rim_sort_key):
        ordered[rim] = grouped_cards[rim]
    return ordered


def get_inventory_item_detail_payload(inventory_item):
    catalog_item = inventory_item.catalog_item
    tire_spec = getattr(catalog_item, "tire_spec", None)
    rim_spec = getattr(catalog_item, "rim_spec", None)

    detail_parts = [
        catalog_item.origin,
        tire_spec.ply_rating if tire_spec else None,
        tire_spec.tread_type if tire_spec else None,
    ]
    if catalog_item.model:
        detail_parts.append(catalog_item.model)
    detail_parts.append(tire_spec.letter_color if tire_spec else None)
    details = " | ".join(str(part) for part in detail_parts if part)

    # For stock > 0 we require current price, for stock = 0 we fallback to last historical.
    fallback_last = inventory_item.stock == 0
    purchase = get_effective_price(inventory_item, PriceType.PURCHASE, fallback_last=fallback_last)
    suggested = get_effective_price(
        inventory_item,
        PriceType.SUGGESTED_SALE,
        fallback_last=fallback_last,
    )

    if catalog_item.product_category == ProductCategory.RIM:
        full = (rim_spec.photo_image_full if rim_spec else None) or (rim_spec.photo_image if rim_spec else None)
        thumb = (rim_spec.photo_image_thumb if rim_spec else None) or full
        if full is None:
            full, thumb = _resolve_brand_images(catalog_item.brand)
    else:
        full, thumb = _resolve_brand_images(catalog_item.brand)

    return {
        "inventory_item_id": inventory_item.id,
        "code": catalog_item.code,
        "tire_type": tire_spec.tire_type if tire_spec else None,
        "brand": catalog_item.brand.name if catalog_item.brand else None,
        "stock": inventory_item.stock,
        "owner": {"id": inventory_item.owner.id, "name": inventory_item.owner.name},
        "details": details,
        "purchase_price": purchase.amount if purchase else None,
        "suggested_sale_price": suggested.amount if suggested else None,
        "last_restock_at": inventory_item.last_restock_at,
        "created_at": inventory_item.created_at,
        "updated_at": inventory_item.updated_at,
        "image": _build_image_ref(full),
        "image_thumb": _build_image_ref(thumb),
    }
