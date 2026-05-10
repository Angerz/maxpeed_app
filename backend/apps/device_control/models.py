import uuid

from django.db import models


class ProcessMode(models.TextChoices):
    DELAY = "delay", "Delay"
    MANUAL = "manual", "Manual"


class ProcessStatus(models.TextChoices):
    INACTIVE = "inactive", "Inactive"
    IN_PROCESS = "in_process", "In process"
    STARTED = "started", "Started"
    FINISHED = "finished", "Finished"


class DeviceControlState(models.Model):
    singleton_key = models.CharField(max_length=32, unique=True, default="main")

    process_command_id = models.UUIDField(default=uuid.uuid4, editable=False)
    process_mode = models.CharField(
        max_length=16,
        choices=ProcessMode.choices,
        default=ProcessMode.DELAY,
    )
    delay_seconds = models.PositiveIntegerField(default=0)
    start_requested = models.BooleanField(default=False)
    process_status = models.CharField(
        max_length=16,
        choices=ProcessStatus.choices,
        default=ProcessStatus.INACTIVE,
    )
    process_requested_at = models.DateTimeField(null=True, blank=True)
    process_picked_up_at = models.DateTimeField(null=True, blank=True)
    process_started_at = models.DateTimeField(null=True, blank=True)
    process_finished_at = models.DateTimeField(null=True, blank=True)

    wifi_command_id = models.UUIDField(default=uuid.uuid4, editable=False)
    wifi_ssid = models.CharField(max_length=64, blank=True)
    wifi_password = models.CharField(max_length=128, blank=True)
    wifi_requested_at = models.DateTimeField(null=True, blank=True)
    wifi_picked_up_at = models.DateTimeField(null=True, blank=True)

    health_status = models.CharField(max_length=32, default="unknown")
    health_message = models.CharField(max_length=160, blank=True)
    health_is_initializing = models.BooleanField(default=False)
    health_reported_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "device control state"
        verbose_name_plural = "device control states"

    def __str__(self) -> str:
        return self.singleton_key
