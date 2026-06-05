"""Business logic for recording analytics events and order context."""

from __future__ import annotations

import uuid
from typing import Any

from django.db.models import F

from .models import AnalyticsEvent, ClientSession, OrderContext
from .utils import extract_context_fields


def _event_type_from_name(name: str) -> str:
    if name == "screen_view":
        return AnalyticsEvent.EventType.SCREEN_VIEW
    if name in ("tap", "click"):
        return AnalyticsEvent.EventType.TAP
    if name == "order":
        return AnalyticsEvent.EventType.ORDER
    if "click" in name or "tap" in name:
        return AnalyticsEvent.EventType.CLICK
    return AnalyticsEvent.EventType.OTHER


def parse_session_id(session_id: str | None) -> uuid.UUID:
    """Accept UUID or any stable string (e.g. Flutter session id)."""
    if not session_id:
        return uuid.uuid4()
    try:
        return uuid.UUID(str(session_id))
    except ValueError:
        return uuid.uuid5(uuid.NAMESPACE_DNS, str(session_id))


def get_or_create_session(
    *,
    user,
    session_id: str | None,
    context: dict[str, Any],
    request=None,
) -> ClientSession:
    sid = session_id or str(uuid.uuid4())
    parsed = parse_session_id(sid)

    fields = extract_context_fields(context, request)
    session, created = ClientSession.objects.get_or_create(
        session_id=parsed,
        defaults={
            "user": user if user and user.is_authenticated else None,
            "ip_address": fields.get("ip_address"),
            "platform": fields.get("platform", ""),
            "device_model": fields.get("device_model", ""),
            "app_version": fields.get("app_version", ""),
            "city": fields.get("city", ""),
            "country": fields.get("country", ""),
            "region": fields.get("region", ""),
            "last_latitude": fields.get("latitude"),
            "last_longitude": fields.get("longitude"),
            "timezone": fields.get("timezone", ""),
            "event_count": 1,
        },
    )

    if not created:
        update_fields = ["last_seen"]
        session.event_count = F("event_count") + 1
        if user and user.is_authenticated and not session.user_id:
            session.user = user
            update_fields.append("user")
        for field, key in [
            ("last_latitude", "latitude"),
            ("last_longitude", "longitude"),
            ("city", "city"),
            ("country", "country"),
            ("region", "region"),
            ("platform", "platform"),
            ("device_model", "device_model"),
            ("app_version", "app_version"),
            ("timezone", "timezone"),
            ("ip_address", "ip_address"),
        ]:
            val = fields.get(key)
            if val:
                setattr(session, field, val)
                update_fields.append(field)
        session.save(update_fields=update_fields)
        session.refresh_from_db()

    return session


def record_event(
    *,
    user,
    data: dict[str, Any],
    request=None,
) -> AnalyticsEvent:
    context = {**data}
    if "context" in data and isinstance(data["context"], dict):
        context.update(data["context"])

    session = None
    session_id = data.get("session_id")
    if session_id or context:
        session = get_or_create_session(
            user=user,
            session_id=session_id,
            context=context,
            request=request,
        )

    fields = extract_context_fields(context, request)
    name = (data.get("name") or "unknown").strip()[:120]
    meta = data.get("metadata") or data.get("meta") or {}
    if isinstance(meta, str):
        meta = {"raw": meta}

    event = AnalyticsEvent.objects.create(
        session=session,
        user=user if user and user.is_authenticated else None,
        event_type=data.get("event_type") or _event_type_from_name(name),
        name=name,
        screen=(data.get("screen") or "")[:120],
        element=(data.get("element") or "")[:120],
        ip_address=fields.get("ip_address"),
        latitude=fields.get("latitude"),
        longitude=fields.get("longitude"),
        city=fields.get("city", ""),
        country=fields.get("country", ""),
        region=fields.get("region", ""),
        device_time=fields.get("device_time"),
        timezone=fields.get("timezone", ""),
        brightness=fields.get("brightness"),
        weather_condition=fields.get("weather_condition", ""),
        temperature_c=fields.get("temperature_c"),
        weather_code=fields.get("weather_code"),
        is_sunny=fields.get("is_sunny"),
        cloud_cover=fields.get("cloud_cover"),
        platform=fields.get("platform", ""),
        device_model=fields.get("device_model", ""),
        app_version=fields.get("app_version", ""),
        connection_type=fields.get("connection_type", ""),
        battery_level=fields.get("battery_level"),
        metadata=meta,
    )
    return event


def record_order_context(*, order, data: dict[str, Any], request=None) -> OrderContext:
    fields = extract_context_fields(data, request)
    return OrderContext.objects.create(
        order=order,
        ip_address=fields.get("ip_address"),
        latitude=fields.get("latitude") or order.latitude,
        longitude=fields.get("longitude") or order.longitude,
        city=fields.get("city", ""),
        country=fields.get("country", ""),
        region=fields.get("region", ""),
        device_time=fields.get("device_time"),
        timezone=fields.get("timezone", ""),
        brightness=fields.get("brightness"),
        weather_condition=fields.get("weather_condition", ""),
        temperature_c=fields.get("temperature_c"),
        weather_code=fields.get("weather_code"),
        is_sunny=fields.get("is_sunny"),
        is_rainy=fields.get("is_rainy"),
        cloud_cover=fields.get("cloud_cover"),
        platform=fields.get("platform", ""),
        device_model=fields.get("device_model", ""),
        app_version=fields.get("app_version", ""),
        connection_type=fields.get("connection_type", ""),
        battery_level=fields.get("battery_level"),
    )


def record_content_engagement(
    *,
    user,
    data: dict[str, Any],
    request=None,
) -> ContentEngagement:
    from .models import ContentEngagement

    context = {**data}
    if "context" in data and isinstance(data["context"], dict):
        context.update(data["context"])

    session = None
    session_id = data.get("session_id")
    if session_id or context:
        session = get_or_create_session(
            user=user,
            session_id=session_id,
            context=context,
            request=request,
        )

    fields = extract_context_fields(context, request)
    return ContentEngagement.objects.create(
        user=user if user and user.is_authenticated else None,
        session=session,
        content_type=data["content_type"],
        content_id=data["content_id"],
        content_title=(data.get("content_title") or "")[:200],
        duration_seconds=min(int(data["duration_seconds"]), 86400),
        city=fields.get("city", ""),
        platform=fields.get("platform", ""),
    )
