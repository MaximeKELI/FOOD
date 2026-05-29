from django.conf import settings
from django.db import models

from catalog.models import Meal


class Order(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        PREPARING = "preparing", "En préparation"
        ON_THE_WAY = "on_the_way", "En route"
        DELIVERED = "delivered", "Livrée"
        CANCELLED = "cancelled", "Annulée"

    class Fulfillment(models.TextChoices):
        DELIVERY = "delivery", "Livraison"
        PICKUP = "pickup", "Retrait"

    class Payment(models.TextChoices):
        CASH = "cash", "À la livraison"
        WAVE = "wave", "Wave"
        ORANGE_MONEY = "orange_money", "Orange Money"
        FREE_MONEY = "free_money", "Free Money"

    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="orders",
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    fulfillment = models.CharField(
        max_length=20, choices=Fulfillment.choices, default=Fulfillment.DELIVERY
    )
    payment_method = models.CharField(
        max_length=20, choices=Payment.choices, default=Payment.CASH
    )
    address = models.CharField(max_length=255, blank=True)
    phone = models.CharField(max_length=30, blank=True)
    note = models.TextField(blank=True)

    total = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Commande #{self.id} de {self.customer.name}"

    def recompute_total(self):
        self.total = sum(item.line_total for item in self.items.all())
        return self.total


class OrderItem(models.Model):
    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, related_name="items"
    )
    meal = models.ForeignKey(
        Meal, on_delete=models.SET_NULL, null=True, related_name="order_items"
    )
    # Snapshot fields (kept even if the meal is later deleted/edited)
    meal_name = models.CharField(max_length=160)
    unit_price = models.PositiveIntegerField(default=0)
    quantity = models.PositiveIntegerField(default=1)

    @property
    def line_total(self):
        return self.unit_price * self.quantity

    def __str__(self):
        return f"{self.quantity} x {self.meal_name}"
