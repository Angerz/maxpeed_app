from django.db import migrations, models


def seed_aldo_owner(apps, schema_editor):
    Owner = apps.get_model("inventory", "Owner")
    Owner.objects.get_or_create(name="ALDO", defaults={"is_active": True})


class Migration(migrations.Migration):

    dependencies = [
        ("inventory", "0002_owner_support"),
    ]

    operations = [
        migrations.AddField(
            model_name="inventoryitem",
            name="deactivated_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.RunPython(seed_aldo_owner, migrations.RunPython.noop),
    ]
