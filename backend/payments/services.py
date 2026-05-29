"""Shared payment completion logic."""

from orders.models import Order

from .models import PaymentIntent


def mark_intent_paid(intent: PaymentIntent) -> bool:
    """Marks intent and order as paid. Returns False if already paid."""
    if intent.status == PaymentIntent.Status.PAID:
        return False
    intent.status = PaymentIntent.Status.PAID
    intent.save(update_fields=["status", "updated_at"])
    order = intent.order
    if order.payment_status != Order.PaymentStatus.PAID:
        order.payment_status = Order.PaymentStatus.PAID
        order.save(update_fields=["payment_status"])
    return True
