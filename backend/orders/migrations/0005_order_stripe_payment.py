from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("orders", "0004_phase3"),
    ]

    operations = [
        migrations.AlterField(
            model_name="order",
            name="payment_method",
            field=models.CharField(
                choices=[
                    ("cash", "À la livraison"),
                    ("stripe", "Carte (Stripe)"),
                    ("wave", "Wave"),
                    ("orange_money", "Orange Money"),
                    ("free_money", "Free Money"),
                ],
                default="cash",
                max_length=20,
            ),
        ),
    ]
