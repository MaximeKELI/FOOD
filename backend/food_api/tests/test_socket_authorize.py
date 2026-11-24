from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from chat.models import Conversation
from orders.models import Order

User = get_user_model()


@override_settings(SOCKET_INTERNAL_SECRET="test-internal-secret")
class SocketAuthorizeTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="a@test.app", password="secret12", display_name="A"
        )
        self.other = User.objects.create_user(
            email="b@test.app", password="secret12", display_name="B"
        )
        self.headers = {"HTTP_X_INTERNAL_SECRET": "test-internal-secret"}

    def test_rejects_bad_secret(self):
        res = self.client.post(
            "/api/internal/socket-authorize/",
            {"user_id": self.user.id, "rooms": [f"user:{self.user.id}"]},
            format="json",
            HTTP_X_INTERNAL_SECRET="wrong",
        )
        self.assertEqual(res.status_code, 403)

    def test_allows_own_user_room_only(self):
        res = self.client.post(
            "/api/internal/socket-authorize/",
            {
                "user_id": self.user.id,
                "rooms": [
                    f"user:{self.user.id}",
                    f"user:{self.other.id}",
                    f"vendor:{self.user.id}",
                ],
            },
            format="json",
            **self.headers,
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(
            set(res.data["allowed"]),
            {f"user:{self.user.id}", f"vendor:{self.user.id}"},
        )

    def test_conversation_membership(self):
        convo = Conversation.between(self.user, self.other)
        res = self.client.post(
            "/api/internal/socket-authorize/",
            {
                "user_id": self.user.id,
                "rooms": [f"conversation:{convo.id}", "conversation:999999"],
            },
            format="json",
            **self.headers,
        )
        self.assertEqual(res.data["allowed"], [f"conversation:{convo.id}"])

    def test_order_customer_allowed(self):
        order = Order.objects.create(customer=self.user, total=1000)
        res = self.client.post(
            "/api/internal/socket-authorize/",
            {"user_id": self.user.id, "rooms": [f"order:{order.id}"]},
            format="json",
            **self.headers,
        )
        self.assertEqual(res.data["allowed"], [f"order:{order.id}"])
        res2 = self.client.post(
            "/api/internal/socket-authorize/",
            {"user_id": self.other.id, "rooms": [f"order:{order.id}"]},
            format="json",
            **self.headers,
        )
        self.assertEqual(res2.data["allowed"], [])
