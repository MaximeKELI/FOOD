"""Helpers for analytics: IP, geocoding, weather enrichment."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

import requests
from django.utils import timezone
from django.utils.dateparse import parse_datetime

logger = logging.getLogger(__name__)

NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse"
NOMINATIM_TIMEOUT = 8


def get_client_ip(request) -> str | None:
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


def _parse_device_time(value) -> datetime | None:
    if not value:
        return None
    if isinstance(value, datetime):
        dt = value
    else:
        dt = parse_datetime(str(value))
    if dt is None:
        return None
    if timezone.is_naive(dt):
        return timezone.make_aware(dt, timezone.get_current_timezone())
    return dt


def reverse_geocode(latitude: float, longitude: float) -> dict[str, str]:
    """Best-effort city/country from coordinates (OpenStreetMap Nominatim)."""
    try:
        response = requests.get(
            NOMINATIM_URL,
            params={
                "lat": latitude,
                "lon": longitude,
                "format": "json",
                "accept-language": "fr",
            },
            headers={"User-Agent": "ChezMama-FoodApp/1.0"},
            timeout=NOMINATIM_TIMEOUT,
        )
        response.raise_for_status()
        data = response.json()
        address = data.get("address") or {}
        city = (
            address.get("city")
            or address.get("town")
            or address.get("village")
            or address.get("municipality")
            or address.get("county")
            or ""
        )
        return {
            "city": city,
            "country": address.get("country", ""),
            "region": address.get("state") or address.get("region") or "",
        }
    except Exception as exc:
        logger.debug("reverse_geocode failed: %s", exc)
        return {"city": "", "country": "", "region": ""}


def fetch_weather_snapshot(latitude: float, longitude: float) -> dict[str, Any]:
    from weather.service import fetch_weather

    try:
        weather = fetch_weather(latitude, longitude)
        return {
            "weather_condition": weather.condition,
            "temperature_c": weather.temperature_c,
            "weather_code": weather.weather_code,
            "is_sunny": weather.is_sunny,
            "is_rainy": weather.is_rainy,
            "cloud_cover": weather.cloud_cover,
        }
    except Exception as exc:
        logger.debug("fetch_weather_snapshot failed: %s", exc)
        return {}


def resolve_location(data: dict) -> dict[str, Any]:
    """Fill city/country/region from payload or reverse geocoding."""
    city = (data.get("city") or "").strip()
    country = (data.get("country") or "").strip()
    region = (data.get("region") or "").strip()
    lat = data.get("latitude")
    lng = data.get("longitude")

    if lat is not None and lng is not None and not city:
        geo = reverse_geocode(float(lat), float(lng))
        city = city or geo["city"]
        country = country or geo["country"]
        region = region or geo["region"]

    return {
        "latitude": lat,
        "longitude": lng,
        "city": city,
        "country": country,
        "region": region,
    }


def enrich_with_weather(data: dict) -> dict[str, Any]:
    lat = data.get("latitude")
    lng = data.get("longitude")
    if lat is None or lng is None:
        return {}
    return fetch_weather_snapshot(float(lat), float(lng))


def extract_context_fields(data: dict, request=None) -> dict[str, Any]:
    """Normalize client context payload from API request."""
    location = resolve_location(data)
    weather = enrich_with_weather(location)

    ip = get_client_ip(request) if request else None
    if not ip:
        ip = data.get("ip_address")

    return {
        "ip_address": ip,
        "latitude": location["latitude"],
        "longitude": location["longitude"],
        "city": location["city"],
        "country": location["country"],
        "region": location["region"],
        "device_time": _parse_device_time(data.get("device_time")),
        "timezone": (data.get("timezone") or "").strip(),
        "brightness": data.get("brightness"),
        "platform": (data.get("platform") or "").strip(),
        "device_model": (data.get("device_model") or "").strip(),
        "app_version": (data.get("app_version") or "").strip(),
        "connection_type": (data.get("connection_type") or "").strip(),
        "battery_level": data.get("battery_level"),
        **weather,
    }
