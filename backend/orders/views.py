from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import ExpressionWrapper, F, IntegerField, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from rest_framework.exceptions import ValidationError

from catalog.models import Meal

from .models import Order, OrderItem
from .serializers import (
    OrderCreateSerializer,
    OrderSerializer,
    PromoValidateSerializer,
)
from .services import (
    ALLOWED_STATUS_TRANSITIONS,
    compute_delivery_fee,
    sellers_from_meals,
    subtotal_by_seller,
)

User = get_user_model()


def _line_total():
    """Fresh expression each call (reusing one instance corrupts queries)."""
    return ExpressionWrapper(
        F("unit_price") * F("quantity"), output_field=IntegerField()
    )


class OrderListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Order.objects.filter(customer=self.request.user)
            .prefetch_related("items")
            .all()
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return OrderCreateSerializer
        return OrderSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = serializer.save()
        return Response(
            OrderSerializer(order, context=self.get_serializer_context()).data,
            status=status.HTTP_201_CREATED,
        )


class OrderDetailView(generics.RetrieveAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(customer=self.request.user).prefetch_related(
            "items"
        )


class ReceivedOrderListView(generics.ListAPIView):
    """Orders that contain at least one meal sold by the current user."""

    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Order.objects.filter(items__meal__seller=self.request.user)
            .prefetch_related("items")
            .distinct()
        )


class SellerStatsView(APIView):
    """Aggregated sales statistics for the current seller."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        items = OrderItem.objects.filter(meal__seller=user)
        orders = Order.objects.filter(items__meal__seller=user).distinct()

        revenue = items.aggregate(v=Sum(_line_total()))["v"] or 0
        delivered_revenue = (
            items.filter(order__status=Order.Status.DELIVERED)
            .aggregate(v=Sum(_line_total()))["v"]
            or 0
        )
        items_sold = items.aggregate(v=Sum("quantity"))["v"] or 0

        by_status = {
            value: orders.filter(status=value).count()
            for value, _ in Order.Status.choices
        }

        top_meals = list(
            items.values("meal_name")
            .annotate(qty=Sum("quantity"), revenue=Sum(_line_total()))
            .order_by("-qty")[:5]
        )

        since = timezone.now() - timedelta(days=6)
        per_day = {
            row["d"]: row["v"]
            for row in items.filter(order__created_at__gte=since)
            .annotate(d=TruncDate("order__created_at"))
            .values("d")
            .annotate(v=Sum(_line_total()))
        }
        today = timezone.now().date()
        sales_by_day = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            sales_by_day.append(
                {"date": day.isoformat(), "revenue": per_day.get(day, 0) or 0}
            )

        return Response(
            {
                "orders_count": orders.count(),
                "items_sold": items_sold,
                "revenue": revenue,
                "delivered_revenue": delivered_revenue,
                "by_status": by_status,
                "top_meals": top_meals,
                "sales_by_day": sales_by_day,
                "followers": user.followers.count(),
                "meals_count": user.meals.count(),
            }
        )


class OrderStatusUpdateView(APIView):
    """Lets a seller (owner of a meal in the order) update the order status."""

    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def patch(self, request, pk):
        from notifications.models import Notification, notify

        order = (
            Order.objects.select_for_update()
            .filter(pk=pk, items__meal__seller=request.user)
            .distinct()
            .first()
        )
        if order is None:
            return Response(
                {"detail": "Commande introuvable ou non autorisée."},
                status=status.HTTP_404_NOT_FOUND,
            )
        new_status = request.data.get("status")
        valid = dict(Order.Status.choices)
        if new_status not in valid:
            return Response(
                {"detail": "Statut invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        allowed = ALLOWED_STATUS_TRANSITIONS.get(order.status, set())
        if new_status != order.status and new_status not in allowed:
            return Response(
                {
                    "detail": (
                        f"Transition impossible : {order.get_status_display()} "
                        f"→ {valid[new_status]}."
                    )
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        old_status = order.status
        order.status = new_status
        update_fields = ["status"]

        if (
            new_status == Order.Status.DELIVERED
            and not order.points_awarded
        ):
            points = order.total // 100
            order.points_earned = points
            order.points_awarded = True
            update_fields += ["points_earned", "points_awarded"]
            if points:
                customer = User.objects.select_for_update().get(pk=order.customer_id)
                customer.loyalty_points = (customer.loyalty_points or 0) + points
                customer.save(update_fields=["loyalty_points"])

        order.save(update_fields=update_fields)

        if new_status != old_status:
            notify(
                order.customer,
                Notification.Kind.ORDER_STATUS,
                "Mise à jour de commande",
                f"Commande #{order.id} : {order.get_status_display()}.",
                related_id=order.id,
                link="order",
            )

        return Response(
            OrderSerializer(order, context={"request": request}).data
        )


class DeliveryQuoteView(APIView):
    """Previews the delivery fee for a set of meals + a customer location."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        meal_ids = request.data.get("meals", [])
        lat = request.data.get("latitude")
        lng = request.data.get("longitude")
        try:
            lat = float(lat) if lat is not None else None
            lng = float(lng) if lng is not None else None
        except (TypeError, ValueError):
            lat = lng = None

        if lat is None or lng is None:
            return Response(
                {"detail": "La position GPS est requise pour estimer la livraison."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        meals = {
            meal.pk: meal
            for meal in Meal.objects.filter(pk__in=meal_ids).select_related(
                "seller__seller_profile"
            )
        }
        if not meals:
            return Response({"delivery_fee": 0})

        items = [{"meal": mid, "quantity": 1} for mid in meals]
        sellers = sellers_from_meals(meals, request.user.id)
        seller_subtotals = subtotal_by_seller(items, meals)
        try:
            fee = compute_delivery_fee(sellers, seller_subtotals, lat, lng)
        except ValidationError as exc:
            return Response(exc.detail, status=status.HTTP_400_BAD_REQUEST)
        return Response({"delivery_fee": fee})


class PromoValidateView(APIView):
    """Previews a promo code discount for the current cart."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PromoValidateSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        return Response(
            {
                "promo_code": serializer.validated_data["promo_code"],
                "discount": serializer.validated_data["discount"],
                "subtotal": serializer.validated_data["subtotal"],
            }
        )
