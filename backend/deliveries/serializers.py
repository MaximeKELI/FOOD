from rest_framework import serializers

from .models import Delivery, Driver


class DriverSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        fields = (
            "id",
            "vehicle_type",
            "license_plate",
            "status",
            "latitude",
            "longitude",
            "is_active",
        )
        read_only_fields = ("id",)


class DriverUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        fields = ("vehicle_type", "license_plate", "status", "latitude", "longitude")


class DeliverySerializer(serializers.ModelSerializer):
    order_id = serializers.IntegerField(source="order.id", read_only=True)

    class Meta:
        model = Delivery
        fields = (
            "id",
            "order_id",
            "status",
            "driver",
            "pickup_latitude",
            "pickup_longitude",
            "dropoff_latitude",
            "dropoff_longitude",
            "eta_minutes",
            "updated_at",
        )


class DeliveryLocationSerializer(serializers.Serializer):
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    eta_minutes = serializers.IntegerField(required=False, min_value=1, max_value=240)
