from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path, reverse
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

from notifications.views import NotificationClearView, NotificationDeleteOneView
from weather.views import WeatherNotifyMeView, WeatherSuggestionView


def api_root(_request):
    return JsonResponse(
        {
            "name": "Food API",
            "version": "1.0",
            "endpoints": {
                "auth": "/api/auth/",
                "catalog": "/api/catalog/",
                "social": "/api/social/",
                "orders": "/api/orders/",
                "payments": "/api/payments/",
                "notifications": "/api/notifications/",
                "chat": "/api/chat/",
                "deliveries": "/api/deliveries/",
                "weather": "/api/weather/suggestion/",
                "analytics": "/api/analytics/events/",
                "docs": "/api/docs/",
                "redoc": "/api/redoc/",
                "schema": "/api/schema/",
                "health": "/health/",
                "admin": "/admin/",
            },
        }
    )


def health(_request):
    from django.db import connection

    try:
        connection.ensure_connection()
        db_ok = True
    except Exception:
        db_ok = False
    try:
        reverse("weather_suggestion")
        weather_ok = True
    except Exception:
        weather_ok = False
    payload = {
        "status": "ok" if db_ok and weather_ok else "degraded",
        "database": db_ok,
        "weather_api": weather_ok,
    }
    status_code = 200 if db_ok and weather_ok else 503
    return JsonResponse(payload, status=status_code)


urlpatterns = [
    path("", api_root),
    path("health/", health, name="health"),
    path("admin/", admin.site.urls),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "api/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
    path("api/auth/", include("accounts.urls")),
    path("api/catalog/", include("catalog.urls")),
    path("api/social/", include("social.urls")),
    path("api/", include("orders.urls")),
    path("api/", include("payments.urls")),
    path("api/", include("notifications.urls")),
    path(
        "api/notifications/clear/",
        NotificationClearView.as_view(),
        name="notifications_clear_root",
    ),
    path(
        "api/notifications/<int:pk>/",
        NotificationDeleteOneView.as_view(),
        name="notification_delete_root",
    ),
    path(
        "api/notifications/<int:pk>/delete/",
        NotificationDeleteOneView.as_view(),
        name="notification_delete_post_root",
    ),
    path("api/", include("chat.urls")),
    path("api/deliveries/", include("deliveries.urls")),
    path("api/", include("analytics.urls")),
    path(
        "api/weather/suggestion/",
        WeatherSuggestionView.as_view(),
        name="weather_suggestion",
    ),
    path(
        "api/weather/notify/",
        WeatherNotifyMeView.as_view(),
        name="weather_notify",
    ),
]

if settings.DEBUG or settings.SERVE_MEDIA:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
