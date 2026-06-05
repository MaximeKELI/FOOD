import json

from django.contrib import admin
from django.db.models import Count, Sum
from django.shortcuts import render
from django.utils.html import format_html

from accounts.models import User
from orders.models import Order

from .dashboard import build_dashboard_context
from .models import (
    AnalyticsDashboard,
    AnalyticsEvent,
    ClientSession,
    ContentEngagement,
    OrderContext,
)


def _dashboard_stats():
    total_clients = User.objects.filter(is_staff=False).count()
    total_orders = Order.objects.count()
    total_revenue = Order.objects.aggregate(v=Sum("total"))["v"] or 0
    total_clicks = AnalyticsEvent.objects.filter(
        event_type__in=[
            AnalyticsEvent.EventType.CLICK,
            AnalyticsEvent.EventType.TAP,
        ]
    ).count()
    total_events = AnalyticsEvent.objects.count()
    total_sessions = ClientSession.objects.count()
    top_cities = list(
        AnalyticsEvent.objects.exclude(city="")
        .values("city")
        .annotate(c=Count("id"))
        .order_by("-c")[:5]
    )
    return {
        "total_clients": total_clients,
        "total_orders": total_orders,
        "total_revenue": total_revenue,
        "total_clicks": total_clicks,
        "total_events": total_events,
        "total_sessions": total_sessions,
        "top_cities": top_cities,
    }


class AnalyticsDashboardMixin:
    """Inject summary stats at the top of changelist views."""

    def changelist_view(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context["dashboard"] = _dashboard_stats()
        return super().changelist_view(request, extra_context=extra_context)


@admin.register(ClientSession)
class ClientSessionAdmin(AnalyticsDashboardMixin, admin.ModelAdmin):
    list_display = (
        "session_id",
        "user_link",
        "event_count",
        "city",
        "country",
        "platform",
        "device_model",
        "ip_address",
        "last_seen",
    )
    list_filter = ("platform", "country", "city")
    search_fields = ("session_id", "user__email", "city", "ip_address", "device_model")
    readonly_fields = (
        "session_id",
        "user",
        "event_count",
        "first_seen",
        "last_seen",
    )
    ordering = ("-last_seen",)

    @admin.display(description="Client")
    def user_link(self, obj):
        if not obj.user_id:
            return "—"
        return format_html(
            '<a href="{}">{}</a>',
            f"/admin/accounts/user/{obj.user_id}/change/",
            obj.user.email,
        )


@admin.register(AnalyticsEvent)
class AnalyticsEventAdmin(AnalyticsDashboardMixin, admin.ModelAdmin):
    list_display = (
        "created_at",
        "name",
        "event_type",
        "user_link",
        "screen",
        "city",
        "ip_address",
        "brightness",
        "device_time",
        "weather_condition",
        "temperature_c",
    )
    list_filter = (
        "event_type",
        "name",
        "platform",
        "country",
        "city",
        "weather_condition",
        ("created_at", admin.DateFieldListFilter),
    )
    search_fields = (
        "name",
        "screen",
        "element",
        "user__email",
        "city",
        "ip_address",
        "device_model",
    )
    readonly_fields = (
        "session",
        "user",
        "order",
        "created_at",
        "metadata",
    )
    date_hierarchy = "created_at"
    ordering = ("-created_at",)

    @admin.display(description="Client")
    def user_link(self, obj):
        if not obj.user_id:
            return "anonyme"
        return format_html(
            '<a href="{}">{}</a>',
            f"/admin/accounts/user/{obj.user_id}/change/",
            obj.user.email,
        )


class OrderContextInline(admin.StackedInline):
    model = OrderContext
    extra = 0
    can_delete = False
    readonly_fields = (
        "ip_address",
        "latitude",
        "longitude",
        "city",
        "country",
        "region",
        "device_time",
        "timezone",
        "brightness",
        "weather_condition",
        "temperature_c",
        "weather_code",
        "is_sunny",
        "is_rainy",
        "cloud_cover",
        "platform",
        "device_model",
        "app_version",
        "connection_type",
        "battery_level",
        "created_at",
    )
    fieldsets = (
        ("Localisation", {
            "fields": (
                "ip_address",
                ("latitude", "longitude"),
                ("city", "country", "region"),
            ),
        }),
        ("Appareil", {
            "fields": (
                ("device_time", "timezone"),
                "brightness",
                ("platform", "device_model", "app_version"),
                ("connection_type", "battery_level"),
            ),
        }),
        ("Météo à l'achat", {
            "fields": (
                "weather_condition",
                ("temperature_c", "cloud_cover"),
                ("is_sunny", "is_rainy"),
                "weather_code",
            ),
        }),
    )


@admin.register(OrderContext)
class OrderContextAdmin(AnalyticsDashboardMixin, admin.ModelAdmin):
    list_display = (
        "order_link",
        "customer_email",
        "city",
        "country",
        "ip_address",
        "device_time",
        "brightness",
        "weather_condition",
        "temperature_c",
        "platform",
        "created_at",
    )
    list_filter = ("country", "city", "weather_condition", "platform")
    search_fields = (
        "order__customer__email",
        "city",
        "ip_address",
        "device_model",
    )
    readonly_fields = [f.name for f in OrderContext._meta.fields]
    ordering = ("-created_at",)

    @admin.display(description="Commande")
    def order_link(self, obj):
        return format_html(
            '<a href="{}">#{}</a>',
            f"/admin/orders/order/{obj.order_id}/change/",
            obj.order_id,
        )

    @admin.display(description="Client")
    def customer_email(self, obj):
        return obj.order.customer.email


@admin.register(ContentEngagement)
class ContentEngagementAdmin(AnalyticsDashboardMixin, admin.ModelAdmin):
    list_display = (
        "created_at",
        "content_type",
        "content_id",
        "content_title",
        "duration_display",
        "user_link",
        "city",
        "platform",
    )
    list_filter = ("content_type", "platform", "city", ("created_at", admin.DateFieldListFilter))
    search_fields = ("content_title", "user__email", "content_id")
    readonly_fields = [f.name for f in ContentEngagement._meta.fields]
    ordering = ("-created_at",)

    @admin.display(description="Client")
    def user_link(self, obj):
        if not obj.user_id:
            return "anonyme"
        return format_html(
            '<a href="{}">{}</a>',
            f"/admin/accounts/user/{obj.user_id}/change/",
            obj.user.email,
        )


@admin.register(AnalyticsDashboard)
class AnalyticsDashboardAdmin(admin.ModelAdmin):
    """Custom analytics dashboard with charts and filters."""

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return request.user.is_staff

    def has_delete_permission(self, request, obj=None):
        return False

    def has_module_permission(self, request):
        return request.user.is_staff

    def changelist_view(self, request, extra_context=None):
        ctx = build_dashboard_context(request)
        ctx.update({
            "title": "Tableau Analytics",
            "site_title": admin.site.site_title,
            "site_header": admin.site.site_header,
            "has_permission": True,
            "top_content_json": json.dumps([
                {
                    "content_type": r["content_type"],
                    "content_id": r["content_id"],
                    "content_title": r["content_title"] or "",
                    "views": r["views"],
                    "total_seconds": r["total_seconds"] or 0,
                    "avg_seconds": float(r["avg_seconds"] or 0),
                }
                for r in ctx["top_content"]
            ]),
            "by_type_json": json.dumps([
                {
                    "content_type": r["content_type"],
                    "views": r["views"],
                    "total_seconds": r["total_seconds"] or 0,
                }
                for r in ctx["by_type"]
            ]),
            "by_day_json": json.dumps([
                {
                    "day": r["day"].isoformat() if r["day"] else "",
                    "views": r["views"],
                    "total_seconds": r["total_seconds"] or 0,
                }
                for r in ctx["by_day"]
            ]),
        })
        return render(request, "admin/analytics/dashboard.html", ctx)
