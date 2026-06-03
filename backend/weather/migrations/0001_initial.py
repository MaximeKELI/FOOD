import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="WeatherNudgeLog",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("sent_at", models.DateTimeField(auto_now_add=True)),
                ("condition", models.CharField(blank=True, max_length=20)),
                ("temperature_c", models.FloatField(blank=True, null=True)),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="weather_nudge_logs",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "ordering": ["-sent_at"],
                "indexes": [
                    models.Index(
                        fields=["user", "-sent_at"],
                        name="weather_wea_user_id_6e8f0a_idx",
                    )
                ],
            },
        ),
    ]
