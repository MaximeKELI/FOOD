import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


def emit_order_status(order_id: int, status: str, vendor_id: int | None = None) -> None:
    rooms = [f"order:{order_id}"]
    if vendor_id:
        rooms.append(f"vendor:{vendor_id}")
    for room in rooms:
        _emit(
            {
                "event": "order:status",
                "room": room,
                "data": {"order_id": order_id, "status": status},
            }
        )


def emit_notification(user_id: int, payload: dict) -> None:
    _emit(
        {
            "event": "notification",
            "room": f"user:{user_id}",
            "data": payload,
        }
    )


def _emit(body: dict) -> None:
    url = getattr(settings, "SOCKET_EMIT_URL", "")
    if not url:
        return
    try:
        requests.post(
            url,
            json=body,
            headers={"X-Internal-Secret": settings.SOCKET_INTERNAL_SECRET},
            timeout=3,
        )
    except requests.RequestException as exc:
        logger.warning("Socket emit failed: %s", exc)
