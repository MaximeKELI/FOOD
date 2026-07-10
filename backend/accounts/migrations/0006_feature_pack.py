from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0005_user_vendor_fields"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="badges",
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="accepts_orders",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="min_order_amount",
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="default_prep_minutes",
            field=models.PositiveSmallIntegerField(default=30),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="badges",
            field=models.JSONField(blank=True, default=list),
        ),
    ]
