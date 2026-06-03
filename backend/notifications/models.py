from django.conf import settings
from django.db import models


class Notification(models.Model):
    class Kind(models.TextChoices):
        ORDER = "order", "Commande"
        ORDER_STATUS = "order_status", "Statut commande"
        FOLLOW = "follow", "Abonnement"
        REVIEW = "review", "Avis"
        CHAT = "chat", "Message"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    kind = models.CharField(max_length=20, choices=Kind.choices)
    title = models.CharField(max_length=160)
    body = models.CharField(max_length=300, blank=True)
    related_id = models.PositiveIntegerField(null=True, blank=True)
    link = models.CharField(max_length=40, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["recipient", "is_read", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.kind} -> {self.recipient.email}"


class PushDevice(models.Model):
    """FCM device token for push notifications."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="push_devices",
    )
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(max_length=20, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["user"])]

    def __str__(self):
        return f"Push {self.platform} — {self.user.email}"


def notify(recipient, kind, title, body="", *, related_id=None, link=""):
    """Helper to create a notification (no-op if recipient is None)."""
    if recipient is None:
        return None
    notification = Notification.objects.create(
        recipient=recipient,
        kind=kind,
        title=title,
        body=body,
        related_id=related_id,
        link=link,
    )
    from .push import send_push_to_user

    send_push_to_user(
        recipient,
        title,
        body,
        data={"kind": kind, "related_id": related_id or "", "link": link},
    )
    from payments.realtime import emit_notification

    emit_notification(
        recipient.id,
        {
            "id": notification.id,
            "kind": kind,
            "title": title,
            "body": body,
            "related_id": related_id,
            "link": link,
        },
    )
    return notification
