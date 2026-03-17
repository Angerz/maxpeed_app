import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("images", "0001_initial"),
        ("catalog", "0005_seed_rim_brands"),
    ]

    operations = [
        migrations.AddField(
            model_name="brand",
            name="logo_image",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="brand_logos",
                to="images.imageasset",
            ),
        ),
        migrations.AddField(
            model_name="rimspec",
            name="photo_image",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="rim_photos",
                to="images.imageasset",
            ),
        ),
    ]
