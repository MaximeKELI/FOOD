"""Wave Checkout API — https://developer.wave.com"""

import uuid

import requests
from decouple import config
from django.conf import settings

from ..models import PaymentIntent
from .base import InitiateResult, PaymentProvider, callback_base


class WaveProvider(PaymentProvider):
    API_BASE = "https://api.wave.com"

    def initiate(self, intent: PaymentIntent) -> InitiateResult:
        api_key = config("WAVE_API_KEY", default="")
        if not api_key:
            raise ValueError("WAVE_API_KEY non configuré.")

        base = callback_base()
        payload = {
            "amount": str(intent.amount),
            "currency": "XOF",
            "client_reference": f"order_{intent.order_id}_intent_{intent.pk}",
            "success_url": f"{base}/api/payments/wave/return/?intent={intent.pk}",
            "error_url": f"{base}/api/payments/wave/return/?intent={intent.pk}&error=1",
        }
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        response = requests.post(
            f"{self.API_BASE}/v1/checkout/sessions",
            json=payload,
            headers=headers,
            timeout=30,
        )
        if response.status_code >= 400:
            raise ValueError(f"Wave API error: {response.text[:200]}")

        data = response.json()
        session_id = data.get("id") or data.get("checkout_session_id") or f"wave_{uuid.uuid4().hex[:12]}"
        checkout_url = data.get("wave_launch_url") or data.get("checkout_url", "")
        return InitiateResult(
            external_id=session_id,
            checkout_url=checkout_url,
            status=PaymentIntent.Status.PROCESSING,
        )

    def verify_webhook(self, header_secret: str) -> bool:
        expected = config("WAVE_WEBHOOK_SECRET", default="")
        if not expected:
            return settings.DEBUG
        return header_secret == expected
