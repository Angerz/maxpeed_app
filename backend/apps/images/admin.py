from django.contrib import admin

from .models import ImageAsset


@admin.register(ImageAsset)
class ImageAssetAdmin(admin.ModelAdmin):
    list_display = ("id", "kind", "mime_type", "size_bytes", "sha256", "created_at")
    list_filter = ("kind", "mime_type", "created_at")
    readonly_fields = ("kind", "mime_type", "size_bytes", "sha256", "created_at")
    search_fields = ("id", "sha256")
