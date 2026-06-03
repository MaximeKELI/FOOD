from rest_framework import serializers

from .models import PaymentIntent


class PaymentIntentSerializer(serializers.ModelSerializer):
    publishable_key = serializers.SerializerMethodField()
    client_secret = serializers.CharField(read_only=True)

    class Meta:
        model = PaymentIntent
        fields = (
            "id",
            "order",
            "provider",
            "status",
            "amount",
            "external_id",
            "checkout_url",
            "client_secret",
            "publishable_key",
            "created_at",
        )
        read_only_fields = fields

    def get_publishable_key(self, obj):
        return (obj.metadata or {}).get("publishable_key", "")


class StripeCreateSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
