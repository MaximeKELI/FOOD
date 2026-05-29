from django.conf import settings
from django.db import models


class Notification(models.Model):
    class Kind(models.TextChoices):
        ORDER = "order", "Commande"
        FOLLOW = "follow", "Abonnement"
        REVIEW = "review", "Avis"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    kind = models.CharField(max_length=20, choices=Kind.choices)
    title = models.CharField(max_length=160)
    body = models.CharField(max_length=300, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.kind} -> {self.recipient.email}"


def notify(recipient, kind, title, body=""):
    """Helper to create a notification (no-op if recipient is None)."""
    if recipient is None:
        return None
    return Notification.objects.create(
        recipient=recipient, kind=kind, title=title, body=body
    )
