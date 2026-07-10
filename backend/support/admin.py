from django.contrib import admin

from .models import (
    ContentReport,
    Dispute,
    FaqEntry,
    GroupOrder,
    GroupOrderItem,
    ReferralCode,
    ReferralRedemption,
    SavedAddress,
    Story,
    UserBlock,
)


@admin.register(FaqEntry)
class FaqEntryAdmin(admin.ModelAdmin):
    list_display = ("question", "category", "order", "is_published", "created_at")
    list_filter = ("category", "is_published")
    list_editable = ("order", "is_published")
    search_fields = ("question", "answer")


@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ("id", "order", "opened_by", "reason", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("reason", "details", "opened_by__email")
    readonly_fields = ("created_at", "updated_at")


@admin.register(UserBlock)
class UserBlockAdmin(admin.ModelAdmin):
    list_display = ("id", "blocker", "blocked", "created_at")
    search_fields = ("blocker__email", "blocked__email")


@admin.register(ContentReport)
class ContentReportAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "reporter",
        "target_type",
        "target_id",
        "reason",
        "status",
        "created_at",
    )
    list_filter = ("status", "target_type")
    search_fields = ("reason", "details", "reporter__email")


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ("id", "author", "caption", "created_at", "expires_at")
    search_fields = ("author__email", "caption")
    list_filter = ("created_at",)


@admin.register(SavedAddress)
class SavedAddressAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "label", "address", "is_default", "created_at")
    list_filter = ("is_default",)
    search_fields = ("user__email", "label", "address")


@admin.register(ReferralCode)
class ReferralCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "user", "reward_points", "created_at")
    search_fields = ("code", "user__email")


@admin.register(ReferralRedemption)
class ReferralRedemptionAdmin(admin.ModelAdmin):
    list_display = ("id", "code", "referred_user", "points_awarded", "created_at")
    search_fields = ("code__code", "referred_user__email")


class GroupOrderItemInline(admin.TabularInline):
    model = GroupOrderItem
    extra = 0


@admin.register(GroupOrder)
class GroupOrderAdmin(admin.ModelAdmin):
    list_display = ("code", "host", "seller", "status", "order", "created_at")
    list_filter = ("status",)
    search_fields = ("code", "host__email")
    inlines = [GroupOrderItemInline]
