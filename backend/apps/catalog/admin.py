from django.contrib import admin

from .models import Brand, CatalogItem, TireSpec


@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ("name", "created_at")
    search_fields = ("name",)
    ordering = ("name",)


class TireSpecInline(admin.StackedInline):
    model = TireSpec
    extra = 0


@admin.register(CatalogItem)
class CatalogItemAdmin(admin.ModelAdmin):
    list_display = (
        "sku",
        "code",
        "product_category",
        "item_kind",
        "brand",
        "model",
        "origin",
        "is_active",
    )
    list_filter = ("item_kind", "product_category", "origin", "is_active")
    search_fields = ("sku", "code", "model", "brand__name")
    inlines = (TireSpecInline,)


@admin.register(TireSpec)
class TireSpecAdmin(admin.ModelAdmin):
    list_display = (
        "catalog_item",
        "tire_type",
        "width",
        "aspect_ratio",
        "rim_diameter",
        "ply_rating",
        "tread_type",
        "letter_color",
    )
    list_filter = ("tire_type", "rim_diameter", "ply_rating", "tread_type", "letter_color")
