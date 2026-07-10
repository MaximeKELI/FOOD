from django.conf import settings
from django.db import models


class Category(models.Model):
    """Meal category (Plats, Soupes, Grillades, Snacks, Boissons…)."""

    name = models.CharField(max_length=60, unique=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name_plural = "categories"
        ordering = ["order", "name"]

    def __str__(self):
        return self.name


class Meal(models.Model):
    """A meal published by a seller. Only name + image are required."""

    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="meals",
    )
    name = models.CharField(max_length=160)
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="meals",
    )
    image = models.ImageField(upload_to="meals/")

    # Optional details
    subtitle = models.CharField(max_length=200, blank=True)
    price = models.PositiveIntegerField(null=True, blank=True)
    # Discounted price (must be < price to be considered a promo).
    promo_price = models.PositiveIntegerField(null=True, blank=True)
    is_available = models.BooleanField(default=True)
    # "Plat du jour" highlight.
    is_special = models.BooleanField(default=False)
    # null = unlimited stock; 0 = out of stock
    stock_qty = models.PositiveIntegerField(null=True, blank=True)
    prep_time_minutes = models.PositiveSmallIntegerField(null=True, blank=True)
    # Dietary / filter tags: ["halal", "vegetarien", "epice", ...]
    tags = models.JSONField(default=list, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def effective_price(self):
        if self.promo_price and self.price and self.promo_price < self.price:
            return self.promo_price
        return self.price or 0

    @property
    def has_promo(self):
        return bool(
            self.promo_price and self.price and self.promo_price < self.price
        )

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["seller", "-created_at"]),
            models.Index(fields=["category", "is_available"]),
            models.Index(fields=["is_special", "is_available"]),
        ]

    def __str__(self):
        return self.name


class MealImage(models.Model):
    """Additional gallery photos for a meal."""

    meal = models.ForeignKey(
        Meal, on_delete=models.CASCADE, related_name="gallery"
    )
    image = models.ImageField(upload_to="meals/gallery/")
    order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return f"Photo {self.pk} — {self.meal.name}"


class MealFavorite(models.Model):
    """A user bookmarking a meal."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="meal_favorites",
    )
    meal = models.ForeignKey(
        Meal, on_delete=models.CASCADE, related_name="favorited_by"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = ("user", "meal")

    def __str__(self):
        return f"{self.user.email} ♥ {self.meal.name}"


class Review(models.Model):
    """A customer rating + optional comment on a meal."""

    meal = models.ForeignKey(
        Meal, on_delete=models.CASCADE, related_name="reviews"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reviews",
    )
    rating = models.PositiveSmallIntegerField()  # 1..5
    comment = models.TextField(blank=True)
    photo = models.ImageField(upload_to="reviews/", blank=True)
    seller_reply = models.TextField(blank=True)
    seller_replied_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = ("meal", "user")

    def __str__(self):
        return f"{self.rating}/5 sur {self.meal.name}"


class MealOptionGroup(models.Model):
    """Option group for a meal (e.g. Size, Extras)."""

    meal = models.ForeignKey(
        Meal, on_delete=models.CASCADE, related_name="option_groups"
    )
    name = models.CharField(max_length=80)
    required = models.BooleanField(default=False)
    min_select = models.PositiveSmallIntegerField(default=0)
    max_select = models.PositiveSmallIntegerField(default=1)
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return f"{self.name} — {self.meal.name}"


class MealOptionChoice(models.Model):
    group = models.ForeignKey(
        MealOptionGroup, on_delete=models.CASCADE, related_name="choices"
    )
    name = models.CharField(max_length=80)
    price_extra = models.PositiveIntegerField(default=0)
    is_available = models.BooleanField(default=True)
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return self.name


class MealCombo(models.Model):
    """Fixed-price combo pack sold by a seller."""

    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="combos",
    )
    name = models.CharField(max_length=160)
    description = models.CharField(max_length=255, blank=True)
    price = models.PositiveIntegerField()
    image = models.ImageField(upload_to="combos/", blank=True)
    is_available = models.BooleanField(default=True)
    meals = models.ManyToManyField(Meal, related_name="combos", blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.name


class RecentlyViewedMeal(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="recently_viewed",
    )
    meal = models.ForeignKey(
        Meal, on_delete=models.CASCADE, related_name="viewed_by"
    )
    viewed_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("user", "meal")
        ordering = ["-viewed_at"]
