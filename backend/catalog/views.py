from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from notifications.models import Notification, notify

from .models import Category, Meal, MealFavorite, Review
from .serializers import (
    CategorySerializer,
    MealCreateSerializer,
    MealSerializer,
    ReviewSerializer,
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


class ReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = None

    def get_queryset(self):
        return Review.objects.filter(meal_id=self.kwargs["meal_id"]).select_related(
            "user"
        )

    def perform_create(self, serializer):
        meal = get_object_or_404(Meal, pk=self.kwargs["meal_id"])
        # One review per user: update if it already exists.
        existing = Review.objects.filter(meal=meal, user=self.request.user).first()
        if existing:
            existing.rating = serializer.validated_data["rating"]
            existing.comment = serializer.validated_data.get("comment", "")
            existing.save()
            serializer.instance = existing
        else:
            review = serializer.save(meal=meal, user=self.request.user)
            if meal.seller_id != self.request.user.id:
                notify(
                    meal.seller,
                    Notification.Kind.REVIEW,
                    "Nouvel avis",
                    f"{self.request.user.name} a noté « {meal.name} » {review.rating}/5.",
                )


class MealFavoriteToggleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, meal_id):
        meal = get_object_or_404(Meal, pk=meal_id)
        fav, created = MealFavorite.objects.get_or_create(
            user=request.user, meal=meal
        )
        if not created:
            fav.delete()
            return Response({"favorited": False})
        return Response({"favorited": True})


class MyFavoriteMealsView(generics.ListAPIView):
    serializer_class = MealSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Meal.objects.filter(
            favorited_by__user=self.request.user
        ).select_related("seller", "category")
