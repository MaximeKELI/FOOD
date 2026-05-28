from rest_framework import serializers

from .models import Category, Meal


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "order")


class MealSerializer(serializers.ModelSerializer):
    seller_name = serializers.CharField(source="seller.name", read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)
    image = serializers.ImageField(read_only=True)

    class Meta:
        model = Meal
        fields = (
            "id",
            "name",
            "image",
            "subtitle",
            "price",
            "is_available",
            "category",
            "category_name",
            "seller",
            "seller_name",
            "created_at",
        )
        read_only_fields = ("seller",)


class MealCreateSerializer(serializers.ModelSerializer):
    is_available = serializers.BooleanField(required=False, default=True)

    class Meta:
        model = Meal
        fields = (
            "id",
            "name",
            "image",
            "subtitle",
            "price",
            "is_available",
            "category",
        )

    def create(self, validated_data):
        validated_data["seller"] = self.context["request"].user
        return super().create(validated_data)
