from decimal import Decimal

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import F, Q
from django.utils import timezone


class InventoryCondition(models.TextChoices):
    NEW = "NEW", "New"
    USED = "USED", "Used"


class PriceType(models.TextChoices):
    PURCHASE = "PURCHASE", "Purchase"
    SUGGESTED_SALE = "SUGGESTED_SALE", "Suggested Sale"


class MovementType(models.TextChoices):
    RESTOCK_IN = "RESTOCK_IN", "Restock In"
    ADJUSTMENT_IN = "ADJUSTMENT_IN", "Adjustment In"
    ADJUSTMENT_OUT = "ADJUSTMENT_OUT", "Adjustment Out"
    RESERVED_OUT = "RESERVED_OUT", "Reserved Out"
    SALE_OUT = "SALE_OUT", "Sale Out"
    TRADEIN_IN = "TRADEIN_IN", "Trade-In In"

    @classmethod
    def inbound_values(cls):
        return {
            cls.RESTOCK_IN,
            cls.ADJUSTMENT_IN,
            cls.TRADEIN_IN,
        }

    @classmethod
    def outbound_values(cls):
        return {
            cls.ADJUSTMENT_OUT,
            cls.RESERVED_OUT,
            cls.SALE_OUT,
        }


class ActiveInventoryQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)


class Owner(models.Model):
    # Table-based owner is preferred over static choices because it scales as business grows.
    name = models.CharField(max_length=120, unique=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


def get_default_owner_id():
    default_owner = Owner.objects.filter(name__iexact="Maxpeed").only("id").first()
    if default_owner:
        return default_owner.id

    fallback_owner = Owner.objects.only("id").order_by("id").first()
    if fallback_owner:
        return fallback_owner.id

    raise Owner.DoesNotExist("No owner available. Run migrations to seed default owners.")


class InventoryItem(models.Model):
    catalog_item = models.ForeignKey(
        "catalog.CatalogItem",
        on_delete=models.PROTECT,
        related_name="inventory_items",
    )
    owner = models.ForeignKey(
        Owner,
        on_delete=models.PROTECT,
        related_name="inventory_items",
        default=get_default_owner_id,
    )
    condition = models.CharField(max_length=8, choices=InventoryCondition.choices)
    stock = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    deactivated_at = models.DateTimeField(null=True, blank=True)
    last_restock_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = ActiveInventoryQuerySet.as_manager()

    class Meta:
        ordering = ["catalog_item__sku", "owner__name", "condition"]
        permissions = [
            ("view_inventory", "Can view inventory"),
            ("view_zero_stock", "Can view zero stock inventory"),
            ("create_stock_receipt", "Can create stock receipt"),
            ("restock", "Can restock inventory"),
            ("deactivate_rims", "Can deactivate rim inventory"),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=["catalog_item", "condition", "owner"],
                name="inventory_unique_catalog_item_condition_owner",
            ),
            models.CheckConstraint(
                condition=Q(stock__gte=0),
                name="inventory_stock_gte_zero",
            ),
        ]

    def clean(self):
        super().clean()
        if self.stock < 0:
            raise ValidationError({"stock": "Stock cannot be negative."})

    def __str__(self) -> str:
        return f"{self.catalog_item} [{self.condition}] ({self.owner.name})"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class PriceRecord(models.Model):
    inventory_item = models.ForeignKey(
        InventoryItem,
        on_delete=models.CASCADE,
        related_name="price_records",
    )
    price_type = models.CharField(max_length=20, choices=PriceType.choices)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    valid_from = models.DateTimeField(default=timezone.now)
    valid_to = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_price_records",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-valid_from", "-created_at"]
        constraints = [
            models.CheckConstraint(
                condition=Q(amount__gte=Decimal("0.00")),
                name="price_record_amount_gte_zero",
            ),
            models.CheckConstraint(
                condition=Q(valid_to__isnull=True) | Q(valid_to__gte=F("valid_from")),
                name="price_record_validity_range",
            ),
            models.UniqueConstraint(
                fields=["inventory_item", "price_type"],
                condition=Q(valid_to__isnull=True),
                name="price_record_single_current_price",
            ),
        ]
        indexes = [
            models.Index(fields=["inventory_item", "price_type", "valid_from"]),
        ]

    def clean(self):
        super().clean()
        if self.amount < 0:
            raise ValidationError({"amount": "Amount must be zero or positive."})
        if self.valid_to and self.valid_to < self.valid_from:
            raise ValidationError({"valid_to": "valid_to must be later than or equal to valid_from."})

    def __str__(self) -> str:
        return f"{self.inventory_item} {self.price_type} {self.amount}"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class InventoryMovement(models.Model):
    inventory_item = models.ForeignKey(
        InventoryItem,
        on_delete=models.CASCADE,
        related_name="movements",
    )
    movement_type = models.CharField(max_length=20, choices=MovementType.choices)
    quantity = models.IntegerField(
        help_text="Signed quantity. Positive for inbound, negative for outbound."
    )
    unit_cost = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
    )
    occurred_at = models.DateTimeField(default=timezone.now)
    reference_type = models.CharField(max_length=64, null=True, blank=True)
    reference_id = models.CharField(max_length=64, null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_inventory_movements",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-occurred_at", "-created_at"]
        indexes = [
            models.Index(fields=["inventory_item", "occurred_at"]),
            models.Index(fields=["movement_type", "occurred_at"]),
            models.Index(fields=["reference_type", "reference_id"]),
        ]

    def clean(self):
        super().clean()
        if self.quantity == 0:
            raise ValidationError({"quantity": "Quantity cannot be zero."})

        if (
            self.movement_type in MovementType.inbound_values()
            and self.quantity < 0
        ):
            raise ValidationError({"quantity": "Inbound movement types require a positive quantity."})

        if (
            self.movement_type in MovementType.outbound_values()
            and self.quantity > 0
        ):
            raise ValidationError({"quantity": "Outbound movement types require a negative quantity."})

        if self.unit_cost is not None and self.unit_cost < 0:
            raise ValidationError({"unit_cost": "Unit cost must be zero or positive."})

    def __str__(self) -> str:
        return f"{self.inventory_item} {self.movement_type} {self.quantity}"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)
