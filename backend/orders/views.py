from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Order
from .serializers import OrderCreateSerializer, OrderSerializer


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
