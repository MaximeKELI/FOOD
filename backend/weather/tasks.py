"""Send weather-based food nudges to users."""

from __future__ import annotations

import logging
from datetime import timedelta

from decouple import config
from django.contrib.auth import get_user_model
from django.utils import timezone

from notifications.models import Notification, notify

from .locations import coordinates_for_user
from .models import WeatherNudgeLog
from .nudges import build_nudge
from .service import fetch_weather

logger = logging.getLogger(__name__)
User = get_user_model()


def nudge_interval() -> timedelta:
    """Default 5 h. Set WEATHER_NUDGE_INTERVAL_SECONDS=10 for local testing."""
    seconds = config("WEATHER_NUDGE_INTERVAL_SECONDS", default=18000, cast=int)
    return timedelta(seconds=max(1, seconds))


def send_weather_nudge_to_user(user, *, force: bool = False) -> bool:
    """Returns True if a notification was sent."""
    if not force:
        cutoff = timezone.now() - nudge_interval()
        if WeatherNudgeLog.objects.filter(user=user, sent_at__gte=cutoff).exists():
            return False

    lat, lon = coordinates_for_user(user)
    try:
        weather = fetch_weather(lat, lon)
    except Exception as exc:
        logger.warning("Weather fetch failed for user %s: %s", user.pk, exc)
        return False

    nudge = build_nudge(weather)
    if not nudge.should_notify:
        return False

    notify(
        user,
        Notification.Kind.WEATHER,
        nudge.title,
        nudge.message,
        link="home",
    )
    WeatherNudgeLog.objects.create(
        user=user,
        condition=nudge.condition,
        temperature_c=weather.temperature_c,
    )
    logger.info("Weather nudge sent to user %s: %s", user.pk, nudge.title)
    return True


def send_all_weather_nudges() -> int:
    """Send nudges to all eligible users. Returns count sent."""
    sent = 0
    cutoff = timezone.now() - nudge_interval()
    users = User.objects.filter(is_active=True)
    for user in users.iterator(chunk_size=100):
        if WeatherNudgeLog.objects.filter(user=user, sent_at__gte=cutoff).exists():
            continue
        if send_weather_nudge_to_user(user):
            sent += 1
    return sent
