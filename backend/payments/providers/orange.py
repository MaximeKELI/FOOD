"""Orange Money WebPay / merchant API."""

import uuid

import requests
from decouple import config
from django.conf import settings

from ..models import PaymentIntent
from .base import InitiateResult, PaymentProvider, callback_base


class OrangeMoneyProvider(PaymentProvider):
    """Uses Orange Money merchant API when ORANGE_MONEY_* env vars are set."""

    def initiate(self, intent: PaymentIntent) -> InitiateResult:
        merchant_key = config("ORANGE_MONEY_MERCHANT_KEY", default="")
        api_url = config(
            "ORANGE_MONEY_API_URL",
            default="https://api.orange.com/orange-money-webpay/dev/v1",
        )
        if not merchant_key:
            raise ValueError("ORANGE_MONEY_MERCHANT_KEY non configuré.")

        base = callback_base()
        order_id = f"FOOD-{intent.order_id}-{intent.pk}"
        payload = {
            "merchant_key": merchant_key,
            "currency": "OUV",
            "order_id": order_id,
            "amount": intent.amount,
            "return_url": f"{base}/api/payments/orange/return/?intent={intent.pk}",
            "cancel_url": f"{base}/api/payments/orange/return/?intent={intent.pk}&cancel=1",
            "notif_url": f"{base}/api/payments/webhook/orange/",
            "lang": "fr",
        }
        auth_user = config("ORANGE_MONEY_CLIENT_ID", default="")
        auth_pass = config("ORANGE_MONEY_CLIENT_SECRET", default="")
        response = requests.post(
            f"{api_url.rstrip('/')}/webpayment",
            json=payload,
            auth=(auth_user, auth_pass) if auth_user else None,
            headers={"Content-Type": "application/json"},
            timeout=30,
        )
        if response.status_code >= 400:
            raise ValueError(f"Orange Money API error: {response.text[:200]}")

        data = response.json()
        pay_token = data.get("pay_token") or data.get("payment_token") or f"om_{uuid.uuid4().hex[:12]}"
        payment_url = data.get("payment_url") or data.get("redirect_url", "")
        return InitiateResult(
            external_id=pay_token,
            checkout_url=payment_url,
            status=PaymentIntent.Status.PROCESSING,
        )

    def verify_webhook(self, header_secret: str) -> bool:
        expected = config("ORANGE_MONEY_WEBHOOK_SECRET", default="")
        if not expected:
            return settings.DEBUG
        return header_secret == expected
