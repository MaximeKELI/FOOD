from django.conf import settings
from django.db import models


class FaqEntry(models.Model):
    """In-app help content managed from Django admin."""

    question = models.CharField(max_length=255)
    answer = models.TextField()
    category = models.CharField(max_length=80, blank=True, default="Général")
    order = models.PositiveIntegerField(default=0)
    is_published = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order", "id"]
        verbose_name_plural = "FAQ entries"

    def __str__(self):
        return self.question


class Dispute(models.Model):
    """Simple order dispute / support ticket (manual resolution)."""

    class Status(models.TextChoices):
        OPEN = "open", "Ouvert"
        IN_REVIEW = "in_review", "En cours"
        RESOLVED = "resolved", "Résolu"
        CLOSED = "closed", "Fermé"

    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.CASCADE,
        related_name="disputes",
    )
    opened_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="disputes_opened",
    )
    reason = models.CharField(max_length=120)
    details = models.TextField(blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.OPEN
    )
    resolution_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Litige #{self.id} commande #{self.order_id}"


class UserBlock(models.Model):
    """Block another user (hides their social content / prevents chat start)."""

    blocker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="blocks_out",
    )
    blocked = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="blocks_in",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("blocker", "blocked")
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.blocker_id} blocked {self.blocked_id}"


class ContentReport(models.Model):
    """Report a post, comment, or user for moderation."""

    class TargetType(models.TextChoices):
        POST = "post", "Publication"
        COMMENT = "comment", "Commentaire"
        USER = "user", "Utilisateur"

    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        REVIEWED = "reviewed", "Traité"
        DISMISSED = "dismissed", "Rejeté"

    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reports_filed",
    )
    target_type = models.CharField(max_length=20, choices=TargetType.choices)
    target_id = models.PositiveIntegerField()
    reason = models.CharField(max_length=120)
    details = models.TextField(blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["target_type", "target_id"]),
        ]

    def __str__(self):
        return f"Report {self.target_type}:{self.target_id}"


class Story(models.Model):
    """24h ephemeral story for sellers."""

    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="stories",
    )
    media = models.FileField(upload_to="stories/")
    caption = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["author", "-created_at"]),
            models.Index(fields=["expires_at"]),
        ]

    def __str__(self):
        return f"Story de {self.author_id}"


class SavedAddress(models.Model):
    """Customer saved delivery addresses."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="saved_addresses",
    )
    label = models.CharField(max_length=60, default="Maison")
    address = models.CharField(max_length=255)
    phone = models.CharField(max_length=30, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_default", "-created_at"]

    def __str__(self):
        return f"{self.label} — {self.user_id}"


class ReferralCode(models.Model):
    """One referral code per user."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="referral",
    )
    code = models.CharField(max_length=20, unique=True)
    reward_points = models.PositiveIntegerField(default=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.code


class ReferralRedemption(models.Model):
    """Tracks who used whose referral code (once per user)."""

    code = models.ForeignKey(
        ReferralCode, on_delete=models.CASCADE, related_name="redemptions"
    )
    referred_user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="referral_used",
    )
    points_awarded = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.referred_user_id} used {self.code.code}"


class GroupOrder(models.Model):
    """Shared cart session — members add items, host places the order."""

    class Status(models.TextChoices):
        OPEN = "open", "Ouvert"
        LOCKED = "locked", "Verrouillé"
        ORDERED = "ordered", "Commandé"
        CANCELLED = "cancelled", "Annulé"

    host = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="group_orders_hosted",
    )
    code = models.CharField(max_length=12, unique=True)
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="group_orders_as_seller",
        null=True,
        blank=True,
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.OPEN
    )
    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="group_source",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Groupe {self.code}"


class GroupOrderItem(models.Model):
    group = models.ForeignKey(
        GroupOrder, on_delete=models.CASCADE, related_name="items"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="group_order_items",
    )
    meal = models.ForeignKey(
        "catalog.Meal", on_delete=models.CASCADE, related_name="group_order_items"
    )
    quantity = models.PositiveIntegerField(default=1)
    note = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("group", "user", "meal")

    def __str__(self):
        return f"{self.quantity}x meal {self.meal_id} in {self.group.code}"
