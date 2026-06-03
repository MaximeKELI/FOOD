from django.urls import path

from .views import DeliveryDetailView, DeliveryLocationView, DriverMeView

urlpatterns = [
    path("drivers/me/", DriverMeView.as_view(), name="driver_me"),
    path("<int:pk>/", DeliveryDetailView.as_view(), name="delivery_detail"),
    path(
        "<int:pk>/location/",
        DeliveryLocationView.as_view(),
        name="delivery_location",
    ),
]
