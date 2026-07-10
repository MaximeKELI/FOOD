from rest_framework import serializers

from .models import (
    ContentReport,
    Dispute,
    FaqEntry,
    GroupOrder,
    GroupOrderItem,
    ReferralCode,
    SavedAddress,
    Story,
    UserBlock,
)


class FaqEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = FaqEntry
        fields = ("id", "question", "answer", "category", "order")


class SavedAddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedAddress
        fields = (
            "id",
            "label",
            "address",
            "phone",
            "latitude",
            "longitude",
            "is_default",
            "created_at",
        )
        read_only_fields = ("created_at",)

    def create(self, validated_data):
        user = self.context["request"].user
        if validated_data.get("is_default"):
            SavedAddress.objects.filter(user=user, is_default=True).update(
                is_default=False
            )
        return SavedAddress.objects.create(user=user, **validated_data)

    def update(self, instance, validated_data):
        if validated_data.get("is_default"):
            SavedAddress.objects.filter(user=instance.user, is_default=True).exclude(
                pk=instance.pk
            ).update(is_default=False)
        return super().update(instance, validated_data)


class UserBlockSerializer(serializers.ModelSerializer):
    blocked_name = serializers.CharField(source="blocked.name", read_only=True)

    class Meta:
        model = UserBlock
        fields = ("id", "blocked", "blocked_name", "created_at")
        read_only_fields = ("created_at",)


class ContentReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContentReport
        fields = (
            "id",
            "target_type",
            "target_id",
            "reason",
            "details",
            "status",
            "created_at",
        )
        read_only_fields = ("status", "created_at")


class StorySerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name", read_only=True)

    class Meta:
        model = Story
        fields = (
            "id",
            "author",
            "author_name",
            "media",
            "caption",
            "created_at",
            "expires_at",
        )
        read_only_fields = ("author", "created_at", "expires_at")


class StoryCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Story
        fields = ("id", "media", "caption")


class ReferralCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReferralCode
        fields = ("code", "reward_points", "created_at")
        read_only_fields = fields


class DisputeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispute
        fields = (
            "id",
            "order",
            "opened_by",
            "reason",
            "details",
            "status",
            "resolution_note",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "opened_by",
            "status",
            "resolution_note",
            "created_at",
            "updated_at",
        )


class DisputeCreateSerializer(serializers.Serializer):
    order = serializers.IntegerField()
    reason = serializers.CharField(max_length=120)
    details = serializers.CharField(required=False, allow_blank=True, default="")


class GroupOrderItemSerializer(serializers.ModelSerializer):
    meal_name = serializers.CharField(source="meal.name", read_only=True)
    user_name = serializers.CharField(source="user.name", read_only=True)

    class Meta:
        model = GroupOrderItem
        fields = (
            "id",
            "user",
            "user_name",
            "meal",
            "meal_name",
            "quantity",
            "note",
            "created_at",
        )
        read_only_fields = ("user", "created_at")


class GroupOrderSerializer(serializers.ModelSerializer):
    items = GroupOrderItemSerializer(many=True, read_only=True)
    host_name = serializers.CharField(source="host.name", read_only=True)

    class Meta:
        model = GroupOrder
        fields = (
            "id",
            "code",
            "host",
            "host_name",
            "seller",
            "status",
            "order",
            "items",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "code",
            "host",
            "status",
            "order",
            "created_at",
            "updated_at",
        )


class GroupOrderItemInputSerializer(serializers.Serializer):
    meal = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, max_value=50, default=1)
    note = serializers.CharField(required=False, allow_blank=True, default="")
