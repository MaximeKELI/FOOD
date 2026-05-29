from django.conf import settings
from django.db import models


class Conversation(models.Model):
    """A 1:1 conversation between two users (customer ↔ seller)."""

    # Stored with the lower user id first to guarantee uniqueness.
    user_low = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="conversations_low",
    )
    user_high = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="conversations_high",
    )
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-updated_at"]
        unique_together = ("user_low", "user_high")

    @classmethod
    def between(cls, a, b):
        low, high = (a, b) if a.id < b.id else (b, a)
        convo, _ = cls.objects.get_or_create(user_low=low, user_high=high)
        return convo

    def other(self, user):
        return self.user_high if self.user_low_id == user.id else self.user_low

    def __str__(self):
        return f"{self.user_low.email} ↔ {self.user_high.email}"


class Message(models.Model):
    conversation = models.ForeignKey(
        Conversation, on_delete=models.CASCADE, related_name="messages"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_messages",
    )
    text = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.sender.email}: {self.text[:30]}"
