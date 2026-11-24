import tempfile

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from catalog.models import Meal
from ops.models import (
    LoyaltyReward,
    LoyaltyTier,
    PlatformSettings,
    WishList,
)
from orders.models import Order, PromoCode
from support.models import Dispute

User = get_user_model()
MEDIA = tempfile.mkdtemp()


@override_settings(MEDIA_ROOT=MEDIA)
class PlatformApiTests(APITestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email="c@test.app", password="pass12345", display_name="Cust"
        )
        self.seller = User.objects.create_user(
            email="s@test.app", password="pass12345", display_name="Seller"
        )
        self.admin = User.objects.create_superuser(
            email="a@test.app", password="pass12345"
        )
        self.meal = Meal.objects.create(
            seller=self.seller,
            name="Thieboudienne",
            subtitle="Riz poisson",
            price=2500,
            image=SimpleUploadedFile("m.jpg", b"\xff\xd8\xff", content_type="image/jpeg"),
            is_available=True,
        )
        PlatformSettings.get()
        LoyaltyTier.objects.create(name="Bronze", min_points=0, perk="Bienvenue")
        LoyaltyTier.objects.create(name="Or", min_points=100, perk="Livraison -10%")
        LoyaltyReward.objects.create(title="Boisson", points_cost=50)

    def test_settings_public(self):
        res = self.client.get("/api/platform/settings/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["payments_enabled"])

    def test_wishlist_flow(self):
        self.client.force_authenticate(self.customer)
        res = self.client.post("/api/platform/wishlists/", {"name": "Soirée"}, format="json")
        self.assertEqual(res.status_code, 201)
        wid = res.data["id"]
        res = self.client.post(
            f"/api/platform/wishlists/{wid}/items/",
            {"meal": self.meal.id},
            format="json",
        )
        self.assertIn(res.status_code, (200, 201))
        self.assertEqual(WishList.objects.get(pk=wid).items.count(), 1)

    def test_loyalty_summary(self):
        self.customer.loyalty_points = 40
        self.customer.save(update_fields=["loyalty_points"])
        self.client.force_authenticate(self.customer)
        res = self.client.get("/api/platform/loyalty/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["points"], 40)
        self.assertIsNotNone(res.data["current_tier"])

    def test_open_now_and_recommendations(self):
        res = self.client.get("/api/platform/open-now/")
        self.assertEqual(res.status_code, 200)
        res = self.client.get("/api/platform/recommendations/")
        self.assertEqual(res.status_code, 200)

    def test_ops_admin_only(self):
        self.client.force_authenticate(self.customer)
        res = self.client.get("/api/platform/ops/")
        self.assertEqual(res.status_code, 403)
        self.client.force_authenticate(self.admin)
        res = self.client.get("/api/platform/ops/")
        self.assertEqual(res.status_code, 200)
        res = self.client.patch(
            "/api/platform/ops/flags/",
            {"new_orders_enabled": False},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertFalse(PlatformSettings.get().new_orders_enabled)

    def test_boost_and_dashboard_extra(self):
        self.client.force_authenticate(self.seller)
        res = self.client.post(
            "/api/platform/boosts/",
            {"meal": self.meal.id, "hours": 12},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        res = self.client.get("/api/platform/seller/dashboard-extra/")
        self.assertEqual(res.status_code, 200)
        self.assertIn("commission_percent", res.data)

    def test_promo_limits_on_model(self):
        promo = PromoCode.objects.create(
            code="LIMIT1",
            seller=self.seller,
            percent=10,
            max_uses=1,
            uses_count=1,
        )
        self.assertEqual(promo.discount_for(5000), 0)

    def test_meal_share(self):
        res = self.client.get(f"/api/catalog/meals/{self.meal.id}/share/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["deep_link"], f"food://meal/{self.meal.id}")

    def test_me_exposes_staff_flags(self):
        self.client.force_authenticate(self.admin)
        res = self.client.get("/api/auth/me/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["is_staff"])
        self.assertTrue(res.data["is_superuser"])


@override_settings(MEDIA_ROOT=MEDIA)
class DisputeEvidenceTests(APITestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            email="d@test.app", password="pass12345"
        )
        self.seller = User.objects.create_user(
            email="ds@test.app", password="pass12345"
        )
        meal = Meal.objects.create(
            seller=self.seller,
            name="Yassa",
            price=2000,
            image=SimpleUploadedFile("y.jpg", b"\xff\xd8\xff", content_type="image/jpeg"),
        )
        self.order = Order.objects.create(
            customer=self.customer,
            subtotal=2000,
            delivery_fee=0,
            discount=0,
            total=2000,
            status=Order.Status.DELIVERED,
            payment_status=Order.PaymentStatus.PAID,
        )
        from orders.models import OrderItem

        OrderItem.objects.create(
            order=self.order,
            meal=meal,
            meal_name=meal.name,
            unit_price=2000,
            quantity=1,
        )
        self.dispute = Dispute.objects.create(
            order=self.order,
            opened_by=self.customer,
            reason="Retard",
            details="Trop long",
        )

    def test_upload_evidence(self):
        self.client.force_authenticate(self.customer)
        f = SimpleUploadedFile("e.jpg", b"\xff\xd8\xff", content_type="image/jpeg")
        res = self.client.post(
            "/api/platform/disputes/evidence/",
            {"dispute": self.dispute.id, "file": f, "note": "photo"},
            format="multipart",
        )
        self.assertEqual(res.status_code, 201)
