from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from orders.models import Order

from .models import AnalyticsEvent, ClientSession, OrderContext
from .services import record_event, record_order_context

User = get_user_model()


class AnalyticsEventTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="client@test.com", password="pass1234"
        )
        self.client = APIClient()

    def test_record_event_creates_session(self):
        event = record_event(
            user=self.user,
            data={
                "name": "screen_view",
                "screen": "/home",
                "session_id": "550e8400-e29b-41d4-a716-446655440000",
                "latitude": 14.7167,
                "longitude": -17.4677,
                "platform": "android",
            },
        )
        self.assertEqual(event.name, "screen_view")
        self.assertIsNotNone(event.session)
        self.assertEqual(event.user, self.user)

    def test_api_post_event(self):
        self.client.force_authenticate(user=self.user)
        res = self.client.post(
            "/api/analytics/events/",
            {
                "name": "tap",
                "screen": "cart",
                "element": "checkout_btn",
                "platform": "android",
                "brightness": 0.8,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(AnalyticsEvent.objects.filter(name="tap").exists())

    def test_order_context(self):
        order = Order.objects.create(customer=self.user, total=5000)
        ctx = record_order_context(
            order=order,
            data={
                "latitude": 14.7,
                "longitude": -17.4,
                "brightness": 0.9,
                "platform": "android",
            },
        )
        self.assertEqual(ctx.order, order)
        self.assertEqual(ctx.brightness, 0.9)
        self.assertTrue(OrderContext.objects.filter(order=order).exists())

    def test_content_engagement(self):
        from analytics.services import record_content_engagement
        from analytics.models import ContentEngagement

        record_content_engagement(
            user=self.user,
            data={
                "content_type": "meal",
                "content_id": 42,
                "content_title": "Thieboudienne",
                "duration_seconds": 120,
                "platform": "android",
            },
        )
        e = ContentEngagement.objects.get(content_id=42)
        self.assertEqual(e.duration_seconds, 120)
        self.assertEqual(e.user, self.user)
