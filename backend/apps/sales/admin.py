from django.contrib import admin

from .models import Sale, SaleLine


class SaleLineInline(admin.TabularInline):
    model = SaleLine
    extra = 0
    readonly_fields = ("created_at",)


@admin.register(Sale)
class SaleAdmin(admin.ModelAdmin):
    list_display = ("id", "sold_at", "status", "total_due", "created_by")
    list_filter = ("status", "sold_at")
    search_fields = ("id", "notes")
    readonly_fields = ("created_at",)
    inlines = [SaleLineInline]


@admin.register(SaleLine)
class SaleLineAdmin(admin.ModelAdmin):
    list_display = ("id", "sale", "line_type", "quantity", "line_total", "inventory_item")
    list_filter = ("line_type",)
    search_fields = ("description", "code", "brand")
    readonly_fields = ("created_at",)
