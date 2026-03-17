from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("inventory", "0004_rename_inventory_i_invento_759f83_idx_inventory_i_invento_13392e_idx_and_more"),
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
                ],
            },
        ),
    ]
