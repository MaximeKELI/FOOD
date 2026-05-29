from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import SellerProfile
from catalog.models import Category, Meal
from orders.models import Order, PromoCode

User = get_user_model()


class AccountsSecurityTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="buyer@test.app", password="secret12", display_name="Buyer"
        )
        SellerProfile.objects.create(user=self.user)
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_cannot_patch_loyalty_points(self):
        res = self.client.patch(
            "/api/auth/me/", {"loyalty_points": 9999}, format="json"
        )
        self.assertEqual(res.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.loyalty_points, 0)

    def test_cannot_patch_email(self):
        res = self.client.patch(
            "/api/auth/me/", {"email": "hacked@test.app"}, format="json"
        )
        self.assertEqual(res.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "buyer@test.app")


class OrderRulesTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email="client@test.app", password="secret12", display_name="Client"
        )
        self.seller = User.objects.create_user(
            email="seller@test.app", password="secret12", display_name="Seller"
        )
        SellerProfile.objects.create(
            user=self.seller,
            shop_name="Test Shop",
            latitude=14.6928,
            longitude=-17.4467,
            delivery_radius_km=10,
            accepts_delivery=True,
            accepts_pickup=True,
            free_delivery_over=10000,
        )
        self.category = Category.objects.create(name="Plats")
        image = SimpleUploadedFile(
            "meal.jpg", b"fake-image-bytes", content_type="image/jpeg"
        )
        self.meal = Meal.objects.create(
            seller=self.seller,
            category=self.category,
            name="Thieb",
            price=5000,
            is_available=True,
            image=image,
        )
        PromoCode.objects.create(code="BIENVENUE", percent=10, min_total=0)
        PromoCode.objects.create(
            code="SELLERONLY", percent=20, min_total=0, seller=self.seller
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.customer)

    def _order_payload(self, **overrides):
        data = {
            "fulfillment": "delivery",
            "payment_method": "cash",
            "address": "Plateau, Dakar",
            "phone": "770000000",
            "latitude": 14.7167,
            "longitude": -17.4677,
            "items": [{"meal": self.meal.id, "quantity": 1}],
        }
        data.update(overrides)
        return data

    def test_invalid_promo_rejected(self):
        res = self.client.post(
            "/api/orders/",
            self._order_payload(promo_code="FAKECODE"),
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertIn("promo_code", res.data)

    def test_seller_scoped_promo_applies(self):
        res = self.client.post(
            "/api/orders/",
            self._order_payload(promo_code="SELLERONLY"),
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["discount"], 1000)

    def test_free_delivery_over_applied(self):
        self.meal.price = 12000
        self.meal.save()
        res = self.client.post(
            "/api/orders/",
            self._order_payload(),
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["delivery_fee"], 0)

    def test_delivery_requires_address(self):
        res = self.client.post(
            "/api/orders/",
            self._order_payload(address=""),
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_status_transition_enforced(self):
        order = Order.objects.create(
            customer=self.customer,
            status=Order.Status.PENDING,
            subtotal=5000,
            total=5000,
        )
        order.items.create(
            meal=self.meal, meal_name=self.meal.name, unit_price=5000, quantity=1
        )
        seller_client = APIClient()
        seller_client.force_authenticate(user=self.seller)
        res = seller_client.patch(
            f"/api/orders/{order.id}/status/",
            {"status": "delivered"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_promo_validate_endpoint(self):
        res = self.client.post(
            "/api/orders/promo-validate/",
            {
                "promo_code": "BIENVENUE",
                "items": [{"meal": self.meal.id, "quantity": 1}],
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["discount"], 500)
