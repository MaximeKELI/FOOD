from math import asin, cos, radians, sin, sqrt

from django.db import transaction
from rest_framework import serializers

from catalog.models import Meal

from .models import Order, OrderItem, PromoCode


def _haversine_km(lat1, lng1, lat2, lng2):
    r = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lng = radians(lng2 - lng1)
    a = (
        sin(d_lat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lng / 2) ** 2
    )
    return 2 * r * asin(sqrt(a))


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
            "line_total",
        )
        read_only_fields = ("meal_name", "unit_price", "line_total")


class OrderItemInputSerializer(serializers.Serializer):
    meal = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, default=1)


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
            "address",
            "phone",
            "note",
            "subtotal",
            "delivery_fee",
            "discount",
            "promo_code",
            "points_earned",
            "total",
            "customer_name",
            "items",
            "created_at",
        )
        read_only_fields = ("status", "total")


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
        for item in items:
            meal = meals.get(item["meal"])
            if meal is None:
                errors.append(f"Plat #{item['meal']} introuvable.")
            elif not meal.is_available:
                errors.append(f"{meal.name} n'est plus disponible.")

        if errors:
            raise serializers.ValidationError({"items": errors})

        attrs["_meals"] = meals
        return attrs

    def _delivery_fee(self, sellers, lat, lng):
        """Sum of per-seller delivery fees based on distance."""
        fee = 0
        for seller in sellers:
            profile = getattr(seller, "seller_profile", None)
            if profile is None:
                continue
            base = profile.delivery_fee_base
            if lat is not None and lng is not None and (
                profile.latitude is not None and profile.longitude is not None
            ):
                km = _haversine_km(lat, lng, profile.latitude, profile.longitude)
                base += int(round(km)) * profile.delivery_fee_per_km
            fee += base
        return fee

    @transaction.atomic
    def create(self, validated_data):
        from notifications.models import Notification, notify

        items = validated_data.pop("items")
        meals = validated_data.pop("_meals")
        customer = self.context["request"].user
        fulfillment = validated_data.get(
            "fulfillment", Order.Fulfillment.DELIVERY
        )
        lat = validated_data.get("latitude")
        lng = validated_data.get("longitude")
        order = Order.objects.create(
            customer=customer,
            fulfillment=fulfillment,
            payment_method=validated_data.get("payment_method", Order.Payment.CASH),
            address=validated_data.get("address", ""),
            phone=validated_data.get("phone", ""),
            note=validated_data.get("note", ""),
            latitude=lat,
            longitude=lng,
        )
        sellers = set()
        for item in items:
            meal = meals[item["meal"]]
            OrderItem.objects.create(
                order=order,
                meal=meal,
                meal_name=meal.name,
                unit_price=meal.effective_price,
                quantity=item["quantity"],
            )
            if meal.seller_id and meal.seller_id != customer.id:
                sellers.add(meal.seller)

        order.subtotal = sum(i.line_total for i in order.items.all())

        if fulfillment == Order.Fulfillment.DELIVERY:
            order.delivery_fee = self._delivery_fee(sellers, lat, lng)

        code = (validated_data.get("promo_code") or "").strip()
        if code:
            promo = PromoCode.objects.filter(code__iexact=code).first()
            if promo:
                order.discount = promo.discount_for(order.subtotal)
                if order.discount > 0:
                    order.promo_code = promo.code

        order.recompute_total()
        order.save()
        for seller in sellers:
            notify(
                seller,
                Notification.Kind.ORDER,
                "Nouvelle commande",
                f"{customer.name} a passé une commande (#{order.id}).",
            )
        return order
