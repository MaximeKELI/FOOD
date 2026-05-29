from django.conf import settings
from django.shortcuts import get_object_or_404
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from orders.models import Order

from .models import PaymentIntent
from .providers import initiate_payment, verify_webhook_secret
from .serializers import PaymentIntentSerializer
from .services import mark_intent_paid


class PaymentInitiateView(APIView):
    """Starts a mobile-money payment for an existing order."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order_id = request.data.get("order_id")
        order = get_object_or_404(Order, pk=order_id, customer=request.user)
        if order.payment_method == Order.Payment.CASH:
            return Response(
                {"detail": "Cette commande est en paiement à la livraison."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if order.payment_status == Order.PaymentStatus.PAID:
            return Response(
                {"detail": "Commande déjà payée."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if order.status == Order.Status.CANCELLED:
            return Response(
                {"detail": "Commande annulée."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        existing = (
            PaymentIntent.objects.filter(
                order=order,
                status__in=(
                    PaymentIntent.Status.PROCESSING,
                    PaymentIntent.Status.PAID,
                ),
            )
            .order_by("-created_at")
            .first()
        )
        if existing is not None:
            return Response(PaymentIntentSerializer(existing).data)

        provider_map = {
            Order.Payment.WAVE: PaymentIntent.Provider.WAVE,
            Order.Payment.ORANGE_MONEY: PaymentIntent.Provider.ORANGE_MONEY,
            Order.Payment.FREE_MONEY: PaymentIntent.Provider.MOCK,
        }
        provider = provider_map.get(order.payment_method, PaymentIntent.Provider.MOCK)

        intent = PaymentIntent.objects.create(
            order=order,
            provider=provider,
            amount=order.total,
        )
        result = initiate_payment(intent)
        intent.external_id = result.external_id
        intent.checkout_url = result.checkout_url
        intent.status = result.status
        intent.save(update_fields=["external_id", "checkout_url", "status", "updated_at"])

        order.payment_status = Order.PaymentStatus.PROCESSING
        order.save(update_fields=["payment_status"])

        return Response(PaymentIntentSerializer(intent).data)


class PaymentStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        intent = get_object_or_404(
            PaymentIntent.objects.select_related("order"),
            pk=pk,
            order__customer=request.user,
        )
        return Response(PaymentIntentSerializer(intent).data)


class MockPaymentCompleteView(APIView):
    """Dev/simulated payment completion page (redirect target)."""

    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        if not settings.DEBUG:
            return Response(
                {"detail": "Non disponible."},
                status=status.HTTP_404_NOT_FOUND,
            )
        intent = get_object_or_404(PaymentIntent, pk=pk)
        mark_intent_paid(intent)
        order = intent.order
        return Response(
            {
                "ok": True,
                "message": "Paiement simulé confirmé.",
                "order_id": order.id,
                "payment_status": order.payment_status,
            }
        )


class WaveWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        secret = request.headers.get("X-Wave-Signature", "")
        if not verify_webhook_secret("wave", secret):
            return Response({"detail": "Signature invalide."}, status=403)
        external_id = request.data.get("id") or request.data.get("external_id")
        intent = PaymentIntent.objects.filter(external_id=external_id).first()
        if intent is None:
            return Response({"detail": "Intent introuvable."}, status=404)
        mark_intent_paid(intent)
        return Response({"ok": True})


class OrangeWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        secret = request.headers.get("X-Orange-Signature", "")
        if not verify_webhook_secret("orange_money", secret):
            return Response({"detail": "Signature invalide."}, status=403)
        external_id = request.data.get("transaction_id") or request.data.get(
            "external_id"
        )
        intent = PaymentIntent.objects.filter(external_id=external_id).first()
        if intent is None:
            return Response({"detail": "Intent introuvable."}, status=404)
        mark_intent_paid(intent)
        return Response({"ok": True})
