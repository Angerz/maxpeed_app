from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="ImageAsset",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("kind", models.CharField(choices=[("BRAND_LOGO", "Brand Logo"), ("RIM_PHOTO", "Rim Photo")], max_length=20)),
                ("mime_type", models.CharField(max_length=100)),
                ("data", models.BinaryField()),
                ("sha256", models.CharField(blank=True, max_length=64, null=True)),
                ("size_bytes", models.IntegerField()),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={
                "ordering": ["-created_at", "-id"],
            },
        ),
        migrations.AddIndex(
            model_name="imageasset",
            index=models.Index(fields=["kind", "created_at"], name="images_imag_kind_76674e_idx"),
        ),
        migrations.AddIndex(
            model_name="imageasset",
            index=models.Index(fields=["sha256"], name="images_imag_sha256_7b8eb9_idx"),
        ),
    ]
