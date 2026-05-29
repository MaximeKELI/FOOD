from django.urls import path

from .views import (
    OrderDetailView,
    OrderListCreateView,
    OrderStatusUpdateView,
    ReceivedOrderListView,
    SellerStatsView,
)

urlpatterns = [
    path("orders/", OrderListCreateView.as_view(), name="orders"),
    path("orders/received/", ReceivedOrderListView.as_view(), name="orders_received"),
    path("orders/stats/", SellerStatsView.as_view(), name="orders_stats"),
    path("orders/<int:pk>/", OrderDetailView.as_view(), name="order_detail"),
    path(
        "orders/<int:pk>/status/",
        OrderStatusUpdateView.as_view(),
        name="order_status",
    ),
]
