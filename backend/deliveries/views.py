from django.conf import settings
from django.db import transaction
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from orders.models import OrderItem

from .models import Delivery, Driver
from .realtime import emit_delivery_location
from .serializers import (
    DeliveryLocationSerializer,
    DeliverySerializer,
    DriverSerializer,
    DriverUpdateSerializer,
)

ALLOWED_DELIVERY_TRANSITIONS = {
    Delivery.Status.PENDING: {Delivery.Status.ASSIGNED, Delivery.Status.CANCELLED},
    Delivery.Status.ASSIGNED: {
        Delivery.Status.PICKED_UP,
        Delivery.Status.CANCELLED,
    },
    Delivery.Status.PICKED_UP: {
        Delivery.Status.IN_TRANSIT,
        Delivery.Status.CANCELLED,
    },
    Delivery.Status.IN_TRANSIT: {
        Delivery.Status.DELIVERED,
        Delivery.Status.CANCELLED,
    },
    Delivery.Status.DELIVERED: set(),
    Delivery.Status.CANCELLED: set(),
}


class DeliveriesFeatureMixin:
    def dispatch(self, request, *args, **kwargs):
        if not settings.DELIVERIES_ENABLED:
            return Response(
                {"detail": "Module livraison non activé."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return super().dispatch(request, *args, **kwargs)


def _can_view_delivery(user, delivery):
    order = delivery.order
    if order.customer_id == user.id:
        return True
    if delivery.driver_id and delivery.driver.user_id == user.id:
        return True
    if OrderItem.objects.filter(order=order, meal__seller=user).exists():
        return True
    return user.is_staff


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
        if not _can_view_delivery(request.user, delivery):
            return Response(status=status.HTTP_403_FORBIDDEN)
        return Response(DeliverySerializer(delivery).data)


@extend_schema(tags=["deliveries"])
class DeliveryPendingListView(DeliveriesFeatureMixin, APIView):
    """Pending deliveries available for drivers to accept."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        driver, _ = Driver.objects.get_or_create(user=request.user)
        if not driver.is_active:
            return Response(
                {"detail": "Profil chauffeur inactif."},
                status=status.HTTP_403_FORBIDDEN,
            )
        qs = (
            Delivery.objects.filter(status=Delivery.Status.PENDING)
            .select_related("order", "driver__user")
            .order_by("-created_at")
        )
        return Response(DeliverySerializer(qs, many=True).data)


@extend_schema(tags=["deliveries"])
class DeliveryAcceptView(DeliveriesFeatureMixin, APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        delivery = (
            Delivery.objects.select_for_update()
            .select_related("order", "driver__user")
            .filter(pk=pk)
            .first()
        )
        if delivery is None:
            return Response(
                {"detail": "Livraison introuvable."},
                status=status.HTTP_404_NOT_FOUND,
            )
        if delivery.status != Delivery.Status.PENDING:
            return Response(
                {"detail": "Cette livraison n'est plus disponible."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        driver, _ = Driver.objects.select_for_update().get_or_create(
            user=request.user
        )
        if not driver.is_active:
            return Response(
                {"detail": "Profil chauffeur inactif."},
                status=status.HTTP_403_FORBIDDEN,
            )
        delivery.driver = driver
        delivery.status = Delivery.Status.ASSIGNED
        delivery.save(update_fields=["driver", "status", "updated_at"])
        driver.status = Driver.Status.BUSY
        driver.save(update_fields=["status"])
        return Response(DeliverySerializer(delivery).data)


@extend_schema(tags=["deliveries"])
class DeliveryStatusView(DeliveriesFeatureMixin, APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def patch(self, request, pk):
        delivery = (
            Delivery.objects.select_for_update()
            .select_related("order", "driver__user")
            .filter(pk=pk)
            .first()
        )
        if delivery is None:
            return Response(
                {"detail": "Livraison introuvable."},
                status=status.HTTP_404_NOT_FOUND,
            )
        driver, _ = Driver.objects.get_or_create(user=request.user)
        if delivery.driver_id != driver.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        new_status = request.data.get("status")
        valid = dict(Delivery.Status.choices)
        if new_status not in valid:
            return Response(
                {"detail": "Statut invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        allowed = ALLOWED_DELIVERY_TRANSITIONS.get(delivery.status, set())
        if new_status != delivery.status and new_status not in allowed:
            return Response(
                {
                    "detail": (
                        f"Transition impossible : {delivery.get_status_display()} "
                        f"→ {valid[new_status]}."
                    )
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        delivery.status = new_status
        delivery.save(update_fields=["status", "updated_at"])
        if new_status in (Delivery.Status.DELIVERED, Delivery.Status.CANCELLED):
            driver.status = Driver.Status.AVAILABLE
            driver.save(update_fields=["status"])
        return Response(DeliverySerializer(delivery).data)


@extend_schema(tags=["deliveries"])
class DeliveryByOrderView(DeliveriesFeatureMixin, APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, order_id):
        delivery = get_object_or_404(
            Delivery.objects.select_related("order", "driver__user"),
            order_id=order_id,
        )
        if not _can_view_delivery(request.user, delivery):
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
