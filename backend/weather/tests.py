from datetime import datetime
import unittest
from unittest.mock import MagicMock, patch
from zoneinfo import ZoneInfo

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from notifications.models import Notification
from weather.nudges import build_nudge
from weather.service import WeatherSnapshot
from weather.tasks import send_weather_nudge_to_user

User = get_user_model()


class WeatherMessageTests(unittest.TestCase):
    """Pure unit tests (no database)."""

    def test_hot_lunch_message(self):
        weather = WeatherSnapshot(
            temperature_c=32,
            weather_code=0,
            is_day=True,
            cloud_cover=10,
            latitude=14.72,
            longitude=-17.47,
        )
        noon = datetime(2026, 6, 2, 12, 0, tzinfo=ZoneInfo("Africa/Dakar"))
        nudge = build_nudge(weather, now=noon)
        self.assertEqual(nudge.condition, "hot")
        self.assertIn("chaud", nudge.message.lower())
        self.assertIn("jus", nudge.message.lower())

    def test_cold_lunch_foutou(self):
        weather = WeatherSnapshot(
            temperature_c=18,
            weather_code=3,
            is_day=True,
            cloud_cover=50,
            latitude=14.72,
            longitude=-17.47,
        )
        noon = datetime(2026, 1, 15, 12, 30, tzinfo=ZoneInfo("Africa/Dakar"))
        nudge = build_nudge(weather, now=noon)
        self.assertEqual(nudge.condition, "cold")
        self.assertIn("foutou", nudge.message.lower())


class WeatherNudgeTests(TestCase):
    @patch("weather.tasks.fetch_weather")
    @patch("weather.tasks.notify")
    def test_send_nudge_creates_notification(self, mock_notify, mock_fetch):
        mock_fetch.return_value = WeatherSnapshot(
            temperature_c=30,
            weather_code=0,
            is_day=True,
            cloud_cover=5,
            latitude=14.72,
            longitude=-17.47,
        )
        user = User.objects.create_user(email="w@test.com", password="pass12345")
        sent = send_weather_nudge_to_user(user, force=True)
        self.assertTrue(sent)
        mock_notify.assert_called_once()
        self.assertEqual(mock_notify.call_args[0][1], Notification.Kind.WEATHER)

    def test_suggestion_api(self):
        client = self.client
        with patch("weather.views.fetch_weather") as mock_fetch:
            mock_fetch.return_value = WeatherSnapshot(
                temperature_c=31,
                weather_code=0,
                is_day=True,
                cloud_cover=0,
                latitude=14.72,
                longitude=-17.47,
            )
            res = client.get("/api/weather/suggestion/?latitude=14.72&longitude=-17.47")
        self.assertEqual(res.status_code, 200)
        self.assertIn("jus", res.json()["message"].lower())
