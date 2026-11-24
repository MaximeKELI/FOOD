from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from orders.models import Order

from .models import PaymentIntent

User = get_user_model()


class WebhookSecurityTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email="whsec@test.app", password="secret12"
        )
        self.order = Order.objects.create(
            customer=self.customer,
            payment_method=Order.Payment.WAVE,
            payment_status=Order.PaymentStatus.PROCESSING,
            total=2000,
        )
        self.intent = PaymentIntent.objects.create(
            order=self.order,
            provider=PaymentIntent.Provider.WAVE,
            amount=2000,
            external_id="wave_sess_sec",
            status=PaymentIntent.Status.PROCESSING,
        )
        self.client = APIClient()

    @override_settings(WAVE_WEBHOOK_SECRET="")
    def test_wave_rejects_when_secret_not_configured(self):
        res = self.client.post(
            "/api/payments/webhook/wave/",
            {"id": "wave_sess_sec"},
            format="json",
            HTTP_X_WAVE_SIGNATURE="anything",
        )
        self.assertEqual(res.status_code, 403)

    @override_settings(WAVE_WEBHOOK_SECRET="expected-secret")
    def test_wave_rejects_wrong_signature(self):
        res = self.client.post(
            "/api/payments/webhook/wave/",
            {"id": "wave_sess_sec"},
            format="json",
            HTTP_X_WAVE_SIGNATURE="wrong",
        )
        self.assertEqual(res.status_code, 403)

    @override_settings(STRIPE_WEBHOOK_SECRET="")
    def test_stripe_requires_webhook_secret(self):
        res = self.client.post(
            "/api/payments/webhook/stripe/",
            {},
            format="json",
        )
        self.assertEqual(res.status_code, 503)
