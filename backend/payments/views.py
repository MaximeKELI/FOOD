import json

import stripe
from django.conf import settings
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from orders.models import Order

from .models import PaymentIntent
from .providers import get_provider, initiate_payment, verify_webhook_secret
from .serializers import PaymentIntentSerializer, StripeCreateSerializer
from .services import mark_intent_paid


def _payment_return_html(intent_id: str, *, error: bool = False) -> HttpResponse:
    """Redirect mobile browser back to the app after Wave/Orange checkout."""
    deep = f"food://payment?intent={intent_id}"
    if error:
        deep += "&error=1"
    html = (
        "<!DOCTYPE html><html><head>"
        f'<meta http-equiv="refresh" content="0;url={deep}">'
        "</head><body>"
        "<p>Retour à l'application…</p>"
        f'<a href="{deep}">Ouvrir Chez Mama</a>'
        "</body></html>"
    )
    return HttpResponse(html)


class PaymentInitiateView(APIView):
    """Starts a mobile-money payment for an existing order."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        tags=["payments"],
        request={"application/json": {"type": "object", "properties": {"order_id": {"type": "integer"}}}},
        responses={200: PaymentIntentSerializer},
    )
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
            Order.Payment.FREE_MONEY: PaymentIntent.Provider.WAVE,
        }
        provider = provider_map.get(order.payment_method)
        if not provider:
            return Response(
                {"detail": "Méthode de paiement non prise en charge."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return _create_and_initiate(order, provider)


class StripeCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        tags=["payments"],
        request=StripeCreateSerializer,
        responses={200: PaymentIntentSerializer},
    )
    def post(self, request):
        ser = StripeCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        order = get_object_or_404(
            Order, pk=ser.validated_data["order_id"], customer=request.user
        )
        if order.payment_status == Order.PaymentStatus.PAID:
            return Response(
                {"detail": "Commande déjà payée."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        order.payment_method = Order.Payment.STRIPE
        order.save(update_fields=["payment_method"])
        return _create_and_initiate(order, PaymentIntent.Provider.STRIPE)


def _create_and_initiate(order: Order, provider: str) -> Response:
    intent = PaymentIntent.objects.create(
        order=order,
        provider=provider,
        amount=order.total,
    )
    try:
        result = initiate_payment(intent)
    except ValueError as exc:
        intent.status = PaymentIntent.Status.FAILED
        intent.save(update_fields=["status", "updated_at"])
        return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

    intent.external_id = result.external_id
    intent.checkout_url = result.checkout_url
    intent.client_secret = result.client_secret
    intent.status = result.status
    intent.metadata = {
        "publishable_key": result.publishable_key,
    }
    intent.save(
        update_fields=[
            "external_id",
            "checkout_url",
            "client_secret",
            "status",
            "metadata",
            "updated_at",
        ]
    )
    order.payment_status = Order.PaymentStatus.PROCESSING
    order.save(update_fields=["payment_status"])
    data = PaymentIntentSerializer(intent).data
    if result.publishable_key:
        data["publishable_key"] = result.publishable_key
    if result.client_secret:
        data["client_secret"] = result.client_secret
    return Response(data)


class PaymentStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(tags=["payments"], responses={200: PaymentIntentSerializer})
    def get(self, request, pk):
        intent = get_object_or_404(
            PaymentIntent.objects.select_related("order"),
            pk=pk,
            order__customer=request.user,
        )
        return Response(PaymentIntentSerializer(intent).data)


class StripeWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        payload = request.body
        sig = request.headers.get("Stripe-Signature", "")
        secret = settings.STRIPE_WEBHOOK_SECRET
        if not secret:
            if not settings.DEBUG:
                return Response(status=403)
            event_data = json.loads(payload)
        else:
            try:
                event = stripe.Webhook.construct_event(payload, sig, secret)
            except (ValueError, stripe.error.SignatureVerificationError):
                return Response({"detail": "Signature invalide."}, status=403)
            event_data = event

        event_type = event_data.get("type") if isinstance(event_data, dict) else event_data.type
        data_obj = (
            event_data.get("data", {}).get("object", {})
            if isinstance(event_data, dict)
            else event_data.data.object
        )
        if event_type == "payment_intent.succeeded":
            external_id = data_obj.get("id") if isinstance(data_obj, dict) else data_obj.id
            intent = PaymentIntent.objects.filter(external_id=external_id).first()
            if intent:
                mark_intent_paid(intent)
        return Response({"ok": True})


class WaveWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        secret = request.headers.get("X-Wave-Signature", "")
        if not verify_webhook_secret(PaymentIntent.Provider.WAVE, secret):
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
        if not verify_webhook_secret(PaymentIntent.Provider.ORANGE_MONEY, secret):
            return Response({"detail": "Signature invalide."}, status=403)
        external_id = request.data.get("transaction_id") or request.data.get(
            "external_id"
        )
        intent = PaymentIntent.objects.filter(external_id=external_id).first()
        if intent is None:
            return Response({"detail": "Intent introuvable."}, status=404)
        mark_intent_paid(intent)
        return Response({"ok": True})


@extend_schema(tags=["payments"], exclude=True)
class WaveReturnView(APIView):
    """Browser return URL after Wave checkout (deep-links back to the app)."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        intent_id = request.query_params.get("intent", "")
        error = request.query_params.get("error") == "1"
        return _payment_return_html(intent_id, error=error)


@extend_schema(tags=["payments"], exclude=True)
class OrangeReturnView(APIView):
    """Browser return URL after Orange Money checkout."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        intent_id = request.query_params.get("intent", "")
        error = (
            request.query_params.get("error") == "1"
            or request.query_params.get("cancel") == "1"
        )
        return _payment_return_html(intent_id, error=error)
