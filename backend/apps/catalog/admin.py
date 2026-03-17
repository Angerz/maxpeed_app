from django.contrib import admin

from .models import Brand, CatalogItem, RimSpec, TireSpec

admin.site.site_header = "Maxpeed Control"
admin.site.site_title = "Maxpeed Admin"
admin.site.index_title = "Operacion del backend"


@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ("name", "logo_image", "created_at")
    search_fields = ("name",)
    ordering = ("name",)


class TireSpecInline(admin.StackedInline):
    model = TireSpec
    extra = 0


class RimSpecInline(admin.StackedInline):
    model = RimSpec
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
    inlines = (TireSpecInline, RimSpecInline)


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


@admin.register(RimSpec)
class RimSpecAdmin(admin.ModelAdmin):
    list_display = ("catalog_item", "rim_diameter", "holes", "width_in", "material", "is_set", "photo_image")
    list_filter = ("rim_diameter", "holes", "width_in", "material", "is_set")
