import stripe
from django.conf import settings
from decouple import config

from ..models import PaymentIntent
from .base import InitiateResult, PaymentProvider, callback_base


class StripeProvider(PaymentProvider):
    def initiate(self, intent: PaymentIntent) -> InitiateResult:
        secret = config("STRIPE_SECRET_KEY", default="") or settings.STRIPE_SECRET_KEY
        if not secret:
            raise ValueError("STRIPE_SECRET_KEY non configuré.")
        stripe.api_key = secret
        order = intent.order
        pi = stripe.PaymentIntent.create(
            amount=intent.amount,
            currency="xof",
            metadata={"order_id": str(order.id), "payment_intent_id": str(intent.pk)},
            automatic_payment_methods={"enabled": True},
        )
        return InitiateResult(
            external_id=pi.id,
            checkout_url="",
            status=PaymentIntent.Status.PROCESSING,
            client_secret=pi.client_secret or "",
            publishable_key=config("STRIPE_PUBLISHABLE_KEY", default="")
            or settings.STRIPE_PUBLISHABLE_KEY,
        )

    def verify_webhook(self, header_secret: str) -> bool:
        expected = config("STRIPE_WEBHOOK_SECRET", default="") or settings.STRIPE_WEBHOOK_SECRET
        if not expected:
            from django.conf import settings as dj_settings

            return dj_settings.DEBUG
        return header_secret == expected
