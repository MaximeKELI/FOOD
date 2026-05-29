from django.db.models import ExpressionWrapper, F, IntegerField, Sum
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Order, OrderItem
from .serializers import OrderCreateSerializer, OrderSerializer

_LINE_TOTAL = ExpressionWrapper(
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

        revenue = items.aggregate(v=Sum(_LINE_TOTAL))["v"] or 0
        delivered_revenue = (
            items.filter(order__status=Order.Status.DELIVERED)
            .aggregate(v=Sum(_LINE_TOTAL))["v"]
            or 0
        )
        items_sold = items.aggregate(v=Sum("quantity"))["v"] or 0

        by_status = {
            value: orders.filter(status=value).count()
            for value, _ in Order.Status.choices
        }

        top_meals = list(
            items.values("meal_name")
            .annotate(quantity=Sum("quantity"), revenue=Sum(_LINE_TOTAL))
            .order_by("-quantity")[:5]
        )

        return Response(
            {
                "orders_count": orders.count(),
                "items_sold": items_sold,
                "revenue": revenue,
                "delivered_revenue": delivered_revenue,
                "by_status": by_status,
                "top_meals": top_meals,
                "followers": user.followers.count(),
                "meals_count": user.meals.count(),
            }
        )


class OrderStatusUpdateView(APIView):
    """Lets a seller (owner of a meal in the order) update the order status."""

    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        order = Order.objects.filter(
            pk=pk, items__meal__seller=request.user
        ).first()
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
        order.status = new_status
        order.save(update_fields=["status"])
        return Response(
            OrderSerializer(order, context={"request": request}).data
        )
