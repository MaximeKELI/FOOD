from django.urls import path

from .views import (
    ContentReportCreateView,
    DisputeDetailView,
    DisputeListCreateView,
    FaqListView,
    GroupOrderAddItemView,
    GroupOrderCheckoutView,
    GroupOrderCreateView,
    GroupOrderDetailView,
    GroupOrderJoinView,
    GroupOrderRemoveItemView,
    ReferralMeView,
    ReferralRedeemView,
    SavedAddressDetailView,
    SavedAddressListCreateView,
    StoryDeleteView,
    StoryFeedView,
    StoryListCreateView,
    UserBlockDeleteView,
    UserBlockListCreateView,
)

urlpatterns = [
    path("faq/", FaqListView.as_view(), name="faq"),
    path("addresses/", SavedAddressListCreateView.as_view(), name="addresses"),
    path(
        "addresses/<int:pk>/",
        SavedAddressDetailView.as_view(),
        name="address_detail",
    ),
    path("blocks/", UserBlockListCreateView.as_view(), name="blocks"),
    path(
        "blocks/<int:user_id>/",
        UserBlockDeleteView.as_view(),
        name="block_delete",
    ),
    path("reports/", ContentReportCreateView.as_view(), name="reports"),
    path("stories/", StoryListCreateView.as_view(), name="stories"),
    path("stories/feed/", StoryFeedView.as_view(), name="stories_feed"),
    path("stories/<int:pk>/", StoryDeleteView.as_view(), name="story_delete"),
    path("referral/", ReferralMeView.as_view(), name="referral_me"),
    path("referral/redeem/", ReferralRedeemView.as_view(), name="referral_redeem"),
    path("disputes/", DisputeListCreateView.as_view(), name="disputes"),
    path("disputes/<int:pk>/", DisputeDetailView.as_view(), name="dispute_detail"),
    path("group-orders/", GroupOrderCreateView.as_view(), name="group_orders"),
    path(
        "group-orders/<str:code>/",
        GroupOrderDetailView.as_view(),
        name="group_order_detail",
    ),
    path(
        "group-orders/<str:code>/join/",
        GroupOrderJoinView.as_view(),
        name="group_order_join",
    ),
    path(
        "group-orders/<str:code>/items/",
        GroupOrderAddItemView.as_view(),
        name="group_order_items",
    ),
    path(
        "group-orders/<str:code>/items/<int:item_id>/",
        GroupOrderRemoveItemView.as_view(),
        name="group_order_item_delete",
    ),
    path(
        "group-orders/<str:code>/checkout/",
        GroupOrderCheckoutView.as_view(),
        name="group_order_checkout",
    ),
]
