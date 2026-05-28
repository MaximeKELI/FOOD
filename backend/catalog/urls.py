from django.urls import path

from .views import CategoryListView, MealDetailView, MealListCreateView

urlpatterns = [
    path("categories/", CategoryListView.as_view(), name="categories"),
    path("meals/", MealListCreateView.as_view(), name="meals"),
    path("meals/<int:pk>/", MealDetailView.as_view(), name="meal_detail"),
]
