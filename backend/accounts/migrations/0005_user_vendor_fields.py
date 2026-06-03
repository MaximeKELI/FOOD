from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0002_sellerprofile_delivery_fee_base_and_more"),
    ]

    operations = [
        # first_name / last_name already exist on User (AbstractUser in 0001_initial).
        migrations.AlterField(
            model_name="user",
            name="first_name",
            field=models.CharField(blank=True, max_length=60),
        ),
        migrations.AlterField(
            model_name="user",
            name="last_name",
            field=models.CharField(blank=True, max_length=60),
        ),
        migrations.AddField(
            model_name="user",
            name="avatar",
            field=models.ImageField(blank=True, upload_to="avatars/"),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="address",
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="business_phone",
            field=models.CharField(blank=True, max_length=30),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="cover",
            field=models.ImageField(blank=True, upload_to="sellers/covers/"),
        ),
        migrations.AddField(
            model_name="sellerprofile",
            name="logo",
            field=models.ImageField(blank=True, upload_to="sellers/logos/"),
        ),
    ]
