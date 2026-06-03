from django.urls import path

from .views import (
    NotificationClearView,
    NotificationDeleteOneView,
    NotificationListView,
    NotificationMarkOneReadView,
    NotificationMarkReadView,
    PushDeviceRegisterView,
)

urlpatterns = [
    path("notifications/", NotificationListView.as_view(), name="notifications"),
    path(
        "notifications/read/",
        NotificationMarkReadView.as_view(),
        name="notifications_read",
    ),
    path(
        "notifications/clear/",
        NotificationClearView.as_view(),
        name="notifications_clear",
    ),
    path(
        "notifications/push/register/",
        PushDeviceRegisterView.as_view(),
        name="push_register",
    ),
    path(
        "notifications/<int:pk>/read/",
        NotificationMarkOneReadView.as_view(),
        name="notification_read_one",
    ),
    path(
        "notifications/<int:pk>/delete/",
        NotificationDeleteOneView.as_view(),
        name="notification_delete_one_post",
    ),
    path(
        "notifications/<int:pk>/",
        NotificationDeleteOneView.as_view(),
        name="notification_delete_one",
    ),
]
