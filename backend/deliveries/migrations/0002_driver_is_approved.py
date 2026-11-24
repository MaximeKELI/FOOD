from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("deliveries", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="driver",
            name="is_approved",
            field=models.BooleanField(default=False),
        ),
    ]
