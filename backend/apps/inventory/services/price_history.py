from apps.catalog.choices import ProductCategory
from apps.inventory.models import PriceRecord, PriceType

from .inventory_queries import get_effective_price


class PurchasePriceHistoryValidationError(Exception):
    pass


def get_purchase_price_history(inventory_item):
    if inventory_item.catalog_item.product_category != ProductCategory.TIRE:
        raise PurchasePriceHistoryValidationError(
            "Purchase price history is only available for tire inventory items."
        )

    latest_twenty = list(
        PriceRecord.objects.filter(
            inventory_item=inventory_item,
            price_type=PriceType.PURCHASE,
        )
        .order_by("-valid_from", "-created_at")[:20]
    )
    latest_twenty.reverse()
    amounts = [record.amount for record in latest_twenty]

    current = get_effective_price(
        inventory_item=inventory_item,
        price_type=PriceType.PURCHASE,
        fallback_last=True,
    )

    if amounts:
        stats = {
            "min": min(amounts),
            "max": max(amounts),
            "avg": sum(amounts) / len(amounts),
        }
    else:
        stats = {"min": None, "max": None, "avg": None}

    return {
        "inventory_item_id": inventory_item.id,
        "code": inventory_item.catalog_item.code,
        "brand": inventory_item.catalog_item.brand.name if inventory_item.catalog_item.brand else None,
        "current_purchase_price": current.amount if current else None,
        "stats": stats,
        "points": [{"date": record.valid_from, "amount": record.amount} for record in latest_twenty],
    }
