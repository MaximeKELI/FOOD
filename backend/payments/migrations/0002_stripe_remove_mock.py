from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("payments", "0001_phase3"),
    ]

    operations = [
        migrations.AlterField(
            model_name="paymentintent",
            name="provider",
            field=models.CharField(
                choices=[
                    ("stripe", "Stripe"),
                    ("wave", "Wave"),
                    ("orange_money", "Orange Money"),
                ],
                max_length=20,
            ),
        ),
    ]
