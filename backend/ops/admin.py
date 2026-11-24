from django.contrib import admin

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


@admin.register(PlatformSettings)
class PlatformSettingsAdmin(admin.ModelAdmin):
    list_display = (
        "payments_enabled",
        "cash_enabled",
        "digital_payments_enabled",
        "new_orders_enabled",
        "commission_percent",
        "updated_at",
    )


@admin.register(SellerInvoice)
class SellerInvoiceAdmin(admin.ModelAdmin):
    list_display = ("seller", "period_start", "period_end", "gmv", "commission", "status")
    list_filter = ("status",)


@admin.register(MealBoost)
class MealBoostAdmin(admin.ModelAdmin):
    list_display = ("meal", "seller", "score", "starts_at", "expires_at", "paid_amount")
    list_filter = ("expires_at",)


class WishListItemInline(admin.TabularInline):
    model = WishListItem
    extra = 0


@admin.register(WishList)
class WishListAdmin(admin.ModelAdmin):
    list_display = ("name", "user", "created_at")
    inlines = [WishListItemInline]


@admin.register(LoyaltyLedger)
class LoyaltyLedgerAdmin(admin.ModelAdmin):
    list_display = ("user", "kind", "points", "balance_after", "created_at")
    list_filter = ("kind",)


@admin.register(LoyaltyTier)
class LoyaltyTierAdmin(admin.ModelAdmin):
    list_display = ("name", "min_points", "perk", "order")


@admin.register(LoyaltyReward)
class LoyaltyRewardAdmin(admin.ModelAdmin):
    list_display = ("title", "points_cost", "active")


@admin.register(KycDocument)
class KycDocumentAdmin(admin.ModelAdmin):
    list_display = ("user", "subject", "status", "created_at", "reviewed_at")
    list_filter = ("status", "subject")
    actions = ["approve", "reject"]

    @admin.action(description="Approuver")
    def approve(self, request, queryset):
        from django.utils import timezone

        queryset.update(status=KycDocument.Status.APPROVED, reviewed_at=timezone.now())

    @admin.action(description="Refuser")
    def reject(self, request, queryset):
        from django.utils import timezone

        queryset.update(status=KycDocument.Status.REJECTED, reviewed_at=timezone.now())


@admin.register(PickupSlot)
class PickupSlotAdmin(admin.ModelAdmin):
    list_display = ("seller", "starts_at", "ends_at", "booked", "capacity", "is_active")


@admin.register(DisputeEvidence)
class DisputeEvidenceAdmin(admin.ModelAdmin):
    list_display = ("dispute", "uploaded_by", "created_at")


@admin.register(DeliveryReview)
class DeliveryReviewAdmin(admin.ModelAdmin):
    list_display = ("order", "customer", "seller_rating", "driver_rating", "created_at")
