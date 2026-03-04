from django.contrib import admin

from .models import StockReceipt, StockReceiptLine


class StockReceiptLineInline(admin.TabularInline):
    model = StockReceiptLine
    extra = 0
    readonly_fields = ("movement",)


@admin.register(StockReceipt)
class StockReceiptAdmin(admin.ModelAdmin):
    list_display = ("id", "supplier_name", "received_at", "created_by", "created_at")
    search_fields = ("supplier_name", "notes")
    inlines = (StockReceiptLineInline,)


@admin.register(StockReceiptLine)
class StockReceiptLineAdmin(admin.ModelAdmin):
    list_display = ("receipt", "inventory_item", "quantity", "unit_cost", "movement")
    search_fields = ("receipt__supplier_name", "inventory_item__catalog_item__sku", "inventory_item__catalog_item__code")
    readonly_fields = ("movement",)
