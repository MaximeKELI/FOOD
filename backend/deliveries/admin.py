from django.contrib import admin

from .models import Delivery, Driver


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ("user", "status", "is_active", "is_approved", "vehicle_type")
    list_filter = ("status", "is_active", "is_approved")
    list_editable = ("is_approved", "is_active")
    actions = ("approve_drivers",)

    @admin.action(description="Approuver les chauffeurs sélectionnés")
    def approve_drivers(self, request, queryset):
        queryset.update(is_approved=True, is_active=True)


@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ("order", "driver", "status", "updated_at")
    list_filter = ("status",)
