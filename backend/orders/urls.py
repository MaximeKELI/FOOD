from django.urls import path

from .views import (
    DeliveryQuoteView,
    OrderCancelView,
    OrderDetailView,
    OrderListCreateView,
    OrderStatusUpdateView,
    PromoValidateView,
    ReceivedOrderListView,
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
]
