"""Contextual food suggestions from weather + time of day."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from zoneinfo import ZoneInfo

from decouple import config
from django.utils import timezone

from .service import WeatherSnapshot


@dataclass(frozen=True)
class WeatherNudge:
    title: str
    message: str
    condition: str
    should_notify: bool = True


def _local_hour(now: datetime | None = None) -> int:
    tz_name = config("WEATHER_TIMEZONE", default="Africa/Dakar")
    tz = ZoneInfo(tz_name)
    dt = now or timezone.now()
    if timezone.is_aware(dt):
        return dt.astimezone(tz).hour
    return dt.replace(tzinfo=tz).hour


def _meal_period(hour: int) -> str:
    if 5 <= hour < 11:
        return "morning"
    if 11 <= hour < 15:
        return "lunch"
    if 15 <= hour < 19:
        return "afternoon"
    return "evening"


def build_nudge(weather: WeatherSnapshot, *, now: datetime | None = None) -> WeatherNudge:
    hour = _local_hour(now)
    period = _meal_period(hour)
    temp = round(weather.temperature_c)
    cond = weather.condition

    if weather.is_hot:
        if period == "morning":
            msg = (
                f"Il fait chaud ce matin ({temp}°C). Et si tu commençais la journée "
                "avec un bon jus de fruit bien frais ?"
            )
        elif period == "lunch":
            msg = (
                f"Il fait chaud ce midi ({temp}°C). Un jus de fruit ou une boisson "
                "fraîche, ça te tente ?"
            )
        else:
            msg = (
                f"Il fait chaud ({temp}°C). Pourquoi pas un jus de fruit ou un plat "
                "léger livré chez toi ?"
            )
        title = "☀️ Il fait chaud"
    elif weather.is_cold:
        if period == "lunch":
            msg = (
                f"Il fait frais ce midi ({temp}°C). Un bon foutou bien chaud, "
                "qu'en dis-tu ?"
            )
        elif period == "evening":
            msg = (
                f"Il fait froid ce soir ({temp}°C). Un plat bien chaud te ferait "
                "du bien, non ?"
            )
        else:
            msg = (
                f"Il fait frais ({temp}°C). Un bon foutou ou un plat chaud, "
                "c'est le moment."
            )
        title = "🍲 Il fait frais"
    elif weather.is_rainy:
        msg = (
            "La pluie est là. Reste au chaud, on te livre un bon plat "
            "réconfortant."
        )
        title = "🌧️ Temps pluvieux"
    elif weather.is_sunny and weather.is_day:
        if period == "lunch":
            msg = (
                f"Le soleil brille ({temp}°C). Parfait pour un bon déjeuner "
                "livré sans bouger."
            )
        else:
            msg = (
                "Beau soleil dehors. Envie d'un bon plat ou d'un jus frais "
                "livré chez toi ?"
            )
        title = "☀️ Beau temps"
    else:
        if period == "lunch":
            msg = (
                f"C'est l'heure du déjeuner ({temp}°C). Qu'est-ce qui te ferait "
                "plaisir aujourd'hui ?"
            )
        else:
            msg = (
                "Découvre les plats du moment sur Chez Mama. Livraison rapide "
                "près de chez toi."
            )
        title = "Chez Mama"
        cond = "mild"

    return WeatherNudge(
        title=title,
        message=msg,
        condition=cond,
        should_notify=True,
    )
