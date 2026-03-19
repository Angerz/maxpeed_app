from django.db import migrations


def seed_groups_and_permissions(apps, schema_editor):
    ContentType = apps.get_model("contenttypes", "ContentType")
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    InventoryItem = apps.get_model("inventory", "InventoryItem")
    Sale = apps.get_model("sales", "Sale")

    inventory_ct, _ = ContentType.objects.get_or_create(
        app_label=InventoryItem._meta.app_label,
        model=InventoryItem._meta.model_name,
    )
    sale_ct, _ = ContentType.objects.get_or_create(
        app_label=Sale._meta.app_label,
        model=Sale._meta.model_name,
    )

    permission_specs = [
        ("inventory", "view_inventory", "Can view inventory", inventory_ct),
        ("inventory", "view_zero_stock", "Can view zero stock inventory", inventory_ct),
        ("inventory", "create_stock_receipt", "Can create stock receipt", inventory_ct),
        ("inventory", "restock", "Can restock inventory", inventory_ct),
        ("inventory", "deactivate_rims", "Can deactivate rim inventory", inventory_ct),
        ("sales", "create_sale", "Can create sales", sale_ct),
        ("sales", "view_sales", "Can view sales list", sale_ct),
        ("sales", "view_sale_detail", "Can view sales detail", sale_ct),
    ]

    permission_map = {}
    for app_label, codename, name, content_type in permission_specs:
        permission, _ = Permission.objects.get_or_create(
            content_type=content_type,
            codename=codename,
            defaults={"name": name},
        )
        permission_map[f"{app_label}.{codename}"] = permission

    group_permissions = {
        "Gerencia": [
            "inventory.view_inventory",
            "inventory.view_zero_stock",
            "inventory.create_stock_receipt",
            "inventory.restock",
            "inventory.deactivate_rims",
            "sales.create_sale",
            "sales.view_sales",
            "sales.view_sale_detail",
        ],
        "Manager": [
            "inventory.view_inventory",
            "inventory.view_zero_stock",
            "sales.view_sales",
            "sales.view_sale_detail",
        ],
        "Vendedor": [
            "inventory.view_inventory",
            "sales.create_sale",
            "sales.view_sales",
            "sales.view_sale_detail",
        ],
    }

    for group_name, permission_keys in group_permissions.items():
        group, _ = Group.objects.get_or_create(name=group_name)
        group.permissions.set([permission_map[key] for key in permission_keys])


class Migration(migrations.Migration):
    dependencies = [
        ("inventory", "0005_inventoryitem_custom_permissions"),
        ("sales", "0002_sale_custom_permissions"),
        ("auth", "0012_alter_user_first_name_max_length"),
        ("contenttypes", "0002_remove_content_type_name"),
    ]

    operations = [
        migrations.RunPython(seed_groups_and_permissions, migrations.RunPython.noop),
    ]
