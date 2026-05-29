from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import SellerProfile

User = get_user_model()


class SellerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = SellerProfile
        exclude = ("id", "user")
        read_only_fields = ("is_verified", "created_at", "updated_at")

    def validate(self, attrs):
        lat = attrs.get("latitude", getattr(self.instance, "latitude", None))
        lng = attrs.get("longitude", getattr(self.instance, "longitude", None))
        if lat is not None and not (-90 <= lat <= 90):
            raise serializers.ValidationError(
                {"latitude": "Latitude invalide (-90 à 90)."}
            )
        if lng is not None and not (-180 <= lng <= 180):
            raise serializers.ValidationError(
                {"longitude": "Longitude invalide (-180 à 180)."}
            )
        return attrs


class SellerLocationSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source="user.id", read_only=True)
    name = serializers.CharField(source="user.name", read_only=True)

    class Meta:
        model = SellerProfile
        fields = (
            "id",
            "name",
            "shop_name",
            "cuisine",
            "city",
            "latitude",
            "longitude",
        )


class UserSerializer(serializers.ModelSerializer):
    seller_profile = SellerProfileSerializer(read_only=True)
    name = serializers.CharField(read_only=True)
    followers_count = serializers.SerializerMethodField()
    meals_count = serializers.SerializerMethodField()
    followed_by_me = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "display_name",
            "name",
            "phone",
            "loyalty_points",
            "seller_profile",
            "followers_count",
            "meals_count",
            "followed_by_me",
        )
        read_only_fields = ("email", "loyalty_points")

    def get_followers_count(self, obj):
        return obj.followers.count()

    def get_meals_count(self, obj):
        return obj.meals.count()

    def get_followed_by_me(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        return obj.followers.filter(follower=user).exists()


class PublicSellerSerializer(serializers.ModelSerializer):
    """Public seller profile — no email, phone, or loyalty data."""

    seller_profile = SellerProfileSerializer(read_only=True)
    name = serializers.CharField(read_only=True)
    followers_count = serializers.SerializerMethodField()
    meals_count = serializers.SerializerMethodField()
    followed_by_me = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "display_name",
            "name",
            "seller_profile",
            "followers_count",
            "meals_count",
            "followed_by_me",
        )

    def get_followers_count(self, obj):
        if hasattr(obj, "followers_count_annotated"):
            return obj.followers_count_annotated
        return obj.followers.count()

    def get_meals_count(self, obj):
        if hasattr(obj, "meals_count_annotated"):
            return obj.meals_count_annotated
        return obj.meals.count()

    def get_followed_by_me(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        if hasattr(obj, "followed_by_me_annotated"):
            return obj.followed_by_me_annotated
        return obj.followers.filter(follower=user).exists()


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("display_name", "phone")


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)
    name = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)

    # Optional seller-profile fields
    country = serializers.CharField(required=False, allow_blank=True)
    city = serializers.CharField(required=False, allow_blank=True)
    neighborhood = serializers.CharField(required=False, allow_blank=True)
    birth_year = serializers.CharField(required=False, allow_blank=True)
    gender = serializers.CharField(required=False, allow_blank=True)
    shop_name = serializers.CharField(required=False, allow_blank=True)
    shop_category = serializers.CharField(required=False, allow_blank=True)
    cuisine = serializers.CharField(required=False, allow_blank=True)
    opens_at = serializers.CharField(required=False, allow_blank=True)
    closes_at = serializers.CharField(required=False, allow_blank=True)
    delivery_radius_km = serializers.IntegerField(required=False, default=5)
    accepts_delivery = serializers.BooleanField(required=False, default=True)
    accepts_pickup = serializers.BooleanField(required=False, default=True)

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Cet email est déjà utilisé.")
        return value.lower()

    def create(self, validated_data):
        password = validated_data.pop("password")
        name = validated_data.pop("name", "")
        phone = validated_data.pop("phone", "")

        user = User.objects.create_user(
            email=validated_data.pop("email"),
            password=password,
            display_name=name,
            phone=phone,
        )

        SellerProfile.objects.create(
            user=user,
            gender=validated_data.pop("gender", "") or "Non précisé",
            **{
                k: v
                for k, v in validated_data.items()
                if k
                in {
                    "country",
                    "city",
                    "neighborhood",
                    "birth_year",
                    "shop_name",
                    "shop_category",
                    "cuisine",
                    "opens_at",
                    "closes_at",
                    "delivery_radius_km",
                    "accepts_delivery",
                    "accepts_pickup",
                }
            },
        )
        return user
