from django.db.models import Count, F, Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from catalog.models import Meal, MealFavorite, RecentlyViewedMeal, Review
from catalog.serializers import MealSerializer
from orders.models import Order, OrderItem

from .models import (
    DeliveryReview,
    DisputeEvidence,
    KycDocument,
    LoyaltyLedger,
    LoyaltyReward,
    LoyaltyTier,
    MealBoost,
    PickupSlot,
    PlatformSettings,
    SellerInvoice,
    WishList,
    WishListItem,
)
from .serializers import (
    DeliveryReviewSerializer,
    DisputeEvidenceSerializer,
    KycDocumentSerializer,
    LoyaltyLedgerSerializer,
    LoyaltyRewardSerializer,
    LoyaltyTierSerializer,
    MealBoostSerializer,
    PickupSlotSerializer,
    PlatformSettingsSerializer,
    SellerInvoiceSerializer,
    WishListItemSerializer,
    WishListSerializer,
)


class PlatformSettingsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response(PlatformSettingsSerializer(PlatformSettings.get()).data)


class OpsKillSwitchView(APIView):
    """Staff-only toggle for payments / new orders."""

    permission_classes = [permissions.IsAdminUser]

    def patch(self, request):
        cfg = PlatformSettings.get()
        for field in (
            "payments_enabled",
            "cash_enabled",
            "digital_payments_enabled",
            "new_orders_enabled",
            "commission_percent",
            "commission_flat",
        ):
            if field in request.data:
                setattr(cfg, field, request.data[field])
        cfg.save()
        return Response(PlatformSettingsSerializer(cfg).data)


class SellerInvoiceListView(generics.ListAPIView):
    serializer_class = SellerInvoiceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SellerInvoice.objects.filter(seller=self.request.user)


class MealBoostCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        meal = get_object_or_404(Meal, pk=request.data.get("meal"), seller=request.user)
        hours = int(request.data.get("hours", 24))
        hours = max(1, min(hours, 168))
        now = timezone.now()
        boost = MealBoost.objects.create(
            meal=meal,
            seller=request.user,
            starts_at=now,
            expires_at=now + timezone.timedelta(hours=hours),
            score=100 + hours,
            paid_amount=int(request.data.get("paid_amount", hours * 100)),
        )
        meal.is_special = True
        meal.save(update_fields=["is_special"])
        return Response(MealBoostSerializer(boost).data, status=201)

    def get(self, request):
        qs = MealBoost.objects.filter(
            seller=request.user, expires_at__gt=timezone.now()
        ).select_related("meal")
        return Response(MealBoostSerializer(qs, many=True).data)


class WishListListCreateView(generics.ListCreateAPIView):
    serializer_class = WishListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WishList.objects.filter(user=self.request.user).prefetch_related(
            "items__meal"
        )

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class WishListDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = WishListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WishList.objects.filter(user=self.request.user).prefetch_related(
            "items__meal"
        )


class WishListAddItemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        wishlist = get_object_or_404(WishList, pk=pk, user=request.user)
        meal = get_object_or_404(Meal, pk=request.data.get("meal"))
        item, created = WishListItem.objects.get_or_create(
            wishlist=wishlist, meal=meal
        )
        return Response(
            WishListItemSerializer(item, context={"request": request}).data,
            status=201 if created else 200,
        )

    def delete(self, request, pk):
        wishlist = get_object_or_404(WishList, pk=pk, user=request.user)
        meal_id = request.data.get("meal") or request.query_params.get("meal")
        WishListItem.objects.filter(wishlist=wishlist, meal_id=meal_id).delete()
        return Response(status=204)


class LoyaltySummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        points = user.loyalty_points or 0
        tiers = list(LoyaltyTier.objects.all())
        current = None
        nxt = None
        for tier in tiers:
            if points >= tier.min_points:
                current = tier
            elif nxt is None:
                nxt = tier
        ledger = LoyaltyLedger.objects.filter(user=user)[:30]
        rewards = LoyaltyReward.objects.filter(active=True)
        return Response(
            {
                "points": points,
                "current_tier": LoyaltyTierSerializer(current).data if current else None,
                "next_tier": LoyaltyTierSerializer(nxt).data if nxt else None,
                "ledger": LoyaltyLedgerSerializer(ledger, many=True).data,
                "rewards": LoyaltyRewardSerializer(rewards, many=True).data,
                "progress_to_next": (
                    {
                        "have": points,
                        "need": nxt.min_points,
                        "remaining": max(0, nxt.min_points - points),
                    }
                    if nxt
                    else None
                ),
            }
        )


class LoyaltyRedeemRewardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        reward = get_object_or_404(
            LoyaltyReward, pk=request.data.get("reward"), active=True
        )
        user = request.user
        if (user.loyalty_points or 0) < reward.points_cost:
            return Response({"detail": "Points insuffisants."}, status=400)
        user.loyalty_points = (user.loyalty_points or 0) - reward.points_cost
        user.save(update_fields=["loyalty_points"])
        LoyaltyLedger.objects.create(
            user=user,
            kind=LoyaltyLedger.Kind.REWARD,
            points=-reward.points_cost,
            balance_after=user.loyalty_points,
            note=f"Récompense: {reward.title}",
        )
        return Response({"loyalty_points": user.loyalty_points, "reward": reward.title})


class KycUploadView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request):
        qs = KycDocument.objects.filter(user=request.user)
        return Response(KycDocumentSerializer(qs, many=True).data)

    def post(self, request):
        ser = KycDocumentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        doc = ser.save(user=request.user)
        return Response(KycDocumentSerializer(doc).data, status=201)


class PickupSlotListCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        seller_id = request.query_params.get("seller") or request.user.id
        qs = PickupSlot.objects.filter(
            seller_id=seller_id,
            is_active=True,
            starts_at__gte=timezone.now() - timezone.timedelta(hours=1),
        )
        return Response(PickupSlotSerializer(qs, many=True).data)

    def post(self, request):
        ser = PickupSlotSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        slot = ser.save(seller=request.user)
        return Response(PickupSlotSerializer(slot).data, status=201)


class PickupSlotBookView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        slot = get_object_or_404(PickupSlot, pk=pk, is_active=True)
        if slot.remaining <= 0:
            return Response({"detail": "Créneau complet."}, status=400)
        PickupSlot.objects.filter(pk=slot.pk, booked__lt=F("capacity")).update(
            booked=F("booked") + 1
        )
        slot.refresh_from_db()
        return Response(PickupSlotSerializer(slot).data)


class DisputeEvidenceCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        from support.models import Dispute

        dispute = get_object_or_404(
            Dispute, pk=request.data.get("dispute"), opened_by=request.user
        )
        ser = DisputeEvidenceSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        ev = ser.save(uploaded_by=request.user, dispute=dispute)
        return Response(DisputeEvidenceSerializer(ev).data, status=201)


class DeliveryReviewCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order = get_object_or_404(
            Order,
            pk=request.data.get("order"),
            customer=request.user,
            status=Order.Status.DELIVERED,
        )
        if hasattr(order, "delivery_review"):
            return Response({"detail": "Avis déjà envoyé."}, status=400)
        ser = DeliveryReviewSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        review = ser.save(customer=request.user, order=order)
        return Response(DeliveryReviewSerializer(review).data, status=201)


class RecommendationsView(APIView):
    """Simple reco: favorites categories + recent + boosted + highly rated."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        now = timezone.now()
        boosted_ids = list(
            MealBoost.objects.filter(expires_at__gt=now).values_list(
                "meal_id", flat=True
            )[:20]
        )
        qs = Meal.objects.filter(is_available=True).select_related(
            "seller", "category", "seller__seller_profile"
        )
        scored = []
        if request.user.is_authenticated:
            fav_cats = (
                MealFavorite.objects.filter(user=request.user)
                .values_list("meal__category_id", flat=True)
                .distinct()
            )
            recent_ids = list(
                RecentlyViewedMeal.objects.filter(user=request.user).values_list(
                    "meal_id", flat=True
                )[:15]
            )
            qs_fav = qs.filter(category_id__in=fav_cats).exclude(
                pk__in=recent_ids
            )[:10]
            scored.extend(list(qs_fav))
            scored.extend(list(qs.filter(pk__in=recent_ids)[:5]))
        scored.extend(list(qs.filter(pk__in=boosted_ids)[:8]))
        top_rated = (
            qs.annotate(avg=Sum("reviews__rating"), n=Count("reviews"))
            .filter(n__gte=1)
            .order_by("-avg")[:10]
        )
        scored.extend(list(top_rated))
        # Dedupe preserving order
        seen = set()
        unique = []
        for m in scored:
            if m.pk in seen:
                continue
            seen.add(m.pk)
            unique.append(m)
        return Response(
            MealSerializer(
                unique[:20], many=True, context={"request": request}
            ).data
        )


class OpenNowSellersView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        from accounts.models import SellerProfile
        from accounts.serializers import PublicSellerSerializer
        from orders.serializers import _seller_open_now

        profiles = SellerProfile.objects.filter(
            shop_name__gt=""
        ).select_related("user")
        open_users = [
            p.user
            for p in profiles
            if _seller_open_now(p) and p.accepts_orders
        ]
        # Lightweight payload
        data = []
        for u in open_users[:50]:
            p = u.seller_profile
            data.append(
                {
                    "id": u.id,
                    "name": u.name,
                    "shop_name": p.shop_name,
                    "opens_at": p.opens_at,
                    "closes_at": p.closes_at,
                    "cuisine": p.cuisine,
                    "is_open_now": True,
                }
            )
        return Response(data)


class SellerDashboardExtraView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from django.db.models import ExpressionWrapper, IntegerField

        user = request.user
        today = timezone.localdate()
        line = ExpressionWrapper(
            (F("unit_price") + F("options_extra")) * F("quantity"),
            output_field=IntegerField(),
        )
        items = OrderItem.objects.filter(meal__seller=user)
        today_rev = (
            items.filter(order__created_at__date=today).aggregate(v=Sum(line))["v"]
            or 0
        )
        low_stock = Meal.objects.filter(
            seller=user, stock_qty__isnull=False, stock_qty__lte=3
        ).count()
        pending = (
            Order.objects.filter(
                items__meal__seller=user, status=Order.Status.PENDING
            )
            .distinct()
            .count()
        )
        unreplied = Review.objects.filter(
            meal__seller=user, seller_reply=""
        ).count()
        cfg = PlatformSettings.get()
        gmv_month = (
            items.filter(
                order__created_at__year=today.year,
                order__created_at__month=today.month,
            ).aggregate(v=Sum(line))["v"]
            or 0
        )
        commission = gmv_month * cfg.commission_percent // 100 + cfg.commission_flat
        return Response(
            {
                "today_revenue": today_rev,
                "low_stock_meals": low_stock,
                "pending_orders": pending,
                "unreplied_reviews": unreplied,
                "month_gmv": gmv_month,
                "estimated_commission": commission,
                "commission_percent": cfg.commission_percent,
            }
        )


class OpsOverviewView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        from deliveries.models import Delivery, Driver
        from support.models import Dispute

        return Response(
            {
                "settings": PlatformSettingsSerializer(PlatformSettings.get()).data,
                "pending_disputes": Dispute.objects.filter(
                    status=Dispute.Status.OPEN
                ).count(),
                "pending_kyc": KycDocument.objects.filter(
                    status=KycDocument.Status.PENDING
                ).count(),
                "active_deliveries": Delivery.objects.exclude(
                    status__in=["delivered", "cancelled"]
                ).count(),
                "drivers_pending": Driver.objects.filter(is_approved=False).count(),
                "orders_today": Order.objects.filter(
                    created_at__date=timezone.localdate()
                ).count(),
            }
        )
