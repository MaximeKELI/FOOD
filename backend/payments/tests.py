from unittest.mock import MagicMock, patch

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from accounts.models import SellerProfile
from catalog.models import Category, Meal
from orders.models import Order

from .models import PaymentIntent
from .services import mark_intent_paid

User = get_user_model()


class PaymentFlowTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email="pay@test.app", password="secret12", display_name="Pay"
        )
        self.seller = User.objects.create_user(
            email="seller2@test.app", password="secret12", display_name="Seller"
        )
        SellerProfile.objects.create(user=self.seller, shop_name="Shop")
        cat = Category.objects.create(name="Plats")
        image = SimpleUploadedFile("m.jpg", b"x", content_type="image/jpeg")
        self.meal = Meal.objects.create(
            seller=self.seller,
            category=cat,
            name="Test",
            price=3000,
            image=image,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.customer)

    @override_settings(DEBUG=True)
    @patch("payments.providers.wave.requests.post")
    def test_initiate_wave_payment(self, mock_post):
        mock_post.return_value = MagicMock(
            status_code=200,
            json=lambda: {
                "id": "wave_sess_1",
                "wave_launch_url": "https://pay.wave.com/session/1",
            },
        )
        with self.settings(WAVE_API_KEY="test-key"):
            order = Order.objects.create(
                customer=self.customer,
                payment_method=Order.Payment.WAVE,
                payment_status=Order.PaymentStatus.PENDING,
                subtotal=3000,
                total=3000,
            )
            order.items.create(
                meal=self.meal, meal_name="Test", unit_price=3000, quantity=1
            )
            res = self.client.post(
                "/api/payments/initiate/", {"order_id": order.id}, format="json"
            )
        self.assertEqual(res.status_code, 200)
        self.assertIn("checkout_url", res.data)
        order.refresh_from_db()
        self.assertEqual(order.payment_status, Order.PaymentStatus.PROCESSING)

    def test_initiate_rejects_cash_order(self):
        order = Order.objects.create(
            customer=self.customer,
            payment_method=Order.Payment.CASH,
            subtotal=1000,
            total=1000,
        )
        res = self.client.post(
            "/api/payments/initiate/", {"order_id": order.id}, format="json"
        )
        self.assertEqual(res.status_code, 400)

    @patch("payments.providers.stripe_provider.stripe.PaymentIntent.create")
    def test_stripe_create_returns_client_secret(self, mock_stripe):
        mock_stripe.return_value = MagicMock(
            id="pi_test", client_secret="cs_test_secret"
        )
        with self.settings(
            STRIPE_SECRET_KEY="sk_test_x",
            STRIPE_PUBLISHABLE_KEY="pk_test_x",
        ):
            order = Order.objects.create(
                customer=self.customer,
                payment_method=Order.Payment.CASH,
                subtotal=5000,
                total=5000,
            )
            res = self.client.post(
                "/api/payments/stripe/create/",
                {"order_id": order.id},
                format="json",
            )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["client_secret"], "cs_test_secret")
        order.refresh_from_db()
        self.assertEqual(order.payment_method, Order.Payment.STRIPE)

    def test_mark_intent_paid_idempotent(self):
        order = Order.objects.create(
            customer=self.customer,
            payment_method=Order.Payment.WAVE,
            payment_status=Order.PaymentStatus.PROCESSING,
            total=1000,
        )
        intent = PaymentIntent.objects.create(
            order=order,
            provider=PaymentIntent.Provider.WAVE,
            amount=1000,
            status=PaymentIntent.Status.PROCESSING,
        )
        self.assertTrue(mark_intent_paid(intent))
        self.assertFalse(mark_intent_paid(intent))
        order.refresh_from_db()
        self.assertEqual(order.payment_status, Order.PaymentStatus.PAID)


class PaymentReturnTests(TestCase):
    def test_wave_return_deep_link(self):
        client = APIClient()
        res = client.get("/api/payments/wave/return/?intent=42")
        self.assertEqual(res.status_code, 200)
        self.assertIn(b"food://payment?intent=42", res.content)

    def test_orange_return_cancel_flag(self):
        client = APIClient()
        res = client.get("/api/payments/orange/return/?intent=7&cancel=1")
        self.assertEqual(res.status_code, 200)
        self.assertIn(b"error=1", res.content)


class WaveWebhookTests(TestCase):
    @override_settings(DEBUG=True)
    def test_wave_webhook_marks_paid(self):
        customer = User.objects.create_user(email="wh@test.app", password="secret12")
        order = Order.objects.create(
            customer=customer,
            payment_method=Order.Payment.WAVE,
            payment_status=Order.PaymentStatus.PROCESSING,
            total=2000,
        )
        intent = PaymentIntent.objects.create(
            order=order,
            provider=PaymentIntent.Provider.WAVE,
            amount=2000,
            external_id="wave_sess_99",
            status=PaymentIntent.Status.PROCESSING,
        )
        client = APIClient()
        with self.settings(WAVE_WEBHOOK_SECRET="dev-webhook-secret"):
            res = client.post(
                "/api/payments/webhook/wave/",
                {"id": "wave_sess_99"},
                format="json",
                HTTP_X_WAVE_SIGNATURE="dev-webhook-secret",
            )
        self.assertEqual(res.status_code, 200)
        intent.refresh_from_db()
        self.assertEqual(intent.status, PaymentIntent.Status.PAID)


class OpenAPITests(TestCase):
    def test_schema_endpoint(self):
        client = APIClient()
        res = client.get("/api/schema/")
        self.assertEqual(res.status_code, 200)
        self.assertIn(b"openapi", res.content)

    def test_redoc_endpoint(self):
        client = APIClient()
        res = client.get("/api/redoc/")
        self.assertEqual(res.status_code, 200)
