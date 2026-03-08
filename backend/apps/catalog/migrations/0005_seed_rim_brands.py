from django.db import migrations


RIM_BRANDS = [
    "ROMAX",
    "HCW",
    "URD",
    "ZEHLENDORF",
]


def seed_rim_brands(apps, schema_editor):
    Brand = apps.get_model("catalog", "Brand")
    existing_names = {name.upper() for name in Brand.objects.values_list("name", flat=True)}

    Brand.objects.bulk_create(
        [Brand(name=name) for name in RIM_BRANDS if name.upper() not in existing_names],
        ignore_conflicts=True,
    )


class Migration(migrations.Migration):

    dependencies = [
        ("catalog", "0004_rimspec"),
    ]

    operations = [
        migrations.RunPython(seed_rim_brands, migrations.RunPython.noop),
    ]
