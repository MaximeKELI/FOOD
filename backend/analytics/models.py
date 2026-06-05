import uuid

from django.conf import settings
from django.db import models


class ClientSession(models.Model):
    """Tracks a client device session across multiple events."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="analytics_sessions",
    )
    session_id = models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    platform = models.CharField(max_length=40, blank=True)
    device_model = models.CharField(max_length=120, blank=True)
    os_version = models.CharField(max_length=40, blank=True)
    app_version = models.CharField(max_length=40, blank=True)

    city = models.CharField(max_length=120, blank=True)
    country = models.CharField(max_length=80, blank=True)
    region = models.CharField(max_length=120, blank=True)
    last_latitude = models.FloatField(null=True, blank=True)
    last_longitude = models.FloatField(null=True, blank=True)
    timezone = models.CharField(max_length=64, blank=True)

    event_count = models.PositiveIntegerField(default=0)
    first_seen = models.DateTimeField(auto_now_add=True)
    last_seen = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-last_seen"]
        verbose_name = "Session client"
        verbose_name_plural = "Sessions clients"

    def __str__(self):
        who = self.user.email if self.user_id else "anonyme"
        return f"Session {self.session_id} ({who})"


class AnalyticsEvent(models.Model):
    """Click, screen view, or other tracked interaction."""

    class EventType(models.TextChoices):
        CLICK = "click", "Clic"
        SCREEN_VIEW = "screen_view", "Vue écran"
        TAP = "tap", "Tap"
        ORDER = "order", "Commande"
        OTHER = "other", "Autre"

    session = models.ForeignKey(
        ClientSession,
        on_delete=models.CASCADE,
        related_name="events",
        null=True,
        blank=True,
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="analytics_events",
    )
    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="analytics_events",
    )

    event_type = models.CharField(
        max_length=20, choices=EventType.choices, default=EventType.OTHER
    )
    name = models.CharField(max_length=120, db_index=True)
    screen = models.CharField(max_length=120, blank=True)
    element = models.CharField(max_length=120, blank=True)

    ip_address = models.GenericIPAddressField(null=True, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    city = models.CharField(max_length=120, blank=True)
    country = models.CharField(max_length=80, blank=True)
    region = models.CharField(max_length=120, blank=True)

    device_time = models.DateTimeField(null=True, blank=True)
    timezone = models.CharField(max_length=64, blank=True)
    brightness = models.FloatField(
        null=True, blank=True, help_text="Luminosité écran (0.0–1.0)"
    )

    weather_condition = models.CharField(max_length=40, blank=True)
    temperature_c = models.FloatField(null=True, blank=True)
    weather_code = models.PositiveSmallIntegerField(null=True, blank=True)
    is_sunny = models.BooleanField(null=True, blank=True)
    cloud_cover = models.PositiveSmallIntegerField(null=True, blank=True)

    platform = models.CharField(max_length=40, blank=True)
    device_model = models.CharField(max_length=120, blank=True)
    app_version = models.CharField(max_length=40, blank=True)
    connection_type = models.CharField(max_length=40, blank=True)
    battery_level = models.FloatField(null=True, blank=True)

    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Événement"
        verbose_name_plural = "Événements"
        indexes = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["name", "-created_at"]),
            models.Index(fields=["city"]),
        ]

    def __str__(self):
        who = self.user.email if self.user_id else "anonyme"
        return f"{self.name} — {who} ({self.created_at:%Y-%m-%d %H:%M})"


class OrderContext(models.Model):
    """Device, location and weather context captured at order time."""

    order = models.OneToOneField(
        "orders.Order",
        on_delete=models.CASCADE,
        related_name="context",
    )

    ip_address = models.GenericIPAddressField(null=True, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    city = models.CharField(max_length=120, blank=True)
    country = models.CharField(max_length=80, blank=True)
    region = models.CharField(max_length=120, blank=True)

    device_time = models.DateTimeField(null=True, blank=True)
    timezone = models.CharField(max_length=64, blank=True)
    brightness = models.FloatField(null=True, blank=True)

    weather_condition = models.CharField(max_length=40, blank=True)
    temperature_c = models.FloatField(null=True, blank=True)
    weather_code = models.PositiveSmallIntegerField(null=True, blank=True)
    is_sunny = models.BooleanField(null=True, blank=True)
    is_rainy = models.BooleanField(null=True, blank=True)
    cloud_cover = models.PositiveSmallIntegerField(null=True, blank=True)

    platform = models.CharField(max_length=40, blank=True)
    device_model = models.CharField(max_length=120, blank=True)
    app_version = models.CharField(max_length=40, blank=True)
    connection_type = models.CharField(max_length=40, blank=True)
    battery_level = models.FloatField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Contexte commande"
        verbose_name_plural = "Contextes commande"

    def __str__(self):
        return f"Contexte commande #{self.order_id}"


class ContentEngagement(models.Model):
    """Time spent viewing a meal, video or short."""

    class ContentType(models.TextChoices):
        MEAL = "meal", "Plat / Nourriture"
        VIDEO = "video", "Vidéo"
        SHORT = "short", "Short"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="content_engagements",
    )
    session = models.ForeignKey(
        ClientSession,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="content_engagements",
    )

    content_type = models.CharField(max_length=20, choices=ContentType.choices, db_index=True)
    content_id = models.PositiveIntegerField(db_index=True)
    content_title = models.CharField(max_length=200, blank=True)

    duration_seconds = models.PositiveIntegerField(default=0)
    city = models.CharField(max_length=120, blank=True)
    platform = models.CharField(max_length=40, blank=True)

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Engagement contenu"
        verbose_name_plural = "Engagements contenu"
        indexes = [
            models.Index(fields=["content_type", "content_id"]),
            models.Index(fields=["user", "-created_at"]),
        ]

    def __str__(self):
        who = self.user.email if self.user_id else "anonyme"
        return (
            f"{self.get_content_type_display()} #{self.content_id} "
            f"({self.duration_seconds}s) — {who}"
        )

    @property
    def duration_display(self) -> str:
        s = self.duration_seconds
        if s < 60:
            return f"{s}s"
        m, sec = divmod(s, 60)
        if m < 60:
            return f"{m}m {sec}s"
        h, m = divmod(m, 60)
        return f"{h}h {m}m"


class AnalyticsDashboard(models.Model):
    """Proxy entry point for the analytics dashboard in admin."""

    class Meta:
        managed = False
        verbose_name = "Tableau Analytics"
        verbose_name_plural = "Tableau Analytics"
        app_label = "analytics"
