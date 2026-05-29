from django.db import transaction
from rest_framework import serializers

from catalog.models import Meal

from .models import Order, OrderItem, PromoCode


def _initial_payment_status(payment_method):
    if payment_method == Order.Payment.CASH:
        return Order.PaymentStatus.NOT_REQUIRED
    return Order.PaymentStatus.PENDING
from .services import (
    compute_delivery_fee,
    resolve_promo,
    sellers_from_meals,
    subtotal_by_seller,
    validate_fulfillment,
)


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
            "payment_status",
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

        customer = self.context["request"].user
        fulfillment = attrs.get("fulfillment", Order.Fulfillment.DELIVERY)
        address = attrs.get("address", "") or ""
        phone = attrs.get("phone", "") or ""
        lat = attrs.get("latitude")
        lng = attrs.get("longitude")
        sellers = sellers_from_meals(meals, customer.id)
        seller_subtotals = subtotal_by_seller(items, meals)
        subtotal = sum(seller_subtotals.values())

        validate_fulfillment(fulfillment, sellers, address, phone, lat, lng)

        delivery_fee = 0
        if fulfillment == Order.Fulfillment.DELIVERY:
            delivery_fee = compute_delivery_fee(
                sellers, seller_subtotals, lat, lng
            )

        promo_code = attrs.get("promo_code", "")
        discount, applied_code = resolve_promo(promo_code, subtotal, sellers)

        attrs["_meals"] = meals
        attrs["_sellers"] = sellers
        attrs["_subtotal"] = subtotal
        attrs["_delivery_fee"] = delivery_fee
        attrs["_discount"] = discount
        attrs["_applied_promo"] = applied_code
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        from notifications.models import Notification, notify

        items = validated_data.pop("items")
        meals = validated_data.pop("_meals")
        sellers = validated_data.pop("_sellers")
        subtotal = validated_data.pop("_subtotal")
        delivery_fee = validated_data.pop("_delivery_fee")
        discount = validated_data.pop("_discount")
        applied_promo = validated_data.pop("_applied_promo")

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
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            discount=discount,
            promo_code=applied_promo,
        )
        for item in items:
            meal = meals[item["meal"]]
            OrderItem.objects.create(
                order=order,
                meal=meal,
                meal_name=meal.name,
                unit_price=meal.effective_price,
                quantity=item["quantity"],
            )

        order.recompute_total()
        order.save()
        for seller in sellers:
            notify(
                seller,
                Notification.Kind.ORDER,
                "Nouvelle commande",
                f"{customer.name} a passé une commande (#{order.id}).",
                related_id=order.id,
                link="received_order",
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
        subtotal = sum(
            meals[item["meal"]].effective_price * item["quantity"] for item in items
        )
        discount, code = resolve_promo(attrs["promo_code"], subtotal, sellers)
        attrs["discount"] = discount
        attrs["promo_code"] = code
        attrs["subtotal"] = subtotal
        return attrs
