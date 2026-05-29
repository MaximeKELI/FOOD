from rest_framework import serializers

from .models import PaymentIntent


class PaymentIntentSerializer(serializers.ModelSerializer):
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    provider_label = serializers.CharField(source="get_provider_display", read_only=True)

    class Meta:
        model = PaymentIntent
        fields = (
            "id",
            "order",
            "provider",
            "provider_label",
            "status",
            "status_label",
            "amount",
            "external_id",
            "checkout_url",
            "created_at",
        )
        read_only_fields = fields
