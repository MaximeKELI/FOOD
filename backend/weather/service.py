"""Open-Meteo weather (free, no API key)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import requests
from decouple import config

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
DEFAULT_TIMEOUT = 12


@dataclass(frozen=True)
class WeatherSnapshot:
    temperature_c: float
    weather_code: int
    is_day: bool
    cloud_cover: int
    latitude: float
    longitude: float

    @property
    def is_sunny(self) -> bool:
        """Clear or mostly clear sky during daytime."""
        if not self.is_day:
            return False
        if self.weather_code in (0, 1):
            return True
        return self.weather_code in (2, 3) and self.cloud_cover <= 35

    @property
    def is_rainy(self) -> bool:
        return self.weather_code >= 51

    @property
    def is_hot(self) -> bool:
        return self.temperature_c >= 28 or (
            self.is_day and self.is_sunny and self.temperature_c >= 26
        )

    @property
    def is_cold(self) -> bool:
        return self.temperature_c <= 20

    @property
    def condition(self) -> str:
        if self.is_rainy:
            return "rainy"
        if self.is_hot:
            return "hot"
        if self.is_cold:
            return "cold"
        if self.is_sunny:
            return "sunny"
        return "mild"


def default_coordinates() -> tuple[float, float]:
    lat = config("WEATHER_DEFAULT_LAT", default=14.7167, cast=float)
    lon = config("WEATHER_DEFAULT_LON", default=-17.4677, cast=float)
    return lat, lon


def fetch_weather(latitude: float, longitude: float) -> WeatherSnapshot:
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": "temperature_2m,weather_code,is_day,cloud_cover",
        "timezone": config("WEATHER_TIMEZONE", default="Africa/Dakar"),
    }
    response = requests.get(OPEN_METEO_URL, params=params, timeout=DEFAULT_TIMEOUT)
    response.raise_for_status()
    data: dict[str, Any] = response.json()
    current = data.get("current") or {}
    return WeatherSnapshot(
        temperature_c=float(current.get("temperature_2m", 25)),
        weather_code=int(current.get("weather_code", 0)),
        is_day=bool(current.get("is_day", 1)),
        cloud_cover=int(current.get("cloud_cover", 0)),
        latitude=float(data.get("latitude", latitude)),
        longitude=float(data.get("longitude", longitude)),
    )
