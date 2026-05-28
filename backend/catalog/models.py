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
    is_available = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.name
