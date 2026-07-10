from django.db.models import Avg
from rest_framework import serializers

from food_api.validators import validate_image_upload

from .models import (
    Category,
    Meal,
    MealCombo,
    MealImage,
    MealOptionChoice,
    MealOptionGroup,
    Review,
)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "order")


class MealOptionChoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = MealOptionChoice
        fields = ("id", "name", "price_extra", "is_available", "order")


class MealOptionGroupSerializer(serializers.ModelSerializer):
    choices = MealOptionChoiceSerializer(many=True, read_only=True)

    class Meta:
        model = MealOptionGroup
        fields = (
            "id",
            "name",
            "required",
            "min_select",
            "max_select",
            "order",
            "choices",
        )


class MealOptionGroupWriteSerializer(serializers.ModelSerializer):
    choices = MealOptionChoiceSerializer(many=True, required=False)

    class Meta:
        model = MealOptionGroup
        fields = (
            "id",
            "name",
            "required",
            "min_select",
            "max_select",
            "order",
            "choices",
        )

    def create(self, validated_data):
        choices_data = validated_data.pop("choices", [])
        meal = self.context["meal"]
        group = MealOptionGroup.objects.create(meal=meal, **validated_data)
        for choice in choices_data:
            MealOptionChoice.objects.create(group=group, **choice)
        return group

    def update(self, instance, validated_data):
        choices_data = validated_data.pop("choices", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if choices_data is not None:
            instance.choices.all().delete()
            for choice in choices_data:
                MealOptionChoice.objects.create(group=instance, **choice)
        return instance


class MealComboSerializer(serializers.ModelSerializer):
    meal_ids = serializers.PrimaryKeyRelatedField(
        source="meals",
        many=True,
        queryset=Meal.objects.all(),
        required=False,
    )

    class Meta:
        model = MealCombo
        fields = (
            "id",
            "name",
            "description",
            "price",
            "image",
            "is_available",
            "meal_ids",
            "seller",
            "created_at",
        )
        read_only_fields = ("seller", "created_at")

    def create(self, validated_data):
        meals = validated_data.pop("meals", [])
        validated_data["seller"] = self.context["request"].user
        combo = MealCombo.objects.create(**validated_data)
        if meals:
            combo.meals.set(meals)
        return combo


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
    option_groups = MealOptionGroupSerializer(many=True, read_only=True)

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
            "stock_qty",
            "prep_time_minutes",
            "tags",
            "option_groups",
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
        fields = (
            "id",
            "rating",
            "comment",
            "photo",
            "seller_reply",
            "seller_replied_at",
            "user_name",
            "created_at",
        )
        read_only_fields = (
            "user_name",
            "created_at",
            "seller_reply",
            "seller_replied_at",
        )

    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError("La note doit être entre 1 et 5.")
        return value

    def validate_comment(self, value):
        text = (value or "").strip()
        if len(text) > 2000:
            raise serializers.ValidationError("Commentaire trop long (max 2000).")
        return text


class ReviewReplySerializer(serializers.Serializer):
    reply = serializers.CharField(max_length=2000)


class MealCreateSerializer(serializers.ModelSerializer):
    is_available = serializers.BooleanField(required=False, default=True)
    is_special = serializers.BooleanField(required=False, default=False)
    tags = serializers.JSONField(required=False)

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
            "stock_qty",
            "prep_time_minutes",
            "tags",
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
