import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("images", "0003_imageasset_variant_and_group_key"),
        ("catalog", "0007_rename_catalog_cat_item_7fa007_idx_catalog_cat_item_ki_1d3096_idx_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="brand",
            name="logo_image_full",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="brand_logo_full_set",
                to="images.imageasset",
            ),
        ),
        migrations.AddField(
            model_name="brand",
            name="logo_image_thumb",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="brand_logo_thumb_set",
                to="images.imageasset",
            ),
        ),
        migrations.AddField(
            model_name="rimspec",
            name="photo_image_full",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="rim_photo_full_set",
                to="images.imageasset",
            ),
        ),
        migrations.AddField(
            model_name="rimspec",
            name="photo_image_thumb",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="rim_photo_thumb_set",
                to="images.imageasset",
            ),
        ),
    ]
