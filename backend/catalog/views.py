from django.db.models import Avg, Count, Exists, OuterRef, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from notifications.models import Notification, notify

from accounts.permissions import IsVendor

from .models import (
    Category,
    Meal,
    MealCombo,
    MealFavorite,
    MealOptionGroup,
    RecentlyViewedMeal,
    Review,
)
from .serializers import (
    CategorySerializer,
    MealComboSerializer,
    MealCreateSerializer,
    MealOptionGroupSerializer,
    MealOptionGroupWriteSerializer,
    MealSerializer,
    ReviewReplySerializer,
    ReviewSerializer,
)


class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.seller_id == request.user.id


def _meal_queryset(request):
    qs = Meal.objects.select_related(
        "seller", "seller__seller_profile", "category"
    ).prefetch_related("gallery", "option_groups__choices")
    qs = qs.annotate(
        rating_avg=Avg("reviews__rating"),
        reviews_count_annotated=Count("reviews", distinct=True),
    )
    user = request.user
    if user.is_authenticated:
        qs = qs.annotate(
            favorited_by_me_annotated=Exists(
                MealFavorite.objects.filter(
                    meal_id=OuterRef("pk"), user_id=user.id
                )
            )
        )
    return qs


@extend_schema_view(get=extend_schema(tags=["catalog"], summary="List food categories"))
class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None


@extend_schema_view(
    get=extend_schema(tags=["catalog"], summary="List or search meals"),
    post=extend_schema(tags=["catalog"], summary="Create a meal (seller)"),
)
class MealListCreateView(generics.ListCreateAPIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsVendor]

    def get_queryset(self):
        qs = _meal_queryset(self.request)
        params = self.request.query_params
        q = (params.get("q") or "").strip()
        if q:
            qs = qs.filter(
                Q(name__icontains=q)
                | Q(subtitle__icontains=q)
                | Q(seller__display_name__icontains=q)
                | Q(category__name__icontains=q)
            )
        category = params.get("category")
        if category:
            qs = qs.filter(category__name=category)
        seller = params.get("seller")
        if seller:
            qs = qs.filter(seller_id=seller)
        if params.get("available") == "true":
            qs = qs.filter(is_available=True)
        if params.get("special") == "true":
            qs = qs.filter(is_special=True)
        tag = (params.get("tag") or "").strip()
        if tag:
            qs = qs.filter(tags__contains=[tag])
        return qs

    def get_serializer_class(self):
        if self.request.method == "POST":
            return MealCreateSerializer
        return MealSerializer


class MealDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = MealSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        return _meal_queryset(self.request)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.is_authenticated:
            RecentlyViewedMeal.objects.update_or_create(
                user=request.user,
                meal=instance,
                defaults={},
            )
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class RecentlyViewedMealsView(generics.ListAPIView):
    serializer_class = MealSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        meal_ids = (
            RecentlyViewedMeal.objects.filter(user=self.request.user)
            .order_by("-viewed_at")
            .values_list("meal_id", flat=True)[:30]
        )
        ids = list(meal_ids)
        qs = _meal_queryset(self.request).filter(pk__in=ids)
        # Preserve viewed_at order
        order_map = {mid: i for i, mid in enumerate(ids)}
        return sorted(qs, key=lambda m: order_map.get(m.pk, 999))


class ReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = None
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        return Review.objects.filter(meal_id=self.kwargs["meal_id"]).select_related(
            "user"
        )

    def perform_create(self, serializer):
        meal = get_object_or_404(Meal, pk=self.kwargs["meal_id"])
        existing = Review.objects.filter(meal=meal, user=self.request.user).first()
        if existing:
            existing.rating = serializer.validated_data["rating"]
            existing.comment = serializer.validated_data.get("comment", "")
            if "photo" in serializer.validated_data:
                existing.photo = serializer.validated_data["photo"]
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
                    related_id=meal.id,
                    link="meal",
                )


class ReviewReplyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, meal_id, review_id):
        meal = get_object_or_404(Meal, pk=meal_id)
        if meal.seller_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        review = get_object_or_404(Review, pk=review_id, meal=meal)
        serializer = ReviewReplySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        review.seller_reply = serializer.validated_data["reply"]
        review.seller_replied_at = timezone.now()
        review.save(update_fields=["seller_reply", "seller_replied_at"])
        return Response(ReviewSerializer(review).data)


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
        return _meal_queryset(self.request).filter(
            favorited_by__user=self.request.user
        )


class MealOptionsView(APIView):
    """GET/POST option groups for a meal (vendor owner)."""

    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request, meal_id):
        meal = get_object_or_404(Meal, pk=meal_id)
        groups = meal.option_groups.prefetch_related("choices").all()
        return Response(MealOptionGroupSerializer(groups, many=True).data)

    def post(self, request, meal_id):
        meal = get_object_or_404(Meal, pk=meal_id)
        if meal.seller_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        serializer = MealOptionGroupWriteSerializer(
            data=request.data, context={"meal": meal, "request": request}
        )
        serializer.is_valid(raise_exception=True)
        group = serializer.save()
        return Response(
            MealOptionGroupSerializer(group).data,
            status=status.HTTP_201_CREATED,
        )


class MealOptionDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, meal_id, group_id):
        meal = get_object_or_404(Meal, pk=meal_id)
        if meal.seller_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        group = get_object_or_404(MealOptionGroup, pk=group_id, meal=meal)
        serializer = MealOptionGroupWriteSerializer(
            group, data=request.data, partial=True, context={"meal": meal}
        )
        serializer.is_valid(raise_exception=True)
        group = serializer.save()
        return Response(MealOptionGroupSerializer(group).data)

    def delete(self, request, meal_id, group_id):
        meal = get_object_or_404(Meal, pk=meal_id)
        if meal.seller_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        group = get_object_or_404(MealOptionGroup, pk=group_id, meal=meal)
        group.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MealComboListCreateView(generics.ListCreateAPIView):
    serializer_class = MealComboSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsVendor]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        qs = MealCombo.objects.prefetch_related("meals").select_related("seller")
        seller = self.request.query_params.get("seller")
        if seller:
            qs = qs.filter(seller_id=seller)
        if self.request.query_params.get("available") == "true":
            qs = qs.filter(is_available=True)
        return qs


class MealComboDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = MealComboSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]
    parser_classes = [MultiPartParser, FormParser]
    queryset = MealCombo.objects.prefetch_related("meals").select_related("seller")
