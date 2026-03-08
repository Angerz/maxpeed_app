from decimal import Decimal

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import Q
from django.utils import timezone


class SaleStatus(models.TextChoices):
    DRAFT = "DRAFT", "Draft"
    CONFIRMED = "CONFIRMED", "Confirmed"
    CANCELED = "CANCELED", "Canceled"


class SaleLineType(models.TextChoices):
    INVENTORY_TIRE = "INVENTORY_TIRE", "Inventory Tire"
    INVENTORY_RIM = "INVENTORY_RIM", "Inventory Rim"
    SERVICE = "SERVICE", "Service"
    ACCESSORY = "ACCESSORY", "Accessory"
    TRADEIN_TIRE = "TRADEIN_TIRE", "Trade-In Tire"
    TRADEIN_RIM = "TRADEIN_RIM", "Trade-In Rim"

    @classmethod
    def inventory_values(cls):
        return {cls.INVENTORY_TIRE, cls.INVENTORY_RIM}

    @classmethod
    def manual_values(cls):
        return {cls.SERVICE, cls.ACCESSORY}

    @classmethod
    def tradein_values(cls):
        return {cls.TRADEIN_TIRE, cls.TRADEIN_RIM}


class Sale(models.Model):
    sold_at = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=16, choices=SaleStatus.choices, default=SaleStatus.CONFIRMED)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    discount_total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    tradein_credit_total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    total_due = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    notes = models.TextField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_sales",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-sold_at", "-id"]

    def clean(self):
        super().clean()
        numeric_fields = {
            "subtotal": self.subtotal,
            "discount_total": self.discount_total,
            "tradein_credit_total": self.tradein_credit_total,
            "total": self.total,
            "total_due": self.total_due,
        }
        for field_name, value in numeric_fields.items():
            if value < 0:
                raise ValidationError({field_name: f"{field_name} cannot be negative."})

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class SaleLine(models.Model):
    sale = models.ForeignKey(Sale, on_delete=models.CASCADE, related_name="lines")
    line_type = models.CharField(max_length=20, choices=SaleLineType.choices)
    inventory_item = models.ForeignKey(
        "inventory.InventoryItem",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="sale_lines",
    )
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    discount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    line_total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    description = models.CharField(max_length=255, null=True, blank=True)
    code = models.CharField(max_length=64, null=True, blank=True)
    brand = models.CharField(max_length=120, null=True, blank=True)
    owner_name = models.CharField(max_length=120, null=True, blank=True)
    details = models.CharField(max_length=255, null=True, blank=True)
    assessed_value = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    tire_condition_percent = models.PositiveSmallIntegerField(null=True, blank=True)
    rim_requires_repair = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["id"]
        constraints = [
            models.CheckConstraint(condition=Q(discount__gte=0), name="sale_line_discount_gte_zero"),
        ]

    def clean(self):
        super().clean()
        if self.quantity <= 0:
            raise ValidationError({"quantity": "Quantity must be greater than zero."})
        if self.unit_price < 0:
            raise ValidationError({"unit_price": "Unit price cannot be negative."})
        if self.discount < 0:
            raise ValidationError({"discount": "Discount cannot be negative."})
        if self.line_total < 0:
            raise ValidationError({"line_total": "Line total cannot be negative."})
        if self.assessed_value is not None and self.assessed_value < 0:
            raise ValidationError({"assessed_value": "Assessed value cannot be negative."})

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)
