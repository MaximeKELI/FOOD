"""Cross-cutting product features: fees, boosts, loyalty, KYC, slots, lists, flags."""

from django.conf import settings
from django.db import models


class PlatformSettings(models.Model):
    """Singleton-ish ops flags (use pk=1)."""

    payments_enabled = models.BooleanField(default=True)
    cash_enabled = models.BooleanField(default=True)
    digital_payments_enabled = models.BooleanField(default=True)
    new_orders_enabled = models.BooleanField(default=True)
    commission_percent = models.PositiveSmallIntegerField(default=10)
    commission_flat = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "platform settings"

    def __str__(self):
        return "Platform settings"

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


class SellerInvoice(models.Model):
    """Monthly platform fee / commission summary for a seller."""

    class Status(models.TextChoices):
        DRAFT = "draft", "Brouillon"
        DUE = "due", "À payer"
        PAID = "paid", "Payée"

    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="platform_invoices",
    )
    period_start = models.DateField()
    period_end = models.DateField()
    gmv = models.PositiveIntegerField(default=0)
    commission = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.DRAFT
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-period_end"]
        unique_together = ("seller", "period_start", "period_end")


class MealBoost(models.Model):
    """Paid / admin boost that elevates a meal in feeds until expires_at."""

    meal = models.ForeignKey(
        "catalog.Meal", on_delete=models.CASCADE, related_name="boosts"
    )
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="meal_boosts",
    )
    starts_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    score = models.PositiveIntegerField(default=100)
    paid_amount = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-score", "-expires_at"]
        indexes = [models.Index(fields=["expires_at", "-score"])]


class WishList(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="wishlists",
    )
    name = models.CharField(max_length=80, default="Ma liste")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class WishListItem(models.Model):
    wishlist = models.ForeignKey(
        WishList, on_delete=models.CASCADE, related_name="items"
    )
    meal = models.ForeignKey(
        "catalog.Meal", on_delete=models.CASCADE, related_name="wishlist_items"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("wishlist", "meal")
        ordering = ["-created_at"]


class LoyaltyLedger(models.Model):
    class Kind(models.TextChoices):
        EARN = "earn", "Gain"
        REDEEM = "redeem", "Débit"
        ADJUST = "adjust", "Ajustement"
        REFERRAL = "referral", "Parrainage"
        REWARD = "reward", "Récompense"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="loyalty_ledger",
    )
    kind = models.CharField(max_length=20, choices=Kind.choices)
    points = models.IntegerField()
    balance_after = models.IntegerField(default=0)
    note = models.CharField(max_length=255, blank=True)
    related_order = models.ForeignKey(
        "orders.Order",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="loyalty_events",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class LoyaltyTier(models.Model):
    name = models.CharField(max_length=40)
    min_points = models.PositiveIntegerField()
    perk = models.CharField(max_length=160, blank=True)
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["min_points"]


class LoyaltyReward(models.Model):
    title = models.CharField(max_length=120)
    description = models.CharField(max_length=255, blank=True)
    points_cost = models.PositiveIntegerField()
    active = models.BooleanField(default=True)

    class Meta:
        ordering = ["points_cost"]


class KycDocument(models.Model):
    class Subject(models.TextChoices):
        SELLER = "seller", "Vendeur"
        DRIVER = "driver", "Livreur"

    class Status(models.TextChoices):
        PENDING = "pending", "En revue"
        APPROVED = "approved", "Approuvé"
        REJECTED = "rejected", "Refusé"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="kyc_documents",
    )
    subject = models.CharField(max_length=20, choices=Subject.choices)
    document = models.FileField(upload_to="kyc/")
    id_number = models.CharField(max_length=80, blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    review_note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]


class PickupSlot(models.Model):
    """Seller-defined pickup / delivery capacity window."""

    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="pickup_slots",
    )
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    capacity = models.PositiveSmallIntegerField(default=10)
    booked = models.PositiveSmallIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["starts_at"]
        indexes = [models.Index(fields=["seller", "starts_at"])]

    @property
    def remaining(self):
        return max(0, self.capacity - self.booked)


class DisputeEvidence(models.Model):
    dispute = models.ForeignKey(
        "support.Dispute",
        on_delete=models.CASCADE,
        related_name="evidence",
    )
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="dispute_evidence",
    )
    file = models.FileField(upload_to="disputes/")
    note = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


class DeliveryReview(models.Model):
    """Post-delivery ratings for seller + optional driver."""

    order = models.OneToOneField(
        "orders.Order",
        on_delete=models.CASCADE,
        related_name="delivery_review",
    )
    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="delivery_reviews",
    )
    seller_rating = models.PositiveSmallIntegerField()
    driver_rating = models.PositiveSmallIntegerField(null=True, blank=True)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
