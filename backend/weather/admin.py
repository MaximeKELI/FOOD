from django.contrib import admin

from .models import WeatherNudgeLog


@admin.register(WeatherNudgeLog)
class WeatherNudgeLogAdmin(admin.ModelAdmin):
    list_display = ("user", "condition", "temperature_c", "sent_at")
    list_filter = ("condition", "sent_at")
    search_fields = ("user__email",)
