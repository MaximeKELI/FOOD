from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from notifications.models import Notification, notify

User = get_user_model()


class NotificationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="u@test.app", password="secret12", display_name="User"
        )

    def test_notify_creates_with_link(self):
        n = notify(
            self.user,
            Notification.Kind.ORDER,
            "Test",
            "Body",
            related_id=42,
            link="order",
        )
        self.assertEqual(n.related_id, 42)
        self.assertEqual(n.link, "order")

    def test_mark_one_read(self):
        n = notify(self.user, Notification.Kind.FOLLOW, "Hi", link="follower")
        from rest_framework.test import APIClient

        client = APIClient()
        client.force_authenticate(user=self.user)
        res = client.post(f"/api/notifications/{n.id}/read/")
        self.assertEqual(res.status_code, 200)
        n.refresh_from_db()
        self.assertTrue(n.is_read)

    @patch("payments.realtime.emit_notification")
    def test_notify_emits_socket_event(self, mock_emit):
        notify(
            self.user,
            Notification.Kind.ORDER,
            "Realtime",
            "Body",
            related_id=99,
        )
        mock_emit.assert_called_once()
