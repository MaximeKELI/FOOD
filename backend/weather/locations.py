"""Resolve coordinates for weather lookups."""

from __future__ import annotations

from django.contrib.auth import get_user_model

from .service import default_coordinates

User = get_user_model()


def coordinates_for_user(user) -> tuple[float, float]:
    profile = getattr(user, "seller_profile", None)
    if profile is not None and profile.latitude is not None and profile.longitude is not None:
        return profile.latitude, profile.longitude

    from orders.models import Order

    order = (
        Order.objects.filter(user=user)
        .exclude(latitude__isnull=True)
        .exclude(longitude__isnull=True)
        .order_by("-created_at")
        .first()
    )
    if order is not None:
        return order.latitude, order.longitude

    return default_coordinates()
