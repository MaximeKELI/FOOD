from django.db.models import Avg, Count, Exists, OuterRef, Q
from rest_framework import serializers

from food_api.validators import validate_image_upload

from .models import Category, Meal, MealFavorite, MealImage, Review


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "order")


class MealSerializer(serializers.ModelSerializer):
    seller_name = serializers.CharField(source="seller.name", read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)
    image = serializers.ImageField(read_only=True)
    rating = serializers.SerializerMethodField()
    reviews_count = serializers.SerializerMethodField()
    favorited_by_me = serializers.SerializerMethodField()
    effective_price = serializers.IntegerField(read_only=True)
    has_promo = serializers.BooleanField(read_only=True)
    seller_lat = serializers.SerializerMethodField()
    seller_lng = serializers.SerializerMethodField()
    gallery = serializers.SerializerMethodField()

    class Meta:
        model = Meal
        fields = (
            "id",
            "name",
            "image",
            "gallery",
            "subtitle",
            "price",
            "promo_price",
            "effective_price",
            "has_promo",
            "is_available",
            "is_special",
            "category",
            "category_name",
            "seller",
            "seller_name",
            "seller_lat",
            "seller_lng",
            "rating",
            "reviews_count",
            "favorited_by_me",
            "created_at",
        )
        read_only_fields = ("seller",)

    def get_rating(self, obj):
        if hasattr(obj, "rating_avg") and obj.rating_avg is not None:
            return round(float(obj.rating_avg), 1)
        avg = obj.reviews.aggregate(v=Avg("rating"))["v"]
        return round(avg, 1) if avg is not None else 0

    def get_reviews_count(self, obj):
        if hasattr(obj, "reviews_count_annotated"):
            return obj.reviews_count_annotated
        return obj.reviews.count()

    def get_favorited_by_me(self, obj):
        if hasattr(obj, "favorited_by_me_annotated"):
            return obj.favorited_by_me_annotated
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        return obj.favorited_by.filter(user=user).exists()

    def _profile(self, obj):
        return getattr(obj.seller, "seller_profile", None)

    def get_seller_lat(self, obj):
        p = self._profile(obj)
        return p.latitude if p else None

    def get_seller_lng(self, obj):
        p = self._profile(obj)
        return p.longitude if p else None

    def get_gallery(self, obj):
        request = self.context.get("request")
        urls = []
        for img in obj.gallery.all():
            url = img.image.url
            if request is not None and url.startswith("/"):
                url = request.build_absolute_uri(url)
            urls.append(url)
        return urls


class ReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.name", read_only=True)

    class Meta:
        model = Review
        fields = ("id", "rating", "comment", "user_name", "created_at")
        read_only_fields = ("user_name", "created_at")

    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError("La note doit être entre 1 et 5.")
        return value

    def validate_comment(self, value):
        text = (value or "").strip()
        if len(text) > 2000:
            raise serializers.ValidationError("Commentaire trop long (max 2000).")
        return text


class MealCreateSerializer(serializers.ModelSerializer):
    is_available = serializers.BooleanField(required=False, default=True)
    is_special = serializers.BooleanField(required=False, default=False)

    class Meta:
        model = Meal
        fields = (
            "id",
            "name",
            "image",
            "subtitle",
            "price",
            "promo_price",
            "is_available",
            "is_special",
            "category",
        )

    def validate(self, attrs):
        validate_image_upload(attrs.get("image"))
        price = attrs.get("price")
        if price is None:
            raise serializers.ValidationError({"price": "Le prix est obligatoire."})
        promo = attrs.get("promo_price")
        if promo is not None and price is not None and promo >= price:
            raise serializers.ValidationError(
                {"promo_price": "Le prix promo doit être inférieur au prix normal."}
            )
        return attrs

    def create(self, validated_data):
        validated_data["seller"] = self.context["request"].user
        meal = super().create(validated_data)
        gallery_files = self.context["request"].FILES.getlist("gallery")
        for i, file in enumerate(gallery_files[:5]):
            validate_image_upload(file)
            MealImage.objects.create(meal=meal, image=file, order=i)
        return meal
