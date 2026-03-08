import django.db.models.deletion
import django.utils.timezone
from decimal import Decimal
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("inventory", "0003_aldo_owner_and_deactivation"),
    ]

    operations = [
        migrations.CreateModel(
            name="Sale",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("sold_at", models.DateTimeField(default=django.utils.timezone.now)),
                (
                    "status",
                    models.CharField(
                        choices=[("DRAFT", "Draft"), ("CONFIRMED", "Confirmed"), ("CANCELED", "Canceled")],
                        default="CONFIRMED",
                        max_length=16,
                    ),
                ),
                ("subtotal", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("discount_total", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("tradein_credit_total", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("total", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("total_due", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("notes", models.TextField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "created_by",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="created_sales",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={"ordering": ["-sold_at", "-id"]},
        ),
        migrations.CreateModel(
            name="SaleLine",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                (
                    "line_type",
                    models.CharField(
                        choices=[
                            ("INVENTORY_TIRE", "Inventory Tire"),
                            ("INVENTORY_RIM", "Inventory Rim"),
                            ("SERVICE", "Service"),
                            ("ACCESSORY", "Accessory"),
                            ("TRADEIN_TIRE", "Trade-In Tire"),
                            ("TRADEIN_RIM", "Trade-In Rim"),
                        ],
                        max_length=20,
                    ),
                ),
                ("quantity", models.PositiveIntegerField(default=1)),
                ("unit_price", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("discount", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("line_total", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=12)),
                ("description", models.CharField(blank=True, max_length=255, null=True)),
                ("code", models.CharField(blank=True, max_length=64, null=True)),
                ("brand", models.CharField(blank=True, max_length=120, null=True)),
                ("owner_name", models.CharField(blank=True, max_length=120, null=True)),
                ("details", models.CharField(blank=True, max_length=255, null=True)),
                ("assessed_value", models.DecimalField(blank=True, decimal_places=2, max_digits=12, null=True)),
                ("tire_condition_percent", models.PositiveSmallIntegerField(blank=True, null=True)),
                ("rim_requires_repair", models.BooleanField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "inventory_item",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="sale_lines",
                        to="inventory.inventoryitem",
                    ),
                ),
                (
                    "sale",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="lines", to="sales.sale"),
                ),
            ],
            options={"ordering": ["id"]},
        ),
        migrations.AddConstraint(
            model_name="saleline",
            constraint=models.CheckConstraint(condition=models.Q(("discount__gte", 0)), name="sale_line_discount_gte_zero"),
        ),
    ]
