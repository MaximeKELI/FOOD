from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import SellerProfile

User = get_user_model()


class MeEndpointTests(TestCase):
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

    def test_can_patch_display_name(self):
        res = self.client.patch(
            "/api/auth/me/", {"display_name": "New Name"}, format="json"
        )
        self.assertEqual(res.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.display_name, "New Name")
