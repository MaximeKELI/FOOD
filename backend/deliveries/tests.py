from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from deliveries.models import Delivery, Driver
from orders.models import Order

User = get_user_model()


class DeliveriesDisabledTests(TestCase):
    def test_delivery_api_returns_503_when_disabled(self):
        user = User.objects.create_user(email="d@test.app", password="secret12")
        client = APIClient()
        client.force_authenticate(user=user)
        with override_settings(DELIVERIES_ENABLED=False):
            res = client.get("/api/deliveries/drivers/me/")
        self.assertEqual(res.status_code, 503)


@override_settings(DELIVERIES_ENABLED=True)
class DeliveriesEnabledTests(TestCase):
    def setUp(self):
        from accounts.models import SellerProfile
        from catalog.models import Category, Meal
        from django.core.files.uploadedfile import SimpleUploadedFile

        self.customer = User.objects.create_user(
            email="cust@test.app", password="secret12"
        )
        self.driver_user = User.objects.create_user(
            email="driver@test.app", password="secret12"
        )
        self.seller = User.objects.create_user(
            email="seller3@test.app", password="secret12"
        )
        SellerProfile.objects.create(
            user=self.seller,
            shop_name="Shop",
            latitude=14.6928,
            longitude=-17.4467,
            accepts_delivery=True,
        )
        cat = Category.objects.create(name="Plats")
        image = SimpleUploadedFile("m.jpg", b"x", content_type="image/jpeg")
        self.meal = Meal.objects.create(
            seller=self.seller,
            category=cat,
            name="Thieb",
            price=3000,
            image=image,
        )
        self.client = APIClient()

    def test_driver_profile_get_or_create(self):
        self.client.force_authenticate(user=self.driver_user)
        res = self.client.get("/api/deliveries/drivers/me/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(Driver.objects.filter(user=self.driver_user).exists())

    def test_driver_can_update_status_and_location(self):
        self.client.force_authenticate(user=self.driver_user)
        res = self.client.patch(
            "/api/deliveries/drivers/me/",
            {"status": "available", "latitude": 14.69, "longitude": -17.44},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["status"], "available")

    def test_delivery_location_emits_for_assigned_driver(self):
        order = Order.objects.create(
            customer=self.customer,
            fulfillment=Order.Fulfillment.DELIVERY,
            latitude=14.7,
            longitude=-17.45,
            total=5000,
        )
        driver = Driver.objects.create(user=self.driver_user, status=Driver.Status.AVAILABLE)
        delivery = Delivery.objects.create(order=order, driver=driver)
        self.client.force_authenticate(user=self.driver_user)
        with self.settings(SOCKET_EMIT_URL=""):
            res = self.client.patch(
                f"/api/deliveries/{delivery.id}/location/",
                {"latitude": 14.71, "longitude": -17.46, "eta_minutes": 12},
                format="json",
            )
        self.assertEqual(res.status_code, 200)
        driver.refresh_from_db()
        self.assertEqual(driver.latitude, 14.71)

    def test_create_delivery_on_order_when_enabled(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/orders/",
            {
                "fulfillment": "delivery",
                "payment_method": "cash",
                "address": "Dakar",
                "phone": "770000000",
                "latitude": 14.69,
                "longitude": -17.44,
                "items": [{"meal": self.meal.id, "quantity": 1}],
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        order_id = res.data["id"]
        self.assertTrue(Delivery.objects.filter(order_id=order_id).exists())
