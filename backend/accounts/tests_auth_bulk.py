"""100 register + login cycles (client + seller)."""

from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from accounts.views import RegisterView, ThrottledTokenObtainPairView

User = get_user_model()


class AuthBulkRegisterLoginTests(TestCase):
    """One assertion suite covering 100 full register→login flows."""

    @patch.object(RegisterView, "throttle_classes", [])
    @patch.object(ThrottledTokenObtainPairView, "throttle_classes", [])
    def test_100_register_and_login(self, *_patches):
        client = APIClient()
        passed = 0
        failures = []

        for i in range(100):
            is_seller = i % 2 == 1
            email = f"bulk_{i:03d}@test.local"
            password = f"Secret{i:03d}!"
            name = f"User {i:03d}"
            payload = {
                "email": email,
                "password": password,
                "name": name,
                "phone": f"+23760000{i:04d}",
                "account_type": "seller" if is_seller else "client",
            }
            if is_seller:
                payload.update(
                    {
                        "country": "Cameroun",
                        "city": "Douala",
                        "shop_name": f"Shop {i:03d}",
                        "shop_category": "Restaurant",
                        "cuisine": "Africaine",
                        "opens_at": "08:00",
                        "closes_at": "22:00",
                        "delivery_radius_km": 5,
                        "accepts_delivery": True,
                        "accepts_pickup": True,
                    }
                )

            mode = "seller" if is_seller else "client"
            with self.subTest(i=i, mode=mode):
                res = client.post("/api/auth/register/", payload, format="json")
                if res.status_code != 201:
                    failures.append((i, "register", res.status_code, res.data))
                    continue
                if "tokens" not in res.data or "access" not in res.data["tokens"]:
                    failures.append((i, "register_tokens", res.status_code, res.data))
                    continue
                if res.data["user"]["email"] != email:
                    failures.append((i, "register_email", res.status_code, res.data))
                    continue
                if res.data["user"]["is_vendor"] != is_seller:
                    failures.append((i, "register_vendor", res.status_code, res.data))
                    continue

                res = client.post(
                    "/api/auth/login/",
                    {"email": email, "password": password},
                    format="json",
                )
                if res.status_code != 200 or "access" not in res.data:
                    failures.append((i, "login", res.status_code, getattr(res, "data", None)))
                    continue

                client.credentials(HTTP_AUTHORIZATION=f"Bearer {res.data['access']}")
                me = client.get("/api/auth/me/")
                client.credentials()
                if me.status_code != 200 or me.data.get("email") != email:
                    failures.append((i, "me", me.status_code, getattr(me, "data", None)))
                    continue

                passed += 1

        self.assertEqual(
            passed,
            100,
            f"{passed}/100 OK; failures={failures[:10]}",
        )
        self.assertEqual(User.objects.filter(email__startswith="bulk_").count(), 100)
        self.assertEqual(failures, [])
