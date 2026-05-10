from django.contrib import admin

from .models import DeviceControlState


@admin.register(DeviceControlState)
class DeviceControlStateAdmin(admin.ModelAdmin):
    list_display = (
        "singleton_key",
        "process_mode",
        "process_status",
        "delay_seconds",
        "start_requested",
        "health_status",
        "health_is_initializing",
        "health_reported_at",
    )
    readonly_fields = ("created_at", "updated_at")
