from django.contrib import admin

from .models import Category, Meal


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "order")
    list_editable = ("order",)


@admin.register(Meal)
class MealAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "seller", "price", "is_available", "created_at")
    list_filter = ("category", "is_available")
    search_fields = ("name", "seller__email")
