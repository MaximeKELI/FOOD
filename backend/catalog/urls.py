from django.urls import path

from .views import (
    CategoryListView,
    MealDetailView,
    MealFavoriteToggleView,
    MealListCreateView,
    MyFavoriteMealsView,
    ReviewListCreateView,
)

urlpatterns = [
    path("categories/", CategoryListView.as_view(), name="categories"),
    path("meals/", MealListCreateView.as_view(), name="meals"),
    path("favorites/", MyFavoriteMealsView.as_view(), name="my_favorite_meals"),
    path("meals/<int:pk>/", MealDetailView.as_view(), name="meal_detail"),
    path(
        "meals/<int:meal_id>/reviews/",
        ReviewListCreateView.as_view(),
        name="meal_reviews",
    ),
    path(
        "meals/<int:meal_id>/favorite/",
        MealFavoriteToggleView.as_view(),
        name="meal_favorite",
    ),
]
