from django.urls import path

from .views import (
    CategoryListView,
    MealComboDetailView,
    MealComboListCreateView,
    MealDetailView,
    MealFavoriteToggleView,
    MealListCreateView,
    MealOptionDetailView,
    MealOptionsView,
    MyFavoriteMealsView,
    RecentlyViewedMealsView,
    ReviewListCreateView,
    ReviewReplyView,
)

urlpatterns = [
    path("categories/", CategoryListView.as_view(), name="categories"),
    path("meals/", MealListCreateView.as_view(), name="meals"),
    path("favorites/", MyFavoriteMealsView.as_view(), name="my_favorite_meals"),
    path("recent/", RecentlyViewedMealsView.as_view(), name="recent_meals"),
    path("combos/", MealComboListCreateView.as_view(), name="combos"),
    path("combos/<int:pk>/", MealComboDetailView.as_view(), name="combo_detail"),
    path("meals/<int:pk>/", MealDetailView.as_view(), name="meal_detail"),
    path(
        "meals/<int:meal_id>/reviews/",
        ReviewListCreateView.as_view(),
        name="meal_reviews",
    ),
    path(
        "meals/<int:meal_id>/reviews/<int:review_id>/reply/",
        ReviewReplyView.as_view(),
        name="meal_review_reply",
    ),
    path(
        "meals/<int:meal_id>/favorite/",
        MealFavoriteToggleView.as_view(),
        name="meal_favorite",
    ),
    path(
        "meals/<int:meal_id>/options/",
        MealOptionsView.as_view(),
        name="meal_options",
    ),
    path(
        "meals/<int:meal_id>/options/<int:group_id>/",
        MealOptionDetailView.as_view(),
        name="meal_option_detail",
    ),
]
