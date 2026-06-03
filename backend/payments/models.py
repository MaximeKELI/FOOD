from django.conf import settings
from django.db import models


class PaymentIntent(models.Model):
    class Provider(models.TextChoices):
        STRIPE = "stripe", "Stripe"
        WAVE = "wave", "Wave"
        ORANGE_MONEY = "orange_money", "Orange Money"

    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        PROCESSING = "processing", "En cours"
        PAID = "paid", "Payé"
        FAILED = "failed", "Échoué"
        CANCELLED = "cancelled", "Annulé"

    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.CASCADE,
        related_name="payment_intents",
    )
    provider = models.CharField(max_length=20, choices=Provider.choices)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    amount = models.PositiveIntegerField()
    external_id = models.CharField(max_length=120, blank=True)
    checkout_url = models.URLField(blank=True)
    client_secret = models.CharField(max_length=255, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["external_id"]),
            models.Index(fields=["order", "status"]),
        ]

    def __str__(self):
        return f"Paiement {self.provider} #{self.pk} ({self.status})"
