from datetime import datetime

from django.db import transaction
from django.utils import timezone
from rest_framework import serializers

from catalog.models import Meal, MealOptionChoice

from .models import Order, OrderItem, OrderStatusEvent, PromoCode
from .services import (
    compute_delivery_fee,
    resolve_promo,
    sellers_from_meals,
    subtotal_by_seller,
    validate_fulfillment,
)


def _initial_payment_status(payment_method):
    if payment_method == Order.Payment.CASH:
        return Order.PaymentStatus.NOT_REQUIRED
    return Order.PaymentStatus.PENDING


def _seller_open_now(profile):
    """Simple HH:MM local-time window check. Returns True if open or unset."""
    opens = (profile.opens_at or "").strip()
    closes = (profile.closes_at or "").strip()
    if not opens or not closes:
        return True
    try:
        open_t = datetime.strptime(opens, "%H:%M").time()
        close_t = datetime.strptime(closes, "%H:%M").time()
    except ValueError:
        return True
    now = timezone.localtime().time()
    if open_t <= close_t:
        return open_t <= now <= close_t
    # Overnight window (e.g. 22:00–02:00)
    return now >= open_t or now <= close_t


class OrderItemSerializer(serializers.ModelSerializer):
    line_total = serializers.IntegerField(read_only=True)

    class Meta:
        model = OrderItem
        fields = (
            "id",
            "meal",
            "meal_name",
            "unit_price",
            "quantity",
            "note",
            "options",
            "options_extra",
            "line_total",
        )
        read_only_fields = ("meal_name", "unit_price", "line_total", "options_extra")


class OrderItemInputSerializer(serializers.Serializer):
    meal = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, max_value=50, default=1)
    note = serializers.CharField(required=False, allow_blank=True, default="")
    options = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        default=list,
    )


class OrderStatusEventSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = OrderStatusEvent
        fields = ("id", "status", "note", "actor", "actor_name", "created_at")

    def get_actor_name(self, obj):
        return obj.actor.name if obj.actor_id else ""


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    payment_label = serializers.CharField(
        source="get_payment_method_display", read_only=True
    )
    customer_name = serializers.CharField(source="customer.name", read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "status",
            "status_label",
            "fulfillment",
            "payment_method",
            "payment_label",
            "payment_status",
            "address",
            "phone",
            "note",
            "latitude",
            "longitude",
            "subtotal",
            "delivery_fee",
            "discount",
            "promo_code",
            "points_earned",
            "points_redeemed",
            "scheduled_for",
            "cancellation_reason",
            "total",
            "customer_name",
            "items",
            "created_at",
        )
        read_only_fields = ("status", "total")


class ReceivedOrderItemSerializer(serializers.ModelSerializer):
    line_total = serializers.IntegerField(read_only=True)

    class Meta:
        model = OrderItem
        fields = (
            "id",
            "meal",
            "meal_name",
            "unit_price",
            "quantity",
            "note",
            "options",
            "options_extra",
            "line_total",
        )


class ReceivedOrderSerializer(serializers.ModelSerializer):
    """Seller-scoped view: only this seller's items and revenue."""

    items = serializers.SerializerMethodField()
    seller_subtotal = serializers.SerializerMethodField()
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    payment_label = serializers.CharField(
        source="get_payment_method_display", read_only=True
    )
    customer_name = serializers.CharField(source="customer.name", read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "status",
            "status_label",
            "fulfillment",
            "payment_method",
            "payment_label",
            "payment_status",
            "address",
            "phone",
            "note",
            "scheduled_for",
            "cancellation_reason",
            "seller_subtotal",
            "customer_name",
            "items",
            "created_at",
        )

    def _seller_items(self, obj):
        seller = self.context["request"].user
        return [i for i in obj.items.all() if i.meal_id and i.meal.seller_id == seller.id]

    def get_items(self, obj):
        return ReceivedOrderItemSerializer(self._seller_items(obj), many=True).data

    def get_seller_subtotal(self, obj):
        return sum(i.line_total for i in self._seller_items(obj))


class DeviceContextSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    city = serializers.CharField(required=False, allow_blank=True)
    country = serializers.CharField(required=False, allow_blank=True)
    region = serializers.CharField(required=False, allow_blank=True)
    device_time = serializers.DateTimeField(required=False, allow_null=True)
    timezone = serializers.CharField(required=False, allow_blank=True)
    brightness = serializers.FloatField(required=False, allow_null=True)
    platform = serializers.CharField(required=False, allow_blank=True)
    device_model = serializers.CharField(required=False, allow_blank=True)
    app_version = serializers.CharField(required=False, allow_blank=True)
    connection_type = serializers.CharField(required=False, allow_blank=True)
    battery_level = serializers.FloatField(required=False, allow_null=True)


class OrderCreateSerializer(serializers.Serializer):
    fulfillment = serializers.ChoiceField(
        choices=Order.Fulfillment.choices, default=Order.Fulfillment.DELIVERY
    )
    payment_method = serializers.ChoiceField(
        choices=Order.Payment.choices, default=Order.Payment.CASH
    )
    address = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    note = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    promo_code = serializers.CharField(required=False, allow_blank=True)
    scheduled_for = serializers.DateTimeField(required=False, allow_null=True)
    points_to_redeem = serializers.IntegerField(
        required=False, min_value=0, default=0
    )
    device_context = DeviceContextSerializer(required=False)
    items = OrderItemInputSerializer(many=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("Le panier est vide.")
        return value

    def validate(self, attrs):
        items = attrs.get("items", [])
        meal_ids = [item["meal"] for item in items]
        meals = {
            meal.pk: meal
            for meal in Meal.objects.filter(pk__in=meal_ids).select_related(
                "seller__seller_profile"
            )
        }

        errors = []
        item_options = {}  # meal_key index -> (snapshot, extra)
        for idx, item in enumerate(items):
            meal = meals.get(item["meal"])
            if meal is None:
                errors.append(f"Plat #{item['meal']} introuvable.")
                continue
            if not meal.is_available:
                errors.append(f"{meal.name} n'est plus disponible.")
            if meal.stock_qty is not None and meal.stock_qty < item["quantity"]:
                errors.append(
                    f"Stock insuffisant pour {meal.name} "
                    f"(disponible : {meal.stock_qty})."
                )

            choice_ids = item.get("options") or []
            snapshot = []
            options_extra = 0
            if choice_ids:
                choices = list(
                    MealOptionChoice.objects.filter(
                        pk__in=choice_ids,
                        group__meal_id=meal.pk,
                        is_available=True,
                    ).select_related("group")
                )
                found = {c.pk for c in choices}
                missing = [cid for cid in choice_ids if cid not in found]
                if missing:
                    errors.append(
                        f"Options invalides pour {meal.name} : {missing}."
                    )
                for choice in choices:
                    snapshot.append(
                        {
                            "group": choice.group.name,
                            "choice": choice.name,
                            "extra": choice.price_extra,
                        }
                    )
                    options_extra += choice.price_extra
            item_options[idx] = (snapshot, options_extra)

        if errors:
            raise serializers.ValidationError({"items": errors})

        customer = self.context["request"].user
        fulfillment = attrs.get("fulfillment", Order.Fulfillment.DELIVERY)
        address = attrs.get("address", "") or ""
        phone = attrs.get("phone", "") or ""
        lat = attrs.get("latitude")
        lng = attrs.get("longitude")
        sellers = sellers_from_meals(meals, customer.id)

        # Accepts orders + open hours + min order
        seller_errors = []
        for seller in sellers:
            profile = getattr(seller, "seller_profile", None)
            if profile is None:
                continue
            shop = profile.shop_name or seller.name
            if not profile.accepts_orders:
                seller_errors.append(f"{shop} n'accepte pas de commandes actuellement.")
            if not _seller_open_now(profile):
                seller_errors.append(
                    f"{shop} est fermé (horaires {profile.opens_at}–{profile.closes_at})."
                )

        # Subtotal including options_extra
        seller_subtotals = {}
        for idx, item in enumerate(items):
            meal = meals[item["meal"]]
            _, options_extra = item_options[idx]
            line = (meal.effective_price + options_extra) * item["quantity"]
            sid = meal.seller_id or 0
            seller_subtotals[sid] = seller_subtotals.get(sid, 0) + line
        subtotal = sum(seller_subtotals.values())

        for seller in sellers:
            profile = getattr(seller, "seller_profile", None)
            if profile and profile.min_order_amount:
                seller_total = seller_subtotals.get(seller.id, 0)
                if seller_total < profile.min_order_amount:
                    shop = profile.shop_name or seller.name
                    seller_errors.append(
                        f"Minimum {profile.min_order_amount} FCFA pour {shop} "
                        f"(panier : {seller_total} FCFA)."
                    )

        if seller_errors:
            raise serializers.ValidationError({"sellers": seller_errors})

        validate_fulfillment(fulfillment, sellers, address, phone, lat, lng)

        delivery_fee = 0
        if fulfillment == Order.Fulfillment.DELIVERY:
            delivery_fee = compute_delivery_fee(
                sellers, seller_subtotals, lat, lng
            )

        promo_code = attrs.get("promo_code", "")
        discount, applied_code = resolve_promo(
            promo_code, subtotal, sellers, seller_subtotals
        )

        points_to_redeem = attrs.get("points_to_redeem") or 0
        available = customer.loyalty_points or 0
        points_to_redeem = min(points_to_redeem, available, subtotal)

        attrs["_meals"] = meals
        attrs["_sellers"] = sellers
        attrs["_subtotal"] = subtotal
        attrs["_delivery_fee"] = delivery_fee
        attrs["_discount"] = discount
        attrs["_applied_promo"] = applied_code
        attrs["_item_options"] = item_options
        attrs["_points_redeemed"] = points_to_redeem
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        from django.contrib.auth import get_user_model
        from notifications.models import Notification, notify

        User = get_user_model()
        items = validated_data.pop("items")
        meals = validated_data.pop("_meals")
        sellers = validated_data.pop("_sellers")
        subtotal = validated_data.pop("_subtotal")
        delivery_fee = validated_data.pop("_delivery_fee")
        discount = validated_data.pop("_discount")
        applied_promo = validated_data.pop("_applied_promo")
        item_options = validated_data.pop("_item_options")
        points_redeemed = validated_data.pop("_points_redeemed")
        validated_data.pop("points_to_redeem", None)

        customer = self.context["request"].user
        fulfillment = validated_data.get(
            "fulfillment", Order.Fulfillment.DELIVERY
        )
        order = Order.objects.create(
            customer=customer,
            fulfillment=fulfillment,
            payment_method=validated_data.get("payment_method", Order.Payment.CASH),
            payment_status=_initial_payment_status(
                validated_data.get("payment_method", Order.Payment.CASH)
            ),
            address=validated_data.get("address", ""),
            phone=validated_data.get("phone", ""),
            note=validated_data.get("note", ""),
            latitude=validated_data.get("latitude"),
            longitude=validated_data.get("longitude"),
            scheduled_for=validated_data.get("scheduled_for"),
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            discount=discount,
            promo_code=applied_promo,
            points_redeemed=points_redeemed,
        )
        for idx, item in enumerate(items):
            meal = meals[item["meal"]]
            snapshot, options_extra = item_options[idx]
            OrderItem.objects.create(
                order=order,
                meal=meal,
                meal_name=meal.name,
                unit_price=meal.effective_price,
                quantity=item["quantity"],
                note=item.get("note", ""),
                options=snapshot,
                options_extra=options_extra,
            )
            if meal.stock_qty is not None:
                meal.stock_qty = max(0, meal.stock_qty - item["quantity"])
                meal.save(update_fields=["stock_qty"])

        if points_redeemed:
            locked = User.objects.select_for_update().get(pk=customer.pk)
            locked.loyalty_points = max(
                0, (locked.loyalty_points or 0) - points_redeemed
            )
            locked.save(update_fields=["loyalty_points"])

        order.recompute_total()
        order.save()
        OrderStatusEvent.objects.create(
            order=order,
            status=Order.Status.PENDING,
            note="Commande créée",
            actor=customer,
        )
        for seller in sellers:
            notify(
                seller,
                Notification.Kind.ORDER,
                "Nouvelle commande",
                f"{customer.name} a passé une commande (#{order.id}).",
                related_id=order.id,
                link="received_order",
            )
        from deliveries.services import create_delivery_for_order

        create_delivery_for_order(order)

        device_context = validated_data.get("device_context")
        if device_context:
            from analytics.services import record_order_context

            ctx_data = dict(device_context)
            if order.latitude is not None:
                ctx_data.setdefault("latitude", order.latitude)
            if order.longitude is not None:
                ctx_data.setdefault("longitude", order.longitude)
            record_order_context(
                order=order,
                data=ctx_data,
                request=self.context["request"],
            )

        return order


class PromoValidateSerializer(serializers.Serializer):
    promo_code = serializers.CharField()
    items = OrderItemInputSerializer(many=True)

    def validate(self, attrs):
        items = attrs.get("items", [])
        if not items:
            raise serializers.ValidationError({"items": "Le panier est vide."})
        meal_ids = [item["meal"] for item in items]
        meals = {
            meal.pk: meal
            for meal in Meal.objects.filter(pk__in=meal_ids).select_related(
                "seller__seller_profile"
            )
        }
        for item in items:
            if item["meal"] not in meals:
                raise serializers.ValidationError(
                    {"items": f"Plat #{item['meal']} introuvable."}
                )
        customer = self.context["request"].user
        sellers = sellers_from_meals(meals, customer.id)
        seller_subtotals = subtotal_by_seller(items, meals)
        subtotal = sum(seller_subtotals.values())
        discount, code = resolve_promo(
            attrs["promo_code"], subtotal, sellers, seller_subtotals
        )
        attrs["discount"] = discount
        attrs["promo_code"] = code
        attrs["subtotal"] = subtotal
        return attrs


class PromoCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromoCode
        fields = (
            "id",
            "code",
            "percent",
            "amount",
            "min_total",
            "active",
            "starts_at",
            "ends_at",
            "created_at",
        )
        read_only_fields = ("created_at",)

    def create(self, validated_data):
        validated_data["seller"] = self.context["request"].user
        return super().create(validated_data)


class LoyaltyRedeemPreviewSerializer(serializers.Serializer):
    points = serializers.IntegerField(min_value=0)
    subtotal = serializers.IntegerField(min_value=0, required=False)
