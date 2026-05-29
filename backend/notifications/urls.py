from django.urls import path

from .views import (
    NotificationListView,
    NotificationMarkOneReadView,
    NotificationMarkReadView,
)

urlpatterns = [
    path("notifications/", NotificationListView.as_view(), name="notifications"),
    path(
        "notifications/read/",
        NotificationMarkReadView.as_view(),
        name="notifications_read",
    ),
    path(
        "notifications/<int:pk>/read/",
        NotificationMarkOneReadView.as_view(),
        name="notification_read_one",
    ),
]
