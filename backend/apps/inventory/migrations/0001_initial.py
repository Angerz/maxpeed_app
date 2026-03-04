import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models
from django.db.models import F, Q


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("catalog", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="InventoryItem",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("condition", models.CharField(choices=[("NEW", "New"), ("USED", "Used")], max_length=8)),
                ("stock", models.IntegerField(default=0)),
                ("is_active", models.BooleanField(default=True)),
                ("last_restock_at", models.DateTimeField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("catalog_item", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="inventory_items", to="catalog.catalogitem")),
            ],
            options={
                "ordering": ["catalog_item__code", "condition"],
            },
        ),
        migrations.CreateModel(
            name="InventoryMovement",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("movement_type", models.CharField(choices=[("RESTOCK_IN", "Restock In"), ("ADJUSTMENT_IN", "Adjustment In"), ("ADJUSTMENT_OUT", "Adjustment Out"), ("RESERVED_OUT", "Reserved Out"), ("SALE_OUT", "Sale Out"), ("TRADEIN_IN", "Trade-In In")], max_length=20)),
                ("quantity", models.IntegerField(help_text="Signed quantity. Positive for inbound, negative for outbound.")),
                ("unit_cost", models.DecimalField(blank=True, decimal_places=2, max_digits=12, null=True)),
                ("occurred_at", models.DateTimeField(default=django.utils.timezone.now)),
                ("reference_type", models.CharField(blank=True, max_length=64, null=True)),
                ("reference_id", models.CharField(blank=True, max_length=64, null=True)),
                ("notes", models.TextField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("created_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="created_inventory_movements", to=settings.AUTH_USER_MODEL)),
                ("inventory_item", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="movements", to="inventory.inventoryitem")),
            ],
            options={
                "ordering": ["-occurred_at", "-created_at"],
                "indexes": [
                    models.Index(fields=["inventory_item", "occurred_at"], name="inventory_i_invento_759f83_idx"),
                    models.Index(fields=["movement_type", "occurred_at"], name="inventory_i_movemen_69457e_idx"),
                    models.Index(fields=["reference_type", "reference_id"], name="inventory_i_referen_76d002_idx"),
                ],
            },
        ),
        migrations.CreateModel(
            name="PriceRecord",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("price_type", models.CharField(choices=[("PURCHASE", "Purchase"), ("SUGGESTED_SALE", "Suggested Sale")], max_length=20)),
                ("amount", models.DecimalField(decimal_places=2, max_digits=12)),
                ("valid_from", models.DateTimeField(default=django.utils.timezone.now)),
                ("valid_to", models.DateTimeField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("created_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="created_price_records", to=settings.AUTH_USER_MODEL)),
                ("inventory_item", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="price_records", to="inventory.inventoryitem")),
            ],
            options={
                "ordering": ["-valid_from", "-created_at"],
                "indexes": [
                    models.Index(fields=["inventory_item", "price_type", "valid_from"], name="inventory_p_invento_459db9_idx"),
                ],
            },
        ),
        migrations.AddConstraint(
            model_name="inventoryitem",
            constraint=models.UniqueConstraint(fields=("catalog_item", "condition"), name="inventory_unique_catalog_item_condition"),
        ),
        migrations.AddConstraint(
            model_name="inventoryitem",
            constraint=models.CheckConstraint(condition=Q(stock__gte=0), name="inventory_stock_gte_zero"),
        ),
        migrations.AddConstraint(
            model_name="pricerecord",
            constraint=models.CheckConstraint(condition=Q(amount__gte=0), name="price_record_amount_gte_zero"),
        ),
        migrations.AddConstraint(
            model_name="pricerecord",
            constraint=models.CheckConstraint(
                condition=Q(valid_to__isnull=True) | Q(valid_to__gte=F("valid_from")),
                name="price_record_validity_range",
            ),
        ),
        migrations.AddConstraint(
            model_name="pricerecord",
            constraint=models.UniqueConstraint(
                condition=Q(valid_to__isnull=True),
                fields=("inventory_item", "price_type"),
                name="price_record_single_current_price",
            ),
        ),
    ]
