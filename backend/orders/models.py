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
        STRIPE = "stripe", "Carte (Stripe)"
        WAVE = "wave", "Wave"
        ORANGE_MONEY = "orange_money", "Orange Money"
        FREE_MONEY = "free_money", "Free Money"

    class PaymentStatus(models.TextChoices):
        NOT_REQUIRED = "not_required", "Non requis"
        PENDING = "pending", "En attente"
        PROCESSING = "processing", "En cours"
        PAID = "paid", "Payé"
        FAILED = "failed", "Échoué"

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
    payment_status = models.CharField(
        max_length=20,
        choices=PaymentStatus.choices,
        default=PaymentStatus.NOT_REQUIRED,
    )
    address = models.CharField(max_length=255, blank=True)
    phone = models.CharField(max_length=30, blank=True)
    note = models.TextField(blank=True)

    # Customer location (used to compute the delivery fee).
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    subtotal = models.PositiveIntegerField(default=0)
    delivery_fee = models.PositiveIntegerField(default=0)
    discount = models.PositiveIntegerField(default=0)
    promo_code = models.CharField(max_length=40, blank=True)
    points_earned = models.PositiveIntegerField(default=0)
    points_awarded = models.BooleanField(default=False)
    points_redeemed = models.PositiveIntegerField(default=0)

    # Scheduled delivery / pickup (null = ASAP).
    scheduled_for = models.DateTimeField(null=True, blank=True)
    cancellation_reason = models.CharField(max_length=255, blank=True)
    cancelled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="cancelled_orders",
    )

    total = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["customer", "-created_at"]),
            models.Index(fields=["status"]),
            models.Index(fields=["payment_status"]),
        ]

    def __str__(self):
        return f"Commande #{self.id} de {self.customer.name}"

    def recompute_total(self):
        self.subtotal = sum(item.line_total for item in self.items.all())
        # 1 loyalty point = 1 FCFA when redeemed
        points_discount = self.points_redeemed or 0
        self.total = max(
            0, self.subtotal + self.delivery_fee - self.discount - points_discount
        )
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
    note = models.CharField(max_length=200, blank=True)
    # Selected options snapshot: [{"group": "Taille", "choice": "L", "extra": 200}]
    options = models.JSONField(default=list, blank=True)
    options_extra = models.PositiveIntegerField(default=0)

    @property
    def line_total(self):
        return (self.unit_price + self.options_extra) * self.quantity

    def __str__(self):
        return f"{self.quantity} x {self.meal_name}"


class OrderStatusEvent(models.Model):
    """Timeline of status changes for an order."""

    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, related_name="status_events"
    )
    status = models.CharField(max_length=20)
    note = models.CharField(max_length=255, blank=True)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="order_status_events",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Order #{self.order_id} → {self.status}"


class PromoCode(models.Model):
    """A discount code, optionally restricted to one seller."""

    code = models.CharField(max_length=40, unique=True)
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="promo_codes",
        null=True,
        blank=True,
    )
    percent = models.PositiveSmallIntegerField(default=0)  # 0..100
    amount = models.PositiveIntegerField(default=0)  # flat FCFA discount
    min_total = models.PositiveIntegerField(default=0)
    active = models.BooleanField(default=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def discount_for(self, subtotal):
        from django.utils import timezone

        if not self.active or subtotal < self.min_total:
            return 0
        now = timezone.now()
        if self.starts_at and now < self.starts_at:
            return 0
        if self.ends_at and now > self.ends_at:
            return 0
        value = self.amount
        if self.percent:
            value += subtotal * self.percent // 100
        return min(value, subtotal)

    def __str__(self):
        return self.code
