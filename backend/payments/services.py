"""Shared payment completion logic."""

from django.db import transaction

from orders.models import Order

from .models import PaymentIntent


@transaction.atomic
def mark_intent_paid(intent: PaymentIntent) -> bool:
    """Marks intent and order as paid. Returns False if already paid."""
    locked = (
        PaymentIntent.objects.select_for_update()
        .select_related("order")
        .filter(pk=intent.pk)
        .first()
    )
    if locked is None:
        return False
    if locked.status == PaymentIntent.Status.PAID:
        return False
    locked.status = PaymentIntent.Status.PAID
    locked.save(update_fields=["status", "updated_at"])
    order = locked.order
    if order.payment_status != Order.PaymentStatus.PAID:
        order.payment_status = Order.PaymentStatus.PAID
        order.save(update_fields=["payment_status"])
    # Keep caller's in-memory instance roughly in sync.
    intent.status = PaymentIntent.Status.PAID
    return True
