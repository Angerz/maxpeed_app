import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("catalog", "0003_seed_brands"),
    ]

    operations = [
        migrations.CreateModel(
            name="RimSpec",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("rim_diameter", models.CharField(choices=[("R12", "R12"), ("R13", "R13"), ("R14", "R14"), ("R15", "R15"), ("R16", "R16"), ("R17", "R17"), ("R18", "R18"), ("R19", "R19"), ("R20", "R20"), ("R21", "R21"), ("R22", "R22")], max_length=3)),
                ("holes", models.PositiveSmallIntegerField(choices=[(4, "4H"), (5, "5H"), (6, "6H")])),
                ("width_in", models.PositiveSmallIntegerField(choices=[(5, "5IN"), (6, "6IN"), (7, "7IN"), (8, "8IN"), (9, "9IN"), (10, "10IN"), (11, "11IN"), (12, "12IN")])),
                ("material", models.CharField(choices=[("ALUMINUM", "Aluminum"), ("IRON", "Iron")], max_length=16)),
                ("is_set", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("catalog_item", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="rim_spec", to="catalog.catalogitem")),
            ],
            options={
                "ordering": ["catalog_item__sku"],
            },
        ),
    ]
