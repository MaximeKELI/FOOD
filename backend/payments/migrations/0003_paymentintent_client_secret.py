from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("payments", "0002_stripe_remove_mock"),
    ]

    operations = [
        migrations.AddField(
            model_name="paymentintent",
            name="client_secret",
            field=models.CharField(blank=True, max_length=255),
        ),
    ]
