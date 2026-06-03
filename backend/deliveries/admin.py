from django.contrib import admin

from .models import Delivery, Driver


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ("user", "status", "is_active", "vehicle_type")
    list_filter = ("status", "is_active")


@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ("order", "driver", "status", "updated_at")
    list_filter = ("status",)
