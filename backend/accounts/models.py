from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    """User manager that uses email as the unique identifier."""

    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        if not email:
            raise ValueError("L'adresse email est obligatoire.")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Le superuser doit avoir is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Le superuser doit avoir is_superuser=True.")
        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    """Custom user authenticated by email instead of username."""

    username = None
    email = models.EmailField("adresse email", unique=True)
    display_name = models.CharField(max_length=120, blank=True)
    phone = models.CharField(max_length=30, blank=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    def __str__(self):
        return self.email

    @property
    def name(self):
        return self.display_name or self.email.split("@")[0]


class SellerProfile(models.Model):
    """Extended seller profile collected at registration."""

    GENDER_CHOICES = [
        ("Non précisé", "Non précisé"),
        ("Femme", "Femme"),
        ("Homme", "Homme"),
        ("Autre", "Autre"),
    ]

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="seller_profile"
    )

    # Personal
    country = models.CharField(max_length=80, blank=True)
    city = models.CharField(max_length=80, blank=True)
    neighborhood = models.CharField(max_length=120, blank=True)
    birth_year = models.CharField(max_length=4, blank=True)
    gender = models.CharField(
        max_length=20, choices=GENDER_CHOICES, default="Non précisé"
    )

    # Business
    shop_name = models.CharField(max_length=160, blank=True)
    shop_category = models.CharField(max_length=80, blank=True)
    cuisine = models.CharField(max_length=80, blank=True)
    opens_at = models.CharField(max_length=5, blank=True)
    closes_at = models.CharField(max_length=5, blank=True)
    delivery_radius_km = models.PositiveIntegerField(default=5)
    accepts_delivery = models.BooleanField(default=True)
    accepts_pickup = models.BooleanField(default=True)

    # Geo (filled later when the seller sets a location)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profil de {self.user.email}"


class Follow(models.Model):
    """A user following a seller (another user)."""

    follower = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="following"
    )
    seller = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="followers"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("follower", "seller")

    def __str__(self):
        return f"{self.follower.email} -> {self.seller.email}"
