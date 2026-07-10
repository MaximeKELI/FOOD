import secrets
import string
from collections import defaultdict
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsVendor, user_is_vendor
from catalog.models import Meal
from notifications.models import Notification, notify
from orders.models import Order, OrderItem, OrderStatusEvent

from .models import (
    ContentReport,
    Dispute,
    FaqEntry,
    GroupOrder,
    GroupOrderItem,
    ReferralCode,
    ReferralRedemption,
    SavedAddress,
    Story,
    UserBlock,
)
from .serializers import (
    ContentReportSerializer,
    DisputeCreateSerializer,
    DisputeSerializer,
    FaqEntrySerializer,
    GroupOrderItemInputSerializer,
    GroupOrderSerializer,
    ReferralCodeSerializer,
    SavedAddressSerializer,
    StoryCreateSerializer,
    StorySerializer,
    UserBlockSerializer,
)

User = get_user_model()


def _random_code(length=8):
    alphabet = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _referral_code_for(user):
    base = f"U{user.id}{_random_code(4)}"
    return base[:20]


class FaqListView(generics.ListAPIView):
    serializer_class = FaqEntrySerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None

    def get_queryset(self):
        return FaqEntry.objects.filter(is_published=True)


class SavedAddressListCreateView(generics.ListCreateAPIView):
    serializer_class = SavedAddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return SavedAddress.objects.filter(user=self.request.user)


class SavedAddressDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = SavedAddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SavedAddress.objects.filter(user=self.request.user)


class UserBlockListCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = UserBlock.objects.filter(blocker=request.user).select_related("blocked")
        return Response(UserBlockSerializer(qs, many=True).data)

    def post(self, request):
        user_id = request.data.get("user_id") or request.data.get("blocked")
        if not user_id:
            return Response(
                {"detail": "user_id est requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            user_id = int(user_id)
        except (TypeError, ValueError):
            return Response(
                {"detail": "user_id invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if user_id == request.user.id:
            return Response(
                {"detail": "Vous ne pouvez pas vous bloquer vous-même."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        blocked = get_object_or_404(User, pk=user_id)
        existing = UserBlock.objects.filter(
            blocker=request.user, blocked=blocked
        ).first()
        if existing:
            existing.delete()
            return Response({"blocked": False, "user_id": user_id})
        block = UserBlock.objects.create(blocker=request.user, blocked=blocked)
        return Response(
            UserBlockSerializer(block).data,
            status=status.HTTP_201_CREATED,
        )


class UserBlockDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, user_id):
        deleted, _ = UserBlock.objects.filter(
            blocker=request.user, blocked_id=user_id
        ).delete()
        if not deleted:
            return Response(
                {"detail": "Blocage introuvable."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


class ContentReportCreateView(generics.CreateAPIView):
    serializer_class = ContentReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)


class StoryListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsVendor]
    parser_classes = [MultiPartParser, FormParser]
    pagination_class = None

    def get_queryset(self):
        return Story.objects.filter(expires_at__gt=timezone.now()).select_related(
            "author"
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return StoryCreateSerializer
        return StorySerializer

    def create(self, request, *args, **kwargs):
        if not user_is_vendor(request.user):
            return Response(
                {"detail": "Profil vendeur requis."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = StoryCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        story = Story.objects.create(
            author=request.user,
            media=serializer.validated_data["media"],
            caption=serializer.validated_data.get("caption", ""),
            expires_at=timezone.now() + timedelta(hours=24),
        )
        return Response(
            StorySerializer(story, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class StoryFeedView(generics.ListAPIView):
    serializer_class = StorySerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        qs = Story.objects.filter(expires_at__gt=timezone.now()).select_related(
            "author"
        )
        blocked_ids = UserBlock.objects.filter(
            blocker=self.request.user
        ).values_list("blocked_id", flat=True)
        return qs.exclude(author_id__in=blocked_ids)


class StoryDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, pk):
        story = get_object_or_404(Story, pk=pk)
        if story.author_id != request.user.id and not request.user.is_staff:
            return Response(status=status.HTTP_403_FORBIDDEN)
        story.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ReferralMeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        ref, _ = ReferralCode.objects.get_or_create(
            user=request.user,
            defaults={"code": _referral_code_for(request.user)},
        )
        if not ref.code:
            ref.code = _referral_code_for(request.user)
            ref.save(update_fields=["code"])
        return Response(ReferralCodeSerializer(ref).data)


class ReferralRedeemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        code_str = (request.data.get("code") or "").strip().upper()
        if not code_str:
            return Response(
                {"detail": "Code requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if ReferralRedemption.objects.filter(referred_user=request.user).exists():
            return Response(
                {"detail": "Vous avez déjà utilisé un code de parrainage."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        ref = ReferralCode.objects.select_related("user").filter(
            code__iexact=code_str
        ).first()
        if ref is None:
            return Response(
                {"detail": "Code de parrainage invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if ref.user_id == request.user.id:
            return Response(
                {"detail": "Vous ne pouvez pas utiliser votre propre code."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        points = ref.reward_points
        ReferralRedemption.objects.create(
            code=ref,
            referred_user=request.user,
            points_awarded=points,
        )
        referrer = User.objects.select_for_update().get(pk=ref.user_id)
        referred = User.objects.select_for_update().get(pk=request.user.id)
        referrer.loyalty_points = (referrer.loyalty_points or 0) + points
        referred.loyalty_points = (referred.loyalty_points or 0) + points
        referrer.save(update_fields=["loyalty_points"])
        referred.save(update_fields=["loyalty_points"])
        notify(
            referrer,
            Notification.Kind.REFERRAL,
            "Parrainage réussi",
            f"{referred.name} a utilisé votre code (+{points} pts).",
            related_id=ref.id,
            link="referral",
        )
        notify(
            referred,
            Notification.Kind.REFERRAL,
            "Bienvenue !",
            f"Code parrainage appliqué (+{points} pts).",
            related_id=ref.id,
            link="referral",
        )
        return Response(
            {"points_awarded": points, "loyalty_points": referred.loyalty_points}
        )


class DisputeListCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = Dispute.objects.filter(opened_by=request.user).select_related(
            "order", "opened_by"
        )
        return Response(DisputeSerializer(qs, many=True).data)

    def post(self, request):
        serializer = DisputeCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = get_object_or_404(Order, pk=serializer.validated_data["order"])
        user = request.user
        is_customer = order.customer_id == user.id
        is_seller = OrderItem.objects.filter(
            order=order, meal__seller=user
        ).exists()
        if not is_customer and not is_seller:
            return Response(
                {"detail": "Vous ne pouvez pas ouvrir un litige sur cette commande."},
                status=status.HTTP_403_FORBIDDEN,
            )
        dispute = Dispute.objects.create(
            order=order,
            opened_by=user,
            reason=serializer.validated_data["reason"],
            details=serializer.validated_data.get("details", ""),
        )
        return Response(
            DisputeSerializer(dispute).data,
            status=status.HTTP_201_CREATED,
        )


class DisputeDetailView(generics.RetrieveAPIView):
    serializer_class = DisputeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Dispute.objects.filter(opened_by=user).select_related(
            "order", "opened_by"
        )


class GroupOrderCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        seller_id = request.data.get("seller")
        seller = None
        if seller_id:
            seller = get_object_or_404(User, pk=seller_id)
        for _ in range(10):
            code = _random_code(8)
            if not GroupOrder.objects.filter(code=code).exists():
                break
        else:
            return Response(
                {"detail": "Impossible de générer un code."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        group = GroupOrder.objects.create(
            host=request.user,
            code=code,
            seller=seller,
        )
        return Response(
            GroupOrderSerializer(group).data,
            status=status.HTTP_201_CREATED,
        )


class GroupOrderDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, code):
        group = get_object_or_404(
            GroupOrder.objects.select_related("host", "seller").prefetch_related(
                "items__meal", "items__user"
            ),
            code__iexact=code,
        )
        return Response(GroupOrderSerializer(group).data)


class GroupOrderJoinView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, code):
        group = get_object_or_404(GroupOrder, code__iexact=code)
        if group.status != GroupOrder.Status.OPEN:
            return Response(
                {"detail": "Ce groupe n'accepte plus de participants."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(GroupOrderSerializer(group).data)


class GroupOrderAddItemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, code):
        group = get_object_or_404(GroupOrder, code__iexact=code)
        if group.status != GroupOrder.Status.OPEN:
            return Response(
                {"detail": "Ce groupe est verrouillé."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = GroupOrderItemInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        meal = get_object_or_404(Meal, pk=serializer.validated_data["meal"])
        if group.seller_id and meal.seller_id != group.seller_id:
            return Response(
                {"detail": "Ce plat n'appartient pas au vendeur du groupe."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        item, created = GroupOrderItem.objects.update_or_create(
            group=group,
            user=request.user,
            meal=meal,
            defaults={
                "quantity": serializer.validated_data["quantity"],
                "note": serializer.validated_data.get("note", ""),
            },
        )
        return Response(
            GroupOrderSerializer(
                GroupOrder.objects.prefetch_related(
                    "items__meal", "items__user"
                ).get(pk=group.pk)
            ).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class GroupOrderRemoveItemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, code, item_id):
        group = get_object_or_404(GroupOrder, code__iexact=code)
        if group.status != GroupOrder.Status.OPEN:
            return Response(
                {"detail": "Ce groupe est verrouillé."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        item = get_object_or_404(GroupOrderItem, pk=item_id, group=group)
        if item.user_id != request.user.id and group.host_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class GroupOrderCheckoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, code):
        group = (
            GroupOrder.objects.select_for_update()
            .prefetch_related("items__meal")
            .filter(code__iexact=code)
            .first()
        )
        if group is None:
            return Response(
                {"detail": "Groupe introuvable."},
                status=status.HTTP_404_NOT_FOUND,
            )
        if group.host_id != request.user.id:
            return Response(
                {"detail": "Seul l'hôte peut finaliser la commande."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if group.status != GroupOrder.Status.OPEN:
            return Response(
                {"detail": "Ce groupe a déjà été finalisé."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        items = list(group.items.select_related("meal"))
        if not items:
            return Response(
                {"detail": "Le panier de groupe est vide."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Aggregate by meal
        aggregated = defaultdict(lambda: {"quantity": 0, "note": "", "meal": None})
        for gi in items:
            if gi.meal is None or not gi.meal.is_available:
                return Response(
                    {"detail": f"Plat #{gi.meal_id} indisponible."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            bucket = aggregated[gi.meal_id]
            bucket["meal"] = gi.meal
            bucket["quantity"] += gi.quantity
            if gi.note and not bucket["note"]:
                bucket["note"] = gi.note

        subtotal = sum(
            b["meal"].effective_price * b["quantity"] for b in aggregated.values()
        )
        order = Order.objects.create(
            customer=request.user,
            fulfillment=Order.Fulfillment.DELIVERY,
            payment_method=Order.Payment.CASH,
            payment_status=Order.PaymentStatus.NOT_REQUIRED,
            address=request.data.get("address", ""),
            phone=request.data.get("phone", ""),
            note=request.data.get("note", f"Commande de groupe {group.code}"),
            subtotal=subtotal,
            delivery_fee=0,
            discount=0,
        )
        for bucket in aggregated.values():
            meal = bucket["meal"]
            OrderItem.objects.create(
                order=order,
                meal=meal,
                meal_name=meal.name,
                unit_price=meal.effective_price,
                quantity=bucket["quantity"],
                note=bucket["note"],
            )
            if meal.stock_qty is not None:
                meal.stock_qty = max(0, meal.stock_qty - bucket["quantity"])
                meal.save(update_fields=["stock_qty"])

        order.recompute_total()
        order.save()
        OrderStatusEvent.objects.create(
            order=order,
            status=Order.Status.PENDING,
            note="Commande de groupe",
            actor=request.user,
        )
        group.status = GroupOrder.Status.ORDERED
        group.order = order
        group.save(update_fields=["status", "order", "updated_at"])

        from deliveries.services import create_delivery_for_order

        create_delivery_for_order(order)

        from orders.serializers import OrderSerializer

        return Response(
            OrderSerializer(order, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )
