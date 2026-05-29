"""Optional FCM push delivery. Requires FIREBASE_CREDENTIALS_PATH in production."""

import logging

from decouple import config

logger = logging.getLogger(__name__)


def send_push_to_user(user, title, body, data=None):
    """Send push to all registered devices. No-op if Firebase is not configured."""
    cred_path = config("FIREBASE_CREDENTIALS_PATH", default="")
    if not cred_path:
        return 0

    from .models import PushDevice

    tokens = list(
        PushDevice.objects.filter(user=user).values_list("token", flat=True)
    )
    if not tokens:
        return 0

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        return response.success_count
    except Exception as exc:
        logger.warning("FCM send failed: %s", exc)
        return 0
