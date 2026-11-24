from django.urls import path

from .views import (
    DeliveryReviewCreateView,
    DisputeEvidenceCreateView,
    KycUploadView,
    LoyaltyRedeemRewardView,
    LoyaltySummaryView,
    MealBoostCreateView,
    OpenNowSellersView,
    OpsKillSwitchView,
    OpsOverviewView,
    PickupSlotBookView,
    PickupSlotListCreateView,
    PlatformSettingsView,
    RecommendationsView,
    SellerDashboardExtraView,
    SellerInvoiceListView,
    WishListAddItemView,
    WishListDetailView,
    WishListListCreateView,
)

urlpatterns = [
    path("settings/", PlatformSettingsView.as_view(), name="platform_settings"),
    path("ops/", OpsOverviewView.as_view(), name="platform_ops"),
    path("ops/flags/", OpsKillSwitchView.as_view(), name="platform_ops_flags"),
    path("invoices/", SellerInvoiceListView.as_view(), name="seller_invoices"),
    path("boosts/", MealBoostCreateView.as_view(), name="meal_boosts"),
    path("wishlists/", WishListListCreateView.as_view(), name="wishlists"),
    path("wishlists/<int:pk>/", WishListDetailView.as_view(), name="wishlist_detail"),
    path(
        "wishlists/<int:pk>/items/",
        WishListAddItemView.as_view(),
        name="wishlist_items",
    ),
    path("loyalty/", LoyaltySummaryView.as_view(), name="loyalty_summary"),
    path(
        "loyalty/redeem/",
        LoyaltyRedeemRewardView.as_view(),
        name="loyalty_redeem_reward",
    ),
    path("kyc/", KycUploadView.as_view(), name="kyc"),
    path("slots/", PickupSlotListCreateView.as_view(), name="pickup_slots"),
    path("slots/<int:pk>/book/", PickupSlotBookView.as_view(), name="pickup_slot_book"),
    path(
        "disputes/evidence/",
        DisputeEvidenceCreateView.as_view(),
        name="dispute_evidence",
    ),
    path(
        "reviews/delivery/",
        DeliveryReviewCreateView.as_view(),
        name="delivery_review",
    ),
    path("recommendations/", RecommendationsView.as_view(), name="recommendations"),
    path("open-now/", OpenNowSellersView.as_view(), name="open_now_sellers"),
    path(
        "seller/dashboard-extra/",
        SellerDashboardExtraView.as_view(),
        name="seller_dashboard_extra",
    ),
]
