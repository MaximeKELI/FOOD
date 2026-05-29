from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import SellerProfile
from catalog.models import Category, Meal
from orders.models import Order

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

    def test_initiate_wave_payment(self):
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

    def test_mock_complete_marks_paid(self):
        order = Order.objects.create(
            customer=self.customer,
            payment_method=Order.Payment.WAVE,
            payment_status=Order.PaymentStatus.PROCESSING,
            subtotal=3000,
            total=3000,
        )
        from payments.models import PaymentIntent

        intent = PaymentIntent.objects.create(
            order=order,
            provider=PaymentIntent.Provider.MOCK,
            amount=3000,
            status=PaymentIntent.Status.PROCESSING,
        )
        res = self.client.get(f"/api/payments/mock/complete/{intent.id}/")
        self.assertEqual(res.status_code, 200)
        order.refresh_from_db()
        self.assertEqual(order.payment_status, Order.PaymentStatus.PAID)
