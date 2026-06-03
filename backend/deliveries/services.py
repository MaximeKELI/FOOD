"""Delivery dispatch helpers (inactive until DELIVERIES_ENABLED)."""

from django.conf import settings

from orders.models import Order

from .models import Delivery


def create_delivery_for_order(order: Order) -> Delivery | None:
    """Create a pending delivery record when the feature flag is on."""
    if not settings.DELIVERIES_ENABLED:
        return None
    if order.fulfillment != Order.Fulfillment.DELIVERY:
        return None
    delivery, _ = Delivery.objects.get_or_create(
        order=order,
        defaults={
            "dropoff_latitude": order.latitude,
            "dropoff_longitude": order.longitude,
        },
    )
    return delivery
