from django.contrib import admin

from .models import InventoryItem, InventoryMovement, PriceRecord


@admin.register(InventoryItem)
class InventoryItemAdmin(admin.ModelAdmin):
    list_display = (
        "catalog_item",
        "condition",
        "stock",
        "is_active",
        "last_restock_at",
        "updated_at",
    )
    list_filter = ("condition", "is_active")
    search_fields = ("catalog_item__sku", "catalog_item__code", "catalog_item__brand__name", "catalog_item__model")


@admin.register(PriceRecord)
class PriceRecordAdmin(admin.ModelAdmin):
    list_display = (
        "inventory_item",
        "price_type",
        "amount",
        "valid_from",
        "valid_to",
        "created_by",
    )
    list_filter = ("price_type",)
    search_fields = ("inventory_item__catalog_item__sku", "inventory_item__catalog_item__code")


@admin.register(InventoryMovement)
class InventoryMovementAdmin(admin.ModelAdmin):
    list_display = (
        "inventory_item",
        "movement_type",
        "quantity",
        "unit_cost",
        "occurred_at",
        "reference_type",
        "reference_id",
    )
    list_filter = ("movement_type", "occurred_at")
    search_fields = (
        "inventory_item__catalog_item__code",
        "inventory_item__catalog_item__sku",
        "reference_type",
        "reference_id",
    )
