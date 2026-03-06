from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils import timezone

from apps.inventory.models import MovementType, PriceType
from apps.inventory.services.core import apply_inventory_movement, set_current_price


class StockReceipt(models.Model):
    supplier_name = models.CharField(max_length=120, null=True, blank=True)
    received_at = models.DateTimeField(default=timezone.now)
    notes = models.TextField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_stock_receipts",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-received_at", "-created_at"]

    def __str__(self) -> str:
        return f"Receipt #{self.pk or 'new'}"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class StockReceiptLine(models.Model):
    receipt = models.ForeignKey(
        StockReceipt,
        on_delete=models.CASCADE,
        related_name="lines",
    )
    inventory_item = models.ForeignKey(
        "inventory.InventoryItem",
        on_delete=models.PROTECT,
        related_name="stock_receipt_lines",
    )
    quantity = models.PositiveIntegerField()
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2)
    notes = models.TextField(null=True, blank=True)
    movement = models.OneToOneField(
        "inventory.InventoryMovement",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="stock_receipt_line",
        editable=False,
    )

    class Meta:
        ordering = ["id"]

    def clean(self):
        super().clean()
        if self.quantity <= 0:
            raise ValidationError({"quantity": "Quantity must be greater than zero."})

        if self.unit_cost < 0:
            raise ValidationError({"unit_cost": "Unit cost must be zero or positive."})

        if self.pk and self.movement_id:
            original = type(self).objects.get(pk=self.pk)
            tracked_fields = ("inventory_item_id", "quantity", "unit_cost")
            if any(getattr(original, field) != getattr(self, field) for field in tracked_fields):
                raise ValidationError(
                    "Posted stock receipt lines cannot change inventory item, quantity, or unit cost."
                )

    def save(self, *args, **kwargs):
        is_create = self._state.adding
        self.full_clean()

        with transaction.atomic():
            super().save(*args, **kwargs)
            if is_create and not self.movement_id:
                movement = apply_inventory_movement(
                    inventory_item=self.inventory_item,
                    movement_type=MovementType.RESTOCK_IN,
                    quantity=self.quantity,
                    unit_cost=self.unit_cost,
                    occurred_at=self.receipt.received_at,
                    reference_type="stock_receipt_line",
                    reference_id=str(self.pk),
                    notes=self.notes,
                    created_by=self.receipt.created_by,
                )
                set_current_price(
                    inventory_item=self.inventory_item,
                    price_type=PriceType.PURCHASE,
                    amount=self.unit_cost,
                    user=self.receipt.created_by,
                    valid_from=self.receipt.received_at,
                )
                type(self).objects.filter(pk=self.pk).update(movement=movement)
                self.movement = movement

    def __str__(self) -> str:
        return f"Receipt #{self.receipt_id} - {self.inventory_item}"
