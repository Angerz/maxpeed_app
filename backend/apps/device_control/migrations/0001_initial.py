# Generated manually because the local Python environment does not have Django installed.

import uuid

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="DeviceControlState",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("singleton_key", models.CharField(default="main", max_length=32, unique=True)),
                (
                    "process_command_id",
                    models.UUIDField(default=uuid.uuid4, editable=False),
                ),
                (
                    "process_mode",
                    models.CharField(
                        choices=[("delay", "Delay"), ("manual", "Manual")],
                        default="delay",
                        max_length=16,
                    ),
                ),
                ("delay_seconds", models.PositiveIntegerField(default=0)),
                ("start_requested", models.BooleanField(default=False)),
                ("process_requested_at", models.DateTimeField(blank=True, null=True)),
                ("process_picked_up_at", models.DateTimeField(blank=True, null=True)),
                ("wifi_command_id", models.UUIDField(default=uuid.uuid4, editable=False)),
                ("wifi_ssid", models.CharField(blank=True, max_length=64)),
                ("wifi_password", models.CharField(blank=True, max_length=128)),
                ("wifi_requested_at", models.DateTimeField(blank=True, null=True)),
                ("wifi_picked_up_at", models.DateTimeField(blank=True, null=True)),
                ("health_status", models.CharField(default="unknown", max_length=32)),
                ("health_message", models.CharField(blank=True, max_length=160)),
                ("health_is_initializing", models.BooleanField(default=False)),
                ("health_reported_at", models.DateTimeField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "device control state",
                "verbose_name_plural": "device control states",
            },
        ),
    ]

