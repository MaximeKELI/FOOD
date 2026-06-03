from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

User = get_user_model()


class AuthApiTests(TestCase):
    def test_register_and_login(self):
        client = APIClient()
        res = client.post(
            "/api/auth/register/",
            {
                "email": "new@test.app",
                "password": "secret1234",
                "name": "New User",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertIn("tokens", res.data)

        res = client.post(
            "/api/auth/login/",
            {"email": "new@test.app", "password": "secret1234"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.data)
