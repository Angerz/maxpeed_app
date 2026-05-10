from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("device_control", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="devicecontrolstate",
            name="process_status",
            field=models.CharField(
                choices=[
                    ("inactive", "Inactive"),
                    ("in_process", "In process"),
                    ("started", "Started"),
                    ("finished", "Finished"),
                ],
                default="inactive",
                max_length=16,
            ),
        ),
        migrations.AddField(
            model_name="devicecontrolstate",
            name="process_started_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="devicecontrolstate",
            name="process_finished_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]

