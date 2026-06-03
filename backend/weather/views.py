from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .locations import coordinates_for_user
from .nudges import build_nudge
from .service import default_coordinates, fetch_weather
from .tasks import nudge_interval, send_weather_nudge_to_user


class WeatherSuggestionView(APIView):
    """
    Current weather + contextual food suggestion.
    Optional query: ?latitude=&longitude=
    """

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        responses={
            200: {
                "type": "object",
                "properties": {
                    "temperature_c": {"type": "number"},
                    "is_sunny": {"type": "boolean"},
                    "is_day": {"type": "boolean"},
                    "condition": {"type": "string"},
                    "title": {"type": "string"},
                    "message": {"type": "string"},
                },
            }
        }
    )
    def get(self, request):
        lat = request.query_params.get("latitude")
        lon = request.query_params.get("longitude")
        if lat is not None and lon is not None:
            try:
                latitude = float(lat)
                longitude = float(lon)
            except (TypeError, ValueError):
                return Response(
                    {"detail": "Coordonnées invalides."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        elif request.user.is_authenticated:
            latitude, longitude = coordinates_for_user(request.user)
        else:
            latitude, longitude = default_coordinates()

        try:
            weather = fetch_weather(latitude, longitude)
        except Exception as exc:
            return Response(
                {"detail": f"Météo indisponible: {exc}"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        nudge = build_nudge(weather)
        return Response(
            {
                "temperature_c": weather.temperature_c,
                "weather_code": weather.weather_code,
                "is_sunny": weather.is_sunny,
                "is_day": weather.is_day,
                "is_hot": weather.is_hot,
                "is_cold": weather.is_cold,
                "cloud_cover": weather.cloud_cover,
                "condition": nudge.condition,
                "title": nudge.title,
                "message": nudge.message,
                "latitude": weather.latitude,
                "longitude": weather.longitude,
            }
        )


class WeatherNotifyMeView(APIView):
    """Trigger a weather nudge for the current user (respects 5h throttle unless ?force=1)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        force = request.query_params.get("force") in ("1", "true", "yes")
        sent = send_weather_nudge_to_user(request.user, force=force)
        if not sent and not force:
            secs = int(nudge_interval().total_seconds())
            return Response(
                {
                    "ok": False,
                    "detail": (
                        f"Notification météo déjà envoyée récemment "
                        f"(attendre {secs} s)."
                    ),
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        if not sent:
            return Response(
                {"ok": False, "detail": "Impossible d'envoyer la notification météo."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response({"ok": True, "sent": True})
