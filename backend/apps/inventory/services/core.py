from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from apps.inventory.models import InventoryItem, InventoryMovement, MovementType, PriceRecord


@transaction.atomic
def set_current_price(inventory_item, price_type, amount, user=None, valid_from=None):
    valid_from = valid_from or timezone.now()

    current_record = (
        PriceRecord.objects.select_for_update()
        .filter(
            inventory_item=inventory_item,
            price_type=price_type,
            valid_to__isnull=True,
        )
        .first()
    )

    if current_record:
        current_record.valid_to = valid_from
        current_record.full_clean()
        current_record.save(update_fields=["valid_to"])

    new_record = PriceRecord(
        inventory_item=inventory_item,
        price_type=price_type,
        amount=amount,
        valid_from=valid_from,
        created_by=user,
    )
    new_record.full_clean()
    new_record.save()
    return new_record


@transaction.atomic
def apply_inventory_movement(
    *,
    inventory_item,
    movement_type,
    quantity,
    unit_cost=None,
    occurred_at=None,
    reference_type=None,
    reference_id=None,
    notes=None,
    created_by=None,
):
    occurred_at = occurred_at or timezone.now()
    locked_item = InventoryItem.objects.select_for_update().get(pk=inventory_item.pk)

    movement = InventoryMovement(
        inventory_item=locked_item,
        movement_type=movement_type,
        quantity=quantity,
        unit_cost=unit_cost,
        occurred_at=occurred_at,
        reference_type=reference_type,
        reference_id=reference_id,
        notes=notes,
        created_by=created_by,
    )
    movement.full_clean()

    new_stock = locked_item.stock + quantity
    if new_stock < 0:
        raise ValidationError({"quantity": "Movement would leave stock below zero."})

    locked_item.stock = new_stock
    if movement_type in MovementType.inbound_values():
        locked_item.last_restock_at = occurred_at
    locked_item.full_clean()
    locked_item.save(update_fields=["stock", "last_restock_at", "updated_at"])

    movement.save()
    inventory_item.stock = locked_item.stock
    inventory_item.last_restock_at = locked_item.last_restock_at
    return movement
