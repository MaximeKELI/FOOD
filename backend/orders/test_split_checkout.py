from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import SellerProfile
from catalog.models import Category, Meal
from orders.models import Order

User = get_user_model()


class SplitCheckoutTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email="split@test.app", password="secret12", display_name="Client"
        )
        self.seller_a = User.objects.create_user(
            email="sa@test.app", password="secret12", display_name="A"
        )
        self.seller_b = User.objects.create_user(
            email="sb@test.app", password="secret12", display_name="B"
        )
        for seller, name in ((self.seller_a, "Shop A"), (self.seller_b, "Shop B")):
            SellerProfile.objects.create(
                user=seller,
                shop_name=name,
                latitude=14.6928,
                longitude=-17.4467,
                delivery_radius_km=20,
                accepts_delivery=True,
                accepts_pickup=True,
            )
        cat = Category.objects.create(name="Plats")
        img = SimpleUploadedFile("m.jpg", b"\xff\xd8\xff\xe0" + b"0" * 20, content_type="image/jpeg")
        self.meal_a = Meal.objects.create(
            seller=self.seller_a, category=cat, name="A", price=2000, image=img, is_available=True
        )
        img2 = SimpleUploadedFile("m2.jpg", b"\xff\xd8\xff\xe0" + b"0" * 20, content_type="image/jpeg")
        self.meal_b = Meal.objects.create(
            seller=self.seller_b, category=cat, name="B", price=3000, image=img2, is_available=True
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.customer)

    def test_multi_seller_cart_creates_two_orders(self):
        res = self.client.post(
            "/api/orders/",
            {
                "fulfillment": "delivery",
                "payment_method": "cash",
                "address": "Dakar",
                "phone": "770000000",
                "latitude": 14.7167,
                "longitude": -17.4677,
                "items": [
                    {"meal": self.meal_a.id, "quantity": 1},
                    {"meal": self.meal_b.id, "quantity": 1},
                ],
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data["count"], 2)
        self.assertTrue(res.data["split"])
        self.assertEqual(len(res.data["orders"]), 2)
        self.assertEqual(Order.objects.filter(customer=self.customer).count(), 2)
        # Each order is single-seller.
        for order in Order.objects.filter(customer=self.customer):
            sellers = {
                i.meal.seller_id for i in order.items.select_related("meal")
            }
            self.assertEqual(len(sellers), 1)
