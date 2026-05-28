from rest_framework import serializers

from catalog.models import Meal

from .models import Order, OrderItem


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

    class Meta:
        model = Order
        fields = (
            "id",
            "status",
            "status_label",
            "fulfillment",
            "address",
            "phone",
            "note",
            "total",
            "items",
            "created_at",
        )
        read_only_fields = ("status", "total")


class OrderCreateSerializer(serializers.Serializer):
    fulfillment = serializers.ChoiceField(
        choices=Order.Fulfillment.choices, default=Order.Fulfillment.DELIVERY
    )
    address = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    note = serializers.CharField(required=False, allow_blank=True)
    items = OrderItemInputSerializer(many=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("Le panier est vide.")
        return value

    def create(self, validated_data):
        items = validated_data.pop("items")
        order = Order.objects.create(
            customer=self.context["request"].user,
            fulfillment=validated_data.get("fulfillment", Order.Fulfillment.DELIVERY),
            address=validated_data.get("address", ""),
            phone=validated_data.get("phone", ""),
            note=validated_data.get("note", ""),
        )
        for item in items:
            meal = Meal.objects.filter(pk=item["meal"]).first()
            if meal is None:
                continue
            OrderItem.objects.create(
                order=order,
                meal=meal,
                meal_name=meal.name,
                unit_price=meal.price or 0,
                quantity=item["quantity"],
            )
        order.recompute_total()
        order.save(update_fields=["total"])
        return order
