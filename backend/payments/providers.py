"""Payment provider adapters. Wire real Wave/Orange APIs when credentials are set."""

import uuid
from dataclasses import dataclass

from decouple import config

from .models import PaymentIntent


@dataclass
class InitiateResult:
    external_id: str
    checkout_url: str
    status: str


def _callback_base():
    return config("PAYMENT_CALLBACK_BASE_URL", default="http://127.0.0.1:8000").rstrip(
        "/"
    )


def initiate_payment(intent: PaymentIntent) -> InitiateResult:
    provider = intent.provider
    if provider == PaymentIntent.Provider.MOCK:
        ext = f"mock_{intent.pk}_{uuid.uuid4().hex[:8]}"
        url = f"{_callback_base()}/api/payments/mock/complete/{intent.pk}/"
        return InitiateResult(ext, url, PaymentIntent.Status.PROCESSING)

    if provider == PaymentIntent.Provider.WAVE:
        api_key = config("WAVE_API_KEY", default="")
        if not api_key:
            return initiate_payment(_as_mock(intent))
        # TODO: call Wave API when WAVE_API_KEY is configured.
        ext = f"wave_{intent.pk}_{uuid.uuid4().hex[:8]}"
        url = f"{_callback_base()}/api/payments/mock/complete/{intent.pk}/"
        return InitiateResult(ext, url, PaymentIntent.Status.PROCESSING)

    if provider == PaymentIntent.Provider.ORANGE_MONEY:
        merchant_key = config("ORANGE_MONEY_MERCHANT_KEY", default="")
        if not merchant_key:
            return initiate_payment(_as_mock(intent))
        ext = f"om_{intent.pk}_{uuid.uuid4().hex[:8]}"
        url = f"{_callback_base()}/api/payments/mock/complete/{intent.pk}/"
        return InitiateResult(ext, url, PaymentIntent.Status.PROCESSING)

    raise ValueError(f"Provider inconnu: {provider}")


def _as_mock(intent: PaymentIntent) -> PaymentIntent:
    intent.provider = PaymentIntent.Provider.MOCK
    intent.save(update_fields=["provider"])
    return intent


def verify_webhook_secret(provider: str, header_secret: str) -> bool:
    from django.conf import settings

    if provider == "wave":
        expected = config("WAVE_WEBHOOK_SECRET", default="")
    elif provider == "orange_money":
        expected = config("ORANGE_MONEY_WEBHOOK_SECRET", default="")
    else:
        expected = config("PAYMENT_WEBHOOK_SECRET", default="")
    if not expected:
        return settings.DEBUG
    return header_secret == expected
