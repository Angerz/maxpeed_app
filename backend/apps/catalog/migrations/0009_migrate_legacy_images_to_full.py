from django.db import migrations


def migrate_legacy_to_full(apps, schema_editor):
    Brand = apps.get_model("catalog", "Brand")
    RimSpec = apps.get_model("catalog", "RimSpec")

    for brand in Brand.objects.exclude(logo_image_id__isnull=True):
        if brand.logo_image_full_id is None:
            brand.logo_image_full_id = brand.logo_image_id
            brand.save(update_fields=["logo_image_full"])

    for rim_spec in RimSpec.objects.exclude(photo_image_id__isnull=True):
        if rim_spec.photo_image_full_id is None:
            rim_spec.photo_image_full_id = rim_spec.photo_image_id
            rim_spec.save(update_fields=["photo_image_full"])


class Migration(migrations.Migration):
    dependencies = [
        ("catalog", "0008_brand_and_rim_image_variants"),
    ]

    operations = [
        migrations.RunPython(migrate_legacy_to_full, migrations.RunPython.noop),
    ]
