"""Shared order business rules (delivery fees, promos, fulfillment)."""

from math import asin, cos, radians, sin, sqrt

from rest_framework import serializers

from catalog.models import Meal

from .models import Order, PromoCode


def haversine_km(lat1, lng1, lat2, lng2):
    r = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lng = radians(lng2 - lng1)
    a = (
        sin(d_lat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lng / 2) ** 2
    )
    return 2 * r * asin(sqrt(a))


ALLOWED_STATUS_TRANSITIONS = {
    Order.Status.PENDING: {Order.Status.PREPARING, Order.Status.CANCELLED},
    Order.Status.PREPARING: {Order.Status.ON_THE_WAY, Order.Status.CANCELLED},
    Order.Status.ON_THE_WAY: {Order.Status.DELIVERED, Order.Status.CANCELLED},
    Order.Status.DELIVERED: set(),
    Order.Status.CANCELLED: set(),
}


def sellers_from_meals(meals, customer_id):
    sellers = set()
    for meal in meals.values():
        if meal.seller_id and meal.seller_id != customer_id:
            sellers.add(meal.seller)
    return sellers


def subtotal_by_seller(items_data, meals):
    """Returns {seller_id: subtotal} for items in the cart."""
    totals = {}
    for item in items_data:
        meal = meals[item["meal"]]
        seller_id = meal.seller_id or 0
        totals[seller_id] = totals.get(seller_id, 0) + (
            meal.effective_price * item["quantity"]
        )
    return totals


def _seller_fee(profile, seller_subtotal, lat, lng):
    if profile is None:
        return 0
    if profile.free_delivery_over and seller_subtotal >= profile.free_delivery_over:
        return 0
    fee = profile.delivery_fee_base
    if (
        lat is not None
        and lng is not None
        and profile.latitude is not None
        and profile.longitude is not None
    ):
        km = haversine_km(lat, lng, profile.latitude, profile.longitude)
        if profile.delivery_radius_km and km > profile.delivery_radius_km:
            shop = profile.shop_name or "ce vendeur"
            raise serializers.ValidationError(
                {
                    "latitude": (
                        f"Hors zone de livraison pour {shop} "
                        f"(max {profile.delivery_radius_km} km, "
                        f"distance {km:.1f} km)."
                    )
                }
            )
        fee += int(round(km)) * profile.delivery_fee_per_km
    return fee


def compute_delivery_fee(sellers, seller_subtotals, lat, lng):
    fee = 0
    for seller in sellers:
        profile = getattr(seller, "seller_profile", None)
        subtotal = seller_subtotals.get(seller.id, 0)
        fee += _seller_fee(profile, subtotal, lat, lng)
    return fee


def validate_fulfillment(fulfillment, sellers, address, phone, lat, lng):
    errors = {}
    if fulfillment == Order.Fulfillment.DELIVERY:
        if not address.strip():
            errors["address"] = "L'adresse de livraison est obligatoire."
        if not phone.strip():
            errors["phone"] = "Le téléphone est obligatoire pour la livraison."
        for seller in sellers:
            profile = getattr(seller, "seller_profile", None)
            if profile and not profile.accepts_delivery:
                shop = profile.shop_name or seller.name
                errors.setdefault("fulfillment", []).append(
                    f"{shop} n'accepte pas la livraison."
                )
        if lat is None or lng is None:
            errors.setdefault("latitude", []).append(
                "La position GPS est requise pour calculer la livraison."
            )
    elif fulfillment == Order.Fulfillment.PICKUP:
        for seller in sellers:
            profile = getattr(seller, "seller_profile", None)
            if profile and not profile.accepts_pickup:
                shop = profile.shop_name or seller.name
                errors.setdefault("fulfillment", []).append(
                    f"{shop} n'accepte pas le retrait sur place."
                )
    if errors:
        raise serializers.ValidationError(errors)


def resolve_promo(code, subtotal, sellers):
    """Returns (discount, promo_code_str) or raises ValidationError."""
    code = (code or "").strip()
    if not code:
        return 0, ""
    promo = PromoCode.objects.filter(code__iexact=code).first()
    if promo is None:
        raise serializers.ValidationError(
            {"promo_code": "Code promo invalide ou expiré."}
        )
    if not promo.active:
        raise serializers.ValidationError(
            {"promo_code": "Ce code promo n'est plus actif."}
        )
    if promo.seller_id:
        seller_ids = {s.id for s in sellers}
        if promo.seller_id not in seller_ids:
            raise serializers.ValidationError(
                {"promo_code": "Ce code promo ne s'applique pas à cette commande."}
            )
    discount = promo.discount_for(subtotal)
    if discount <= 0:
        raise serializers.ValidationError(
            {
                "promo_code": (
                    f"Minimum {promo.min_total} FCFA requis pour ce code promo."
                )
            }
        )
    return discount, promo.code
