import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


def emit_chat_message(conversation_id: int, payload: dict) -> None:
    _emit(
        {
            "event": "chat:message",
            "room": f"conversation:{conversation_id}",
            "data": payload,
        }
    )


def emit_chat_read(conversation_id: int, user_id: int) -> None:
    _emit(
        {
            "event": "chat:read",
            "room": f"conversation:{conversation_id}",
            "data": {"conversation_id": conversation_id, "user_id": user_id},
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
