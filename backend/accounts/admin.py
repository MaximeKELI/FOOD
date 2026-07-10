from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.db.models import Count, Q, Sum

from analytics.models import AnalyticsEvent

from .models import Follow, SellerProfile, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ("email",)
    list_display = (
        "email",
        "display_name",
        "click_count",
        "order_count",
        "total_spent",
        "last_city",
        "last_ip",
        "is_staff",
        "is_active",
    )
    search_fields = ("email", "display_name")
    list_filter = ("is_staff", "is_active", "date_joined")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Infos", {"fields": ("display_name", "phone", "loyalty_points", "badges")}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "email",
                    "password1",
                    "password2",
                    "is_staff",
                    "is_superuser",
                ),
            },
        ),
    )

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        click_types = [
            AnalyticsEvent.EventType.CLICK,
            AnalyticsEvent.EventType.TAP,
        ]
        return qs.annotate(
            _click_count=Count(
                "analytics_events",
                filter=Q(event_type__in=click_types),
            ),
            _order_count=Count("orders", distinct=True),
            _total_spent=Sum("orders__total"),
        )

    @admin.display(description="Clics", ordering="_click_count")
    def click_count(self, obj):
        return obj._click_count

    @admin.display(description="Commandes", ordering="_order_count")
    def order_count(self, obj):
        return obj._order_count

    @admin.display(description="Ventes (FCFA)", ordering="_total_spent")
    def total_spent(self, obj):
        return obj._total_spent or 0

    @admin.display(description="Dernière ville")
    def last_city(self, obj):
        event = (
            AnalyticsEvent.objects.filter(user=obj)
            .exclude(city="")
            .order_by("-created_at")
            .first()
        )
        return event.city if event else "—"

    @admin.display(description="Dernière IP")
    def last_ip(self, obj):
        event = (
            AnalyticsEvent.objects.filter(user=obj)
            .exclude(ip_address__isnull=True)
            .order_by("-created_at")
            .first()
        )
        return event.ip_address if event else "—"


admin.site.register(SellerProfile)
admin.site.register(Follow)
