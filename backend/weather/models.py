from django.conf import settings
from django.db import models


class WeatherNudgeLog(models.Model):
    """Tracks last weather nudge per user (5h throttle)."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="weather_nudge_logs",
    )
    sent_at = models.DateTimeField(auto_now_add=True)
    condition = models.CharField(max_length=20, blank=True)
    temperature_c = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ["-sent_at"]
        indexes = [
            models.Index(fields=["user", "-sent_at"]),
        ]
