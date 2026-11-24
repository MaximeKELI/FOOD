"""Internal service-to-service endpoints (socket gateway, workers)."""

from django.conf import settings
from django.db.models import Q
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from chat.models import Conversation
from deliveries.models import Delivery
from orders.models import Order, OrderItem


def _internal_secret_ok(request) -> bool:
    expected = getattr(settings, "SOCKET_INTERNAL_SECRET", "") or ""
    provided = request.headers.get("X-Internal-Secret", "")
    return bool(expected) and provided == expected


def user_can_join_room(user_id: int, room: str) -> bool:
    """Return True when user_id is allowed to subscribe to room."""
    if not room or ":" not in room:
        return False
    kind, _, raw_id = room.partition(":")
    if not raw_id or not raw_id.isdigit():
        return False
    target_id = int(raw_id)

    if kind == "user":
        return target_id == user_id
    if kind == "vendor":
        return target_id == user_id

    if kind == "conversation":
        return Conversation.objects.filter(
            pk=target_id
        ).filter(Q(user_low_id=user_id) | Q(user_high_id=user_id)).exists()

    if kind == "order":
        order = Order.objects.filter(pk=target_id).first()
        if order is None:
            return False
        if order.customer_id == user_id:
            return True
        if OrderItem.objects.filter(order=order, meal__seller_id=user_id).exists():
            return True
        delivery = Delivery.objects.filter(order=order).select_related("driver").first()
        if delivery and delivery.driver_id and delivery.driver.user_id == user_id:
            return True
        return False

    if kind == "delivery":
        delivery = (
            Delivery.objects.select_related("order", "driver")
            .filter(pk=target_id)
            .first()
        )
        if delivery is None:
            return False
        order = delivery.order
        if order.customer_id == user_id:
            return True
        if delivery.driver_id and delivery.driver.user_id == user_id:
            return True
        if OrderItem.objects.filter(order=order, meal__seller_id=user_id).exists():
            return True
        return False

    return False


class SocketAuthorizeView(APIView):
    """Called by the socket gateway to ACL room joins."""

    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        if not _internal_secret_ok(request):
            return Response({"detail": "Forbidden"}, status=status.HTTP_403_FORBIDDEN)

        try:
            user_id = int(request.data.get("user_id"))
        except (TypeError, ValueError):
            return Response(
                {"detail": "user_id invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        rooms = request.data.get("rooms") or []
        if not isinstance(rooms, list):
            return Response(
                {"detail": "rooms doit être une liste."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        allowed = []
        for room in rooms:
            if isinstance(room, str) and user_can_join_room(user_id, room):
                allowed.append(room)

        return Response({"allowed": allowed})
