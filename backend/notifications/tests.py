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

    def test_mark_one_read_idempotent(self):
        n = notify(self.user, Notification.Kind.FOLLOW, "Hi2", link="follower")
        n.is_read = True
        n.save(update_fields=["is_read"])
        from rest_framework.test import APIClient

        client = APIClient()
        client.force_authenticate(user=self.user)
        res = client.post(f"/api/notifications/{n.id}/read/")
        self.assertEqual(res.status_code, 200)

    def test_delete_one(self):
        n = notify(self.user, Notification.Kind.CHAT, "Msg", link="chat")
        from rest_framework.test import APIClient

        client = APIClient()
        client.force_authenticate(user=self.user)
        res = client.delete(f"/api/notifications/{n.id}/")
        self.assertEqual(res.status_code, 200)
        self.assertFalse(Notification.objects.filter(pk=n.id).exists())

    def test_delete_one_via_read_action(self):
        n = notify(self.user, Notification.Kind.CHAT, "Msg 2", link="chat")
        from rest_framework.test import APIClient

        client = APIClient()
        client.force_authenticate(user=self.user)
        res = client.post(
            f"/api/notifications/{n.id}/read/",
            {"action": "delete"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertFalse(Notification.objects.filter(pk=n.id).exists())

    def test_sanitize_em_dash(self):
        n = notify(
            self.user,
            Notification.Kind.WEATHER,
            "Titre — test",
            "Corps — avec tiret",
            link="home",
        )
        self.assertNotIn("\u2014", n.title)
        self.assertNotIn("\u2014", n.body)

    def test_clear_all(self):
        notify(self.user, Notification.Kind.ORDER, "A", link="order")
        notify(self.user, Notification.Kind.FOLLOW, "B", link="follower")
        from rest_framework.test import APIClient

        client = APIClient()
        client.force_authenticate(user=self.user)
        res = client.post(
            "/api/notifications/read/",
            {"action": "clear"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(
            Notification.objects.filter(recipient=self.user).count(), 0
        )

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
