from django.conf import settings
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Delivery, Driver
from .realtime import emit_delivery_location
from .serializers import (
    DeliveryLocationSerializer,
    DeliverySerializer,
    DriverSerializer,
    DriverUpdateSerializer,
)


class DeliveriesFeatureMixin:
    def dispatch(self, request, *args, **kwargs):
        if not settings.DELIVERIES_ENABLED:
            return Response(
                {"detail": "Module livraison non activé."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return super().dispatch(request, *args, **kwargs)


@extend_schema(tags=["deliveries"])
class DriverMeView(DeliveriesFeatureMixin, APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        driver, _ = Driver.objects.get_or_create(user=request.user)
        return Response(DriverSerializer(driver).data)

    @extend_schema(request=DriverUpdateSerializer, responses={200: DriverSerializer})
    def patch(self, request):
        driver, _ = Driver.objects.get_or_create(user=request.user)
        ser = DriverUpdateSerializer(driver, data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(DriverSerializer(driver).data)


@extend_schema(tags=["deliveries"])
class DeliveryDetailView(DeliveriesFeatureMixin, APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        delivery = get_object_or_404(
            Delivery.objects.select_related("order", "driver__user"),
            pk=pk,
        )
        order = delivery.order
        if order.customer_id != request.user.id and (
            delivery.driver is None or delivery.driver.user_id != request.user.id
        ):
            return Response(status=status.HTTP_403_FORBIDDEN)
        return Response(DeliverySerializer(delivery).data)


@extend_schema(tags=["deliveries"])
class DeliveryLocationView(DeliveriesFeatureMixin, APIView):
    """Driver updates GPS position; emits realtime tracking event."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(request=DeliveryLocationSerializer, responses={200: DeliverySerializer})
    def patch(self, request, pk):
        delivery = get_object_or_404(
            Delivery.objects.select_related("order", "driver__user"),
            pk=pk,
        )
        driver, _ = Driver.objects.get_or_create(user=request.user)
        if delivery.driver_id != driver.id:
            return Response(status=status.HTTP_403_FORBIDDEN)

        ser = DeliveryLocationSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        lat = ser.validated_data["latitude"]
        lng = ser.validated_data["longitude"]
        driver.latitude = lat
        driver.longitude = lng
        driver.save(update_fields=["latitude", "longitude"])
        if "eta_minutes" in ser.validated_data:
            delivery.eta_minutes = ser.validated_data["eta_minutes"]
        delivery.save(update_fields=["eta_minutes", "updated_at"])
        emit_delivery_location(delivery.id, lat, lng)
        return Response(DeliverySerializer(delivery).data)
