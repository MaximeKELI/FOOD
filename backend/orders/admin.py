from django.contrib import admin

from .models import Order, OrderItem, PromoCode


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "customer", "status", "fulfillment", "total", "created_at")
    list_filter = ("status", "fulfillment")
    inlines = [OrderItemInline]


@admin.register(PromoCode)
class PromoCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "percent", "amount", "min_total", "active", "seller")
    list_filter = ("active",)
    search_fields = ("code",)
