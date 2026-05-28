from rest_framework import generics, permissions
from rest_framework.parsers import FormParser, MultiPartParser

from .models import Category, Meal
from .serializers import (
    CategorySerializer,
    MealCreateSerializer,
    MealSerializer,
)


class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.seller_id == request.user.id


class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None


class MealListCreateView(generics.ListCreateAPIView):
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        qs = Meal.objects.select_related("seller", "category").all()
        category = self.request.query_params.get("category")
        if category:
            qs = qs.filter(category__name=category)
        seller = self.request.query_params.get("seller")
        if seller:
            qs = qs.filter(seller_id=seller)
        return qs

    def get_serializer_class(self):
        if self.request.method == "POST":
            return MealCreateSerializer
        return MealSerializer


class MealDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Meal.objects.select_related("seller", "category").all()
    serializer_class = MealSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]
    parser_classes = [MultiPartParser, FormParser]
