from django.db import migrations, models
import django.db.models.deletion
from django.db.models import Q


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="Brand",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(db_index=True, max_length=120, unique=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={
                "ordering": ["name"],
            },
        ),
        migrations.CreateModel(
            name="CatalogItem",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("code", models.CharField(max_length=64)),
                ("item_kind", models.CharField(choices=[("MERCHANDISE", "Merchandise"), ("SERVICE", "Service")], max_length=16)),
                ("product_category", models.CharField(choices=[("TIRE", "Tire"), ("RIM", "Rim"), ("ACCESSORY", "Accessory"), ("SERVICE_GENERAL", "General Service")], max_length=32)),
                ("model", models.CharField(blank=True, max_length=120, null=True)),
                ("origin", models.CharField(blank=True, choices=[("CHINA", "China"), ("THAILAND", "Thailand"), ("JAPAN", "Japan"), ("KOREA", "Korea"), ("TAIWAN", "Taiwan"), ("INDIA", "India"), ("BRAZIL", "Brazil"), ("USA", "USA"), ("EUROPE", "Europe"), ("OTHER", "Other")], max_length=32, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("is_active", models.BooleanField(default=True)),
                ("brand", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="catalog_items", to="catalog.brand")),
            ],
            options={
                "ordering": ["product_category", "code", "brand__name", "model"],
                "indexes": [
                    models.Index(fields=["item_kind", "product_category", "is_active"], name="catalog_cat_item_7fa007_idx"),
                    models.Index(fields=["code"], name="catalog_cat_code_a43d41_idx"),
                ],
            },
        ),
        migrations.CreateModel(
            name="TireSpec",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("tire_type", models.CharField(choices=[("RADIAL", "Radial"), ("CARGO", "Cargo"), ("MILLIMETRIC", "Millimetric"), ("CONVENTIONAL", "Conventional")], max_length=16)),
                ("width", models.PositiveIntegerField()),
                ("aspect_ratio", models.PositiveIntegerField(blank=True, null=True)),
                ("rim_diameter", models.CharField(choices=[("R12", "R12"), ("R13", "R13"), ("R14", "R14"), ("R15", "R15"), ("R16", "R16"), ("R17", "R17"), ("R18", "R18"), ("R19", "R19"), ("R20", "R20"), ("R21", "R21"), ("R22", "R22")], max_length=3)),
                ("ply_rating", models.CharField(choices=[("PR2", "PR2"), ("PR4", "PR4"), ("PR6", "PR6"), ("PR8", "PR8"), ("PR10", "PR10"), ("PR12", "PR12")], max_length=4)),
                ("tread_type", models.CharField(choices=[("LINEAR", "Linear"), ("AT", "A/T"), ("AT2", "A/T 2"), ("HT", "H/T"), ("MT", "M/T"), ("RT", "R/T"), ("HIGHWAY", "Highway"), ("SPORT", "Sport")], max_length=16)),
                ("letter_color", models.CharField(choices=[("BLACK", "Black"), ("WHITE", "White"), ("RED", "Red"), ("YELLOW", "Yellow")], default="BLACK", max_length=16)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("catalog_item", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="tire_spec", to="catalog.catalogitem")),
            ],
            options={
                "ordering": ["catalog_item__code"],
            },
        ),
        migrations.AddConstraint(
            model_name="catalogitem",
            constraint=models.UniqueConstraint(
                condition=Q(product_category__in=["TIRE", "RIM"]),
                fields=("code", "brand", "model", "product_category"),
                name="catalog_unique_code_brand_model_category_for_goods",
            ),
        ),
    ]
