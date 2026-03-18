from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("inventory", "0005_inventoryitem_custom_permissions"),
    ]

    operations = [
        migrations.AlterModelOptions(
            name="inventoryitem",
            options={
                "ordering": ["catalog_item__sku", "owner__name", "condition"],
                "permissions": [
                    ("view_inventory", "Can view inventory"),
                    ("view_zero_stock", "Can view zero stock inventory"),
                    ("create_stock_receipt", "Can create stock receipt"),
                    ("restock", "Can restock inventory"),
                    ("deactivate_rims", "Can deactivate rim inventory"),
                    ("view_purchase_price_history", "Can view purchase price history"),
                ],
            },
        ),
    ]
