from django.db import migrations, models


def populate_sku(apps, schema_editor):
    CatalogItem = apps.get_model("catalog", "CatalogItem")

    for item in CatalogItem.objects.all().order_by("pk"):
        base_sku = item.code or f"ITEM-{item.pk}"
        candidate = base_sku
        suffix = 1
        while CatalogItem.objects.exclude(pk=item.pk).filter(sku=candidate).exists():
            suffix += 1
            candidate = f"{base_sku}-{suffix}"
        item.sku = candidate
        item.save(update_fields=["sku"])


class Migration(migrations.Migration):

    dependencies = [
        ("catalog", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="catalogitem",
            name="sku",
            field=models.CharField(blank=True, db_index=True, max_length=64, null=True),
        ),
        migrations.RunPython(populate_sku, migrations.RunPython.noop),
        migrations.AlterField(
            model_name="catalogitem",
            name="sku",
            field=models.CharField(db_index=True, max_length=64, unique=True),
        ),
        migrations.AlterField(
            model_name="catalogitem",
            name="code",
            field=models.CharField(blank=True, max_length=64, null=True),
        ),
        migrations.AlterModelOptions(
            name="catalogitem",
            options={"ordering": ["product_category", "sku", "brand__name", "model"]},
        ),
        migrations.AlterModelOptions(
            name="tirespec",
            options={"ordering": ["catalog_item__sku"]},
        ),
    ]
