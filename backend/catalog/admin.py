from django.contrib import admin

from .models import (
    Category,
    Meal,
    MealCombo,
    MealFavorite,
    MealOptionChoice,
    MealOptionGroup,
    RecentlyViewedMeal,
    Review,
)

admin.site.register(MealFavorite)
admin.site.register(RecentlyViewedMeal)


class MealOptionChoiceInline(admin.TabularInline):
    model = MealOptionChoice
    extra = 0


@admin.register(MealOptionGroup)
class MealOptionGroupAdmin(admin.ModelAdmin):
    list_display = ("name", "meal", "required", "min_select", "max_select", "order")
    list_filter = ("required",)
    search_fields = ("name", "meal__name")
    inlines = [MealOptionChoiceInline]


@admin.register(MealCombo)
class MealComboAdmin(admin.ModelAdmin):
    list_display = ("name", "seller", "price", "is_available", "created_at")
    list_filter = ("is_available",)
    search_fields = ("name", "seller__email")
    filter_horizontal = ("meals",)


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "meal",
        "user",
        "rating",
        "seller_reply",
        "created_at",
    )
    list_filter = ("rating",)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "order")
    list_editable = ("order",)


@admin.register(Meal)
class MealAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "seller",
        "price",
        "stock_qty",
        "is_available",
        "created_at",
    )
    list_filter = ("category", "is_available", "is_special")
    search_fields = ("name", "seller__email")
