from django.db import migrations


def seed_purchase_price_history_permission(apps, schema_editor):
    ContentType = apps.get_model("contenttypes", "ContentType")
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")

    inventory_ct = ContentType.objects.get(app_label="inventory", model="inventoryitem")
    permission, _ = Permission.objects.get_or_create(
        content_type=inventory_ct,
        codename="view_purchase_price_history",
        defaults={"name": "Can view purchase price history"},
    )

    gerencia, _ = Group.objects.get_or_create(name="Gerencia")
    gerencia.permissions.add(permission)

    for group_name in ["Manager", "Vendedor"]:
        group, _ = Group.objects.get_or_create(name=group_name)
        group.permissions.remove(permission)


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0001_seed_groups_and_permissions"),
        ("inventory", "0006_inventoryitem_purchase_price_history_permission"),
        ("auth", "0012_alter_user_first_name_max_length"),
        ("contenttypes", "0002_remove_content_type_name"),
    ]

    operations = [
        migrations.RunPython(seed_purchase_price_history_permission, migrations.RunPython.noop),
    ]
