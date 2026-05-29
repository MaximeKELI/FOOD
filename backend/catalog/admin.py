from django.contrib import admin

from .models import Category, Meal, MealFavorite, Review

admin.site.register(MealFavorite)


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ("id", "meal", "user", "rating", "created_at")
    list_filter = ("rating",)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "order")
    list_editable = ("order",)


@admin.register(Meal)
class MealAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "seller", "price", "is_available", "created_at")
    list_filter = ("category", "is_available")
    search_fields = ("name", "seller__email")
