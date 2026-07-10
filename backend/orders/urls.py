from django.urls import path

from .views import (
    DeliveryQuoteView,
    LoyaltyRedeemPreviewView,
    OrderCancelView,
    OrderDetailView,
    OrderListCreateView,
    OrderReorderView,
    OrderStatusUpdateView,
    OrderTimelineView,
    PromoValidateView,
    ReceivedOrderListView,
    SellerPromoDetailView,
    SellerPromoListCreateView,
    SellerStatsView,
)

urlpatterns = [
    path("orders/", OrderListCreateView.as_view(), name="orders"),
    path("orders/received/", ReceivedOrderListView.as_view(), name="orders_received"),
    path("orders/stats/", SellerStatsView.as_view(), name="orders_stats"),
    path(
        "orders/delivery-quote/",
        DeliveryQuoteView.as_view(),
        name="delivery_quote",
    ),
    path(
        "orders/promo-validate/",
        PromoValidateView.as_view(),
        name="promo_validate",
    ),
    path("orders/<int:pk>/", OrderDetailView.as_view(), name="order_detail"),
    path(
        "orders/<int:pk>/cancel/",
        OrderCancelView.as_view(),
        name="order_cancel",
    ),
    path(
        "orders/<int:pk>/status/",
        OrderStatusUpdateView.as_view(),
        name="order_status",
    ),
    path(
        "orders/<int:pk>/timeline/",
        OrderTimelineView.as_view(),
        name="order_timeline",
    ),
    path(
        "orders/<int:pk>/reorder/",
        OrderReorderView.as_view(),
        name="order_reorder",
    ),
    path("promos/", SellerPromoListCreateView.as_view(), name="promos"),
    path("promos/<int:pk>/", SellerPromoDetailView.as_view(), name="promo_detail"),
    path(
        "loyalty/redeem-preview/",
        LoyaltyRedeemPreviewView.as_view(),
        name="loyalty_redeem_preview",
    ),
]
