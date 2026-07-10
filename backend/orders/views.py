from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Count, ExpressionWrapper, F, IntegerField, Sum
from django.db.models.functions import TruncDate
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import generics, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsVendor
from catalog.models import Meal

from .models import Order, OrderItem, OrderStatusEvent, PromoCode
from .serializers import (
    LoyaltyRedeemPreviewSerializer,
    OrderCreateSerializer,
    OrderSerializer,
    OrderStatusEventSerializer,
    PromoCodeSerializer,
    PromoValidateSerializer,
    ReceivedOrderSerializer,
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
        (F("unit_price") + F("options_extra")) * F("quantity"),
        output_field=IntegerField(),
    )


@extend_schema_view(
    get=extend_schema(tags=["orders"], summary="List customer orders"),
    post=extend_schema(tags=["orders"], summary="Create order from cart"),
)
class OrderListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = (
            Order.objects.filter(customer=self.request.user)
            .select_related("customer")
            .prefetch_related("items", "items__meal")
        )
        params = self.request.query_params
        status_filter = params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter)
        seller = params.get("seller")
        if seller:
            qs = qs.filter(items__meal__seller_id=seller).distinct()
        date_from = params.get("from")
        if date_from:
            qs = qs.filter(created_at__date__gte=date_from)
        date_to = params.get("to")
        if date_to:
            qs = qs.filter(created_at__date__lte=date_to)
        return qs

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
        return (
            Order.objects.filter(customer=self.request.user)
            .select_related("customer")
            .prefetch_related("items", "items__meal")
        )


class OrderTimelineView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        order = get_object_or_404(Order, pk=pk)
        is_customer = order.customer_id == request.user.id
        is_seller = OrderItem.objects.filter(
            order=order, meal__seller=request.user
        ).exists()
        if not is_customer and not is_seller and not request.user.is_staff:
            return Response(status=status.HTTP_403_FORBIDDEN)
        events = order.status_events.select_related("actor").all()
        return Response(OrderStatusEventSerializer(events, many=True).data)


class OrderReorderView(APIView):
    """Returns cart payload from a past order (does not create a new order)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        order = get_object_or_404(Order, pk=pk, customer=request.user)
        items = []
        for item in order.items.all():
            if item.meal_id is None:
                continue
            payload = {
                "meal": item.meal_id,
                "quantity": item.quantity,
                "note": item.note or "",
            }
            # Reconstruct choice ids is not stored; return option snapshot only
            if item.options:
                payload["options_snapshot"] = item.options
            items.append(payload)
        return Response({"items": items})


class ReceivedOrderListView(generics.ListAPIView):
    """Orders that contain at least one meal sold by the current user."""

    serializer_class = ReceivedOrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        seller = self.request.user
        return (
            Order.objects.filter(items__meal__seller=seller)
            .select_related("customer")
            .prefetch_related("items", "items__meal")
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

        by_status = dict(
            orders.values("status")
            .annotate(c=Count("id", distinct=True))
            .values_list("status", "c")
        )
        for value, _ in Order.Status.choices:
            by_status.setdefault(value, 0)

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

        order = Order.objects.select_for_update().filter(pk=pk).first()
        if order is None or not OrderItem.objects.filter(
            order=order, meal__seller=request.user
        ).exists():
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
        reason = (request.data.get("cancellation_reason") or "").strip()
        if new_status == Order.Status.CANCELLED:
            if reason:
                order.cancellation_reason = reason
                update_fields.append("cancellation_reason")
            order.cancelled_by = request.user
            update_fields.append("cancelled_by")

        if (
            new_status == Order.Status.DELIVERED
            and not order.points_awarded
        ):
            seller_total = (
                OrderItem.objects.filter(order=order, meal__seller=request.user)
                .aggregate(v=Sum(_line_total()))["v"]
                or 0
            )
            points = seller_total // 100
            order.points_earned = points
            order.points_awarded = True
            update_fields += ["points_earned", "points_awarded"]
            if points:
                customer = User.objects.select_for_update().get(pk=order.customer_id)
                customer.loyalty_points = (customer.loyalty_points or 0) + points
                customer.save(update_fields=["loyalty_points"])

        order.save(update_fields=update_fields)

        if new_status != old_status:
            OrderStatusEvent.objects.create(
                order=order,
                status=new_status,
                note=reason or "",
                actor=request.user,
            )
            notify(
                order.customer,
                Notification.Kind.ORDER_STATUS,
                "Mise à jour de commande",
                f"Commande #{order.id} : {order.get_status_display()}.",
                related_id=order.id,
                link="order",
            )
            from payments.realtime import emit_order_status

            emit_order_status(order.id, new_status, vendor_id=request.user.id)

        return Response(
            ReceivedOrderSerializer(order, context={"request": request}).data
        )


class OrderCancelView(APIView):
    """Lets the customer cancel a pending order."""

    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        order = (
            Order.objects.select_for_update()
            .filter(pk=pk, customer=request.user)
            .first()
        )
        if order is None:
            return Response(
                {"detail": "Commande introuvable."},
                status=status.HTTP_404_NOT_FOUND,
            )
        if order.status != Order.Status.PENDING:
            return Response(
                {"detail": "Seules les commandes en attente peuvent être annulées."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        reason = (request.data.get("reason") or request.data.get("cancellation_reason") or "").strip()
        order.status = Order.Status.CANCELLED
        order.cancellation_reason = reason
        order.cancelled_by = request.user
        order.save(
            update_fields=["status", "cancellation_reason", "cancelled_by"]
        )
        OrderStatusEvent.objects.create(
            order=order,
            status=Order.Status.CANCELLED,
            note=reason or "Annulée par le client",
            actor=request.user,
        )
        from payments.realtime import emit_order_status

        vendor_id = (
            OrderItem.objects.filter(order=order, meal__isnull=False)
            .values_list("meal__seller_id", flat=True)
            .first()
        )
        emit_order_status(order.id, Order.Status.CANCELLED, vendor_id=vendor_id)
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
            for meal in Meal.objects.filter(
                pk__in=meal_ids, is_available=True
            ).select_related("seller__seller_profile")
        }
        if not meals:
            return Response(
                {"detail": "Aucun plat valide dans le panier."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qty_by_meal = {}
        for mid in meal_ids:
            qty_by_meal[mid] = qty_by_meal.get(mid, 0) + 1
        items = [
            {"meal": mid, "quantity": qty_by_meal[mid]} for mid in qty_by_meal
        ]
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


class SellerPromoListCreateView(generics.ListCreateAPIView):
    serializer_class = PromoCodeSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    def get_queryset(self):
        return PromoCode.objects.filter(seller=self.request.user)


class SellerPromoDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = PromoCodeSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    def get_queryset(self):
        return PromoCode.objects.filter(seller=self.request.user)


class LoyaltyRedeemPreviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = LoyaltyRedeemPreviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        points = serializer.validated_data["points"]
        subtotal = serializer.validated_data.get("subtotal")
        available = request.user.loyalty_points or 0
        usable = min(points, available)
        if subtotal is not None:
            usable = min(usable, subtotal)
        return Response(
            {
                "points_requested": points,
                "points_available": available,
                "points_usable": usable,
                "discount_fcfa": usable,
            }
        )
