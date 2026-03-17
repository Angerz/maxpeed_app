import uuid

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("images", "0002_rename_images_imag_kind_76674e_idx_images_imag_kind_d0e3e9_idx_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="imageasset",
            name="group_key",
            field=models.UUIDField(db_index=True, default=uuid.uuid4),
        ),
        migrations.AddField(
            model_name="imageasset",
            name="variant",
            field=models.CharField(
                choices=[("FULL", "Full"), ("THUMB", "Thumb")],
                default="FULL",
                max_length=8,
            ),
        ),
        migrations.RemoveIndex(
            model_name="imageasset",
            name="images_imag_kind_d0e3e9_idx",
        ),
        migrations.AddIndex(
            model_name="imageasset",
            index=models.Index(fields=["kind", "variant", "created_at"], name="images_imag_kind_6b7579_idx"),
        ),
    ]
