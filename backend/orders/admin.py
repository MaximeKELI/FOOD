from django.contrib import admin

from analytics.admin import OrderContextInline

from .models import Order, OrderItem, OrderStatusEvent, PromoCode


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


class OrderStatusEventInline(admin.TabularInline):
    model = OrderStatusEvent
    extra = 0
    readonly_fields = ("status", "note", "actor", "created_at")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "customer",
        "status",
        "fulfillment",
        "total",
        "points_redeemed",
        "scheduled_for",
        "context_city",
        "context_weather",
        "context_ip",
        "created_at",
    )
    list_filter = (
        "status",
        "fulfillment",
        "context__city",
        "context__weather_condition",
    )
    search_fields = ("customer__email", "context__city", "context__ip_address")
    inlines = [OrderItemInline, OrderStatusEventInline, OrderContextInline]

    @admin.display(description="Ville")
    def context_city(self, obj):
        ctx = getattr(obj, "context", None)
        return ctx.city if ctx else "—"

    @admin.display(description="Météo")
    def context_weather(self, obj):
        ctx = getattr(obj, "context", None)
        if not ctx or not ctx.weather_condition:
            return "—"
        temp = f" {ctx.temperature_c:.0f}°C" if ctx.temperature_c is not None else ""
        return f"{ctx.weather_condition}{temp}"

    @admin.display(description="IP")
    def context_ip(self, obj):
        ctx = getattr(obj, "context", None)
        return ctx.ip_address if ctx else "—"


@admin.register(OrderStatusEvent)
class OrderStatusEventAdmin(admin.ModelAdmin):
    list_display = ("id", "order", "status", "actor", "created_at")
    list_filter = ("status",)
    search_fields = ("order__id", "note")


@admin.register(PromoCode)
class PromoCodeAdmin(admin.ModelAdmin):
    list_display = (
        "code",
        "percent",
        "amount",
        "min_total",
        "active",
        "starts_at",
        "ends_at",
        "seller",
    )
    list_filter = ("active",)
    search_fields = ("code",)
