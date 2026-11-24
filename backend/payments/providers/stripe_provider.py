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
        if not expected or not header_secret:
            return False
        import hmac

        return hmac.compare_digest(str(header_secret), str(expected))

    def confirm_paid(self, intent: PaymentIntent) -> bool:
        secret = config("STRIPE_SECRET_KEY", default="") or settings.STRIPE_SECRET_KEY
        if not secret or not intent.external_id:
            return False
        stripe.api_key = secret
        try:
            pi = stripe.PaymentIntent.retrieve(intent.external_id)
        except Exception:
            return False
        status = getattr(pi, "status", None) or (
            pi.get("status") if isinstance(pi, dict) else None
        )
        return status == "succeeded"
