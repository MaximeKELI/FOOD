from django.urls import path

from .views import (
    DeliveryAcceptView,
    DeliveryByOrderView,
    DeliveryDetailView,
    DeliveryLocationView,
    DeliveryPendingListView,
    DeliveryStatusView,
    DriverMeView,
)

urlpatterns = [
    path("drivers/me/", DriverMeView.as_view(), name="driver_me"),
    path("pending/", DeliveryPendingListView.as_view(), name="delivery_pending"),
    path(
        "by-order/<int:order_id>/",
        DeliveryByOrderView.as_view(),
        name="delivery_by_order",
    ),
    path("<int:pk>/", DeliveryDetailView.as_view(), name="delivery_detail"),
    path(
        "<int:pk>/accept/",
        DeliveryAcceptView.as_view(),
        name="delivery_accept",
    ),
    path(
        "<int:pk>/status/",
        DeliveryStatusView.as_view(),
        name="delivery_status",
    ),
    path(
        "<int:pk>/location/",
        DeliveryLocationView.as_view(),
        name="delivery_location",
    ),
]
