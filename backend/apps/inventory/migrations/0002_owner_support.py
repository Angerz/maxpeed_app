import django.db.models.deletion
from django.db import migrations, models
import apps.inventory.models


def seed_owners_and_backfill_inventory(apps, schema_editor):
    Owner = apps.get_model("inventory", "Owner")
    InventoryItem = apps.get_model("inventory", "InventoryItem")

    maxpeed_owner, _ = Owner.objects.get_or_create(name="Maxpeed", defaults={"is_active": True})
    Owner.objects.get_or_create(name="Ruel", defaults={"is_active": True})

    InventoryItem.objects.filter(owner__isnull=True).update(owner=maxpeed_owner)


class Migration(migrations.Migration):

    dependencies = [
        ("inventory", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Owner",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=120, unique=True)),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={
                "ordering": ["name"],
            },
        ),
        migrations.AddField(
            model_name="inventoryitem",
            name="owner",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="inventory_items",
                to="inventory.owner",
            ),
        ),
        migrations.RunPython(seed_owners_and_backfill_inventory, migrations.RunPython.noop),
        migrations.AlterField(
            model_name="inventoryitem",
            name="owner",
            field=models.ForeignKey(
                default=apps.inventory.models.get_default_owner_id,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="inventory_items",
                to="inventory.owner",
            ),
        ),
        migrations.RemoveConstraint(
            model_name="inventoryitem",
            name="inventory_unique_catalog_item_condition",
        ),
        migrations.AddConstraint(
            model_name="inventoryitem",
            constraint=models.UniqueConstraint(
                fields=("catalog_item", "condition", "owner"),
                name="inventory_unique_catalog_item_condition_owner",
            ),
        ),
        migrations.AlterModelOptions(
            name="inventoryitem",
            options={"ordering": ["catalog_item__sku", "owner__name", "condition"]},
        ),
    ]
