"""Emit delivery tracking events to the Socket.io gateway."""

import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


def emit_delivery_location(delivery_id: int, latitude: float, longitude: float) -> None:
    payload = {
        "event": "delivery:location",
        "room": f"delivery:{delivery_id}",
        "data": {
            "delivery_id": delivery_id,
            "latitude": latitude,
            "longitude": longitude,
        },
    }
    _emit(payload)


def _emit(payload: dict) -> None:
    url = getattr(settings, "SOCKET_EMIT_URL", "")
    if not url:
        return
    try:
        requests.post(
            url,
            json=payload,
            headers={"X-Internal-Secret": settings.SOCKET_INTERNAL_SECRET},
            timeout=3,
        )
    except requests.RequestException as exc:
        logger.warning("Socket emit failed: %s", exc)
