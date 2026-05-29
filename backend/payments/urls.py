from django.urls import path

from .views import (
    MockPaymentCompleteView,
    OrangeWebhookView,
    PaymentInitiateView,
    PaymentStatusView,
    WaveWebhookView,
)

urlpatterns = [
    path("payments/initiate/", PaymentInitiateView.as_view(), name="payment_initiate"),
    path(
        "payments/<int:pk>/",
        PaymentStatusView.as_view(),
        name="payment_status",
    ),
    path(
        "payments/mock/complete/<int:pk>/",
        MockPaymentCompleteView.as_view(),
        name="payment_mock_complete",
    ),
    path(
        "payments/webhook/wave/",
        WaveWebhookView.as_view(),
        name="payment_webhook_wave",
    ),
    path(
        "payments/webhook/orange/",
        OrangeWebhookView.as_view(),
        name="payment_webhook_orange",
    ),
]
