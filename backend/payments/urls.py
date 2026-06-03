from django.urls import path

from .views import (
    OrangeReturnView,
    OrangeWebhookView,
    PaymentInitiateView,
    PaymentStatusView,
    StripeCreateView,
    StripeWebhookView,
    WaveReturnView,
    WaveWebhookView,
)

urlpatterns = [
    path("payments/initiate/", PaymentInitiateView.as_view(), name="payment_initiate"),
    path(
        "payments/stripe/create/",
        StripeCreateView.as_view(),
        name="payment_stripe_create",
    ),
    path(
        "payments/<int:pk>/",
        PaymentStatusView.as_view(),
        name="payment_status",
    ),
    path(
        "payments/webhook/stripe/",
        StripeWebhookView.as_view(),
        name="payment_webhook_stripe",
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
    path(
        "payments/wave/return/",
        WaveReturnView.as_view(),
        name="payment_wave_return",
    ),
    path(
        "payments/orange/return/",
        OrangeReturnView.as_view(),
        name="payment_orange_return",
    ),
]
