"""Aggregations for the admin analytics dashboard."""

from __future__ import annotations

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Avg, Count, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone

from accounts.models import User
from orders.models import Order

from .models import AnalyticsEvent, ClientSession, ContentEngagement

User = get_user_model()


def _period_start(period: str):
    now = timezone.now()
    mapping = {
        "7": timedelta(days=7),
        "30": timedelta(days=30),
        "90": timedelta(days=90),
    }
    delta = mapping.get(period)
    return now - delta if delta else None


def build_dashboard_context(request):
    period = request.GET.get("period", "30")
    content_type = request.GET.get("type", "all")
    sort = request.GET.get("sort", "duration")
    user_id = request.GET.get("user", "").strip()

    since = _period_start(period)
    engagements = ContentEngagement.objects.all()
    events = AnalyticsEvent.objects.all()
    orders = Order.objects.all()

    if since:
        engagements = engagements.filter(created_at__gte=since)
        events = events.filter(created_at__gte=since)
        orders = orders.filter(created_at__gte=since)

    if content_type in ("meal", "video", "short"):
        engagements = engagements.filter(content_type=content_type)

    if user_id.isdigit():
        engagements = engagements.filter(user_id=int(user_id))
        events = events.filter(user_id=int(user_id))
        orders = orders.filter(customer_id=int(user_id))

    total_engagements = engagements.count()
    total_watch_seconds = engagements.aggregate(v=Sum("duration_seconds"))["v"] or 0
    unique_users = engagements.exclude(user__isnull=True).values("user").distinct().count()
    unique_content = engagements.values("content_type", "content_id").distinct().count()

    content_stats = list(
        engagements.values("content_type", "content_id", "content_title")
        .annotate(
            views=Count("id"),
            total_seconds=Sum("duration_seconds"),
            avg_seconds=Avg("duration_seconds"),
        )
    )

    sort_key = {
        "duration": lambda r: r["total_seconds"] or 0,
        "views": lambda r: r["views"],
        "avg": lambda r: r["avg_seconds"] or 0,
        "title": lambda r: (r["content_title"] or "").lower(),
    }.get(sort, lambda r: r["total_seconds"] or 0)
    content_stats.sort(key=sort_key, reverse=sort != "title")

    top_content = content_stats[:15]

    by_type = list(
        engagements.values("content_type")
        .annotate(
            views=Count("id"),
            total_seconds=Sum("duration_seconds"),
        )
        .order_by("-total_seconds")
    )

    by_day = list(
        engagements.annotate(day=TruncDate("created_at"))
        .values("day")
        .annotate(
            views=Count("id"),
            total_seconds=Sum("duration_seconds"),
        )
        .order_by("day")
    )

    top_users = list(
        engagements.exclude(user__isnull=True)
        .values("user__email", "user__display_name", "user_id")
        .annotate(
            views=Count("id"),
            total_seconds=Sum("duration_seconds"),
        )
        .order_by("-total_seconds")[:10]
    )

    recent = engagements.select_related("user").order_by("-created_at")[:25]

    users_for_filter = User.objects.filter(is_staff=False).order_by("email")[:200]

    return {
        "period": period,
        "content_type": content_type,
        "sort": sort,
        "user_id": user_id,
        "total_clients": User.objects.filter(is_staff=False).count(),
        "total_orders": orders.count(),
        "total_revenue": orders.aggregate(v=Sum("total"))["v"] or 0,
        "total_events": events.count(),
        "total_sessions": ClientSession.objects.count(),
        "total_engagements": total_engagements,
        "total_watch_seconds": total_watch_seconds,
        "total_watch_display": _format_seconds(total_watch_seconds),
        "unique_users": unique_users,
        "unique_content": unique_content,
        "top_content": top_content,
        "by_type": by_type,
        "by_day": by_day,
        "top_users": top_users,
        "recent_engagements": recent,
        "users_for_filter": users_for_filter,
        "type_labels": dict(ContentEngagement.ContentType.choices),
    }


def _format_seconds(total: int) -> str:
    if total < 60:
        return f"{total}s"
    m, s = divmod(total, 60)
    if m < 60:
        return f"{m}m {s}s"
    h, m = divmod(m, 60)
    return f"{h}h {m}m"
