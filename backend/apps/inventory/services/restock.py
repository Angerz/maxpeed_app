from django.db import transaction
from django.utils import timezone

from apps.inventory.models import InventoryCondition, InventoryItem, PriceRecord, PriceType
from apps.inventory.services.core import set_current_price
from apps.purchases.models import StockReceipt, StockReceiptLine


class RestockConflictError(Exception):
    pass


@transaction.atomic
def restock_inventory_item(*, inventory_item_id, quantity, unit_purchase_price, suggested_sale_price, notes=None, user=None):
    inventory_item = (
        InventoryItem.objects.select_for_update()
        .select_related("catalog_item", "owner")
        .filter(id=inventory_item_id, is_active=True)
        .first()
    )
    if inventory_item is None:
        return None

    if inventory_item.condition == InventoryCondition.USED:
        raise RestockConflictError("Restock is currently restricted to NEW inventory items.")

    stock_before = inventory_item.stock
    occurred_at = timezone.now()

    receipt = StockReceipt.objects.create(
        supplier_name=None,
        received_at=occurred_at,
        notes=notes,
        created_by=user,
    )
    receipt_line = StockReceiptLine.objects.create(
        receipt=receipt,
        inventory_item=inventory_item,
        quantity=quantity,
        unit_cost=unit_purchase_price,
        notes=notes,
    )

    purchase_record = PriceRecord.objects.select_for_update().get(
        inventory_item=inventory_item,
        price_type=PriceType.PURCHASE,
        valid_to__isnull=True,
    )
    suggested_sale_record = set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.SUGGESTED_SALE,
        amount=suggested_sale_price,
        user=user,
        valid_from=occurred_at,
    )

    inventory_item.refresh_from_db(fields=["stock", "last_restock_at"])
    return {
        "inventory_item_id": inventory_item.id,
        "stock_before": stock_before,
        "stock_after": inventory_item.stock,
        "purchase_price_current": purchase_record.amount,
        "suggested_sale_price_current": suggested_sale_record.amount,
        "receipt_id": receipt.id,
        "receipt_line_id": receipt_line.id,
        "movement_id": receipt_line.movement_id,
        "last_restock_at": inventory_item.last_restock_at,
    }
