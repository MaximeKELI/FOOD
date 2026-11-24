from rest_framework import serializers

from catalog.serializers import MealSerializer

from .models import (
    DeliveryReview,
    DisputeEvidence,
    KycDocument,
    LoyaltyLedger,
    LoyaltyReward,
    LoyaltyTier,
    MealBoost,
    PickupSlot,
    PlatformSettings,
    SellerInvoice,
    WishList,
    WishListItem,
)


class PlatformSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlatformSettings
        fields = (
            "payments_enabled",
            "cash_enabled",
            "digital_payments_enabled",
            "new_orders_enabled",
            "commission_percent",
            "commission_flat",
            "updated_at",
        )


class SellerInvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SellerInvoice
        fields = (
            "id",
            "period_start",
            "period_end",
            "gmv",
            "commission",
            "status",
            "created_at",
        )


class MealBoostSerializer(serializers.ModelSerializer):
    meal_name = serializers.CharField(source="meal.name", read_only=True)

    class Meta:
        model = MealBoost
        fields = (
            "id",
            "meal",
            "meal_name",
            "starts_at",
            "expires_at",
            "score",
            "paid_amount",
            "created_at",
        )
        read_only_fields = ("score", "created_at")


class WishListItemSerializer(serializers.ModelSerializer):
    meal_detail = MealSerializer(source="meal", read_only=True)

    class Meta:
        model = WishListItem
        fields = ("id", "meal", "meal_detail", "created_at")
        read_only_fields = ("created_at",)


class WishListSerializer(serializers.ModelSerializer):
    items = WishListItemSerializer(many=True, read_only=True)
    items_count = serializers.IntegerField(source="items.count", read_only=True)

    class Meta:
        model = WishList
        fields = ("id", "name", "items", "items_count", "created_at")
        read_only_fields = ("created_at",)


class LoyaltyLedgerSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoyaltyLedger
        fields = (
            "id",
            "kind",
            "points",
            "balance_after",
            "note",
            "related_order",
            "created_at",
        )


class LoyaltyTierSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoyaltyTier
        fields = ("id", "name", "min_points", "perk", "order")


class LoyaltyRewardSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoyaltyReward
        fields = ("id", "title", "description", "points_cost", "active")


class KycDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = KycDocument
        fields = (
            "id",
            "subject",
            "document",
            "id_number",
            "status",
            "review_note",
            "created_at",
            "reviewed_at",
        )
        read_only_fields = ("status", "review_note", "created_at", "reviewed_at")


class PickupSlotSerializer(serializers.ModelSerializer):
    remaining = serializers.IntegerField(read_only=True)

    class Meta:
        model = PickupSlot
        fields = (
            "id",
            "seller",
            "starts_at",
            "ends_at",
            "capacity",
            "booked",
            "remaining",
            "is_active",
        )
        read_only_fields = ("seller", "booked")


class DisputeEvidenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = DisputeEvidence
        fields = ("id", "dispute", "file", "note", "created_at")
        read_only_fields = ("created_at",)


class DeliveryReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryReview
        fields = (
            "id",
            "order",
            "seller_rating",
            "driver_rating",
            "comment",
            "created_at",
        )
        read_only_fields = ("created_at",)
