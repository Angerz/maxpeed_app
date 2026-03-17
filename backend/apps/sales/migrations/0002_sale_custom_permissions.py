from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("sales", "0001_initial"),
    ]

    operations = [
        migrations.AlterModelOptions(
            name="sale",
            options={
                "ordering": ["-sold_at", "-id"],
                "permissions": [
                    ("create_sale", "Can create sales"),
                    ("view_sales", "Can view sales list"),
                    ("view_sale_detail", "Can view sales detail"),
                ],
            },
        ),
    ]
