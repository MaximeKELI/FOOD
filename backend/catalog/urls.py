from django.urls import path

from .views import (
    CategoryListView,
    MealDetailView,
    MealListCreateView,
    ReviewListCreateView,
)

urlpatterns = [
    path("categories/", CategoryListView.as_view(), name="categories"),
    path("meals/", MealListCreateView.as_view(), name="meals"),
    path("meals/<int:pk>/", MealDetailView.as_view(), name="meal_detail"),
    path(
        "meals/<int:meal_id>/reviews/",
        ReviewListCreateView.as_view(),
        name="meal_reviews",
    ),
]
