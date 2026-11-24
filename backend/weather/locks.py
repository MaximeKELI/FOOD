"""Distributed lock helpers for weather cron (Redis when available)."""

from __future__ import annotations

import logging
import uuid
from contextlib import contextmanager

from django.conf import settings

logger = logging.getLogger(__name__)


@contextmanager
def redis_lock(key: str, ttl_seconds: int = 300):
    """
    Best-effort Redis lock. If Redis is unavailable, runs without locking
    (single weather-cron replica is the common local case).
    """
    token = str(uuid.uuid4())
    client = None
    acquired = False
    redis_url = getattr(settings, "REDIS_URL", "") or ""
    if redis_url:
        try:
            import redis

            client = redis.Redis.from_url(redis_url, decode_responses=True)
            acquired = bool(client.set(key, token, nx=True, ex=ttl_seconds))
        except Exception as exc:
            logger.warning("Weather lock unavailable (%s); continuing unlocked.", exc)
            client = None
            acquired = True
    else:
        acquired = True

    try:
        if not acquired:
            yield False
            return
        yield True
    finally:
        if client is not None and acquired:
            try:
                # Release only if we still own the lock.
                current = client.get(key)
                if current == token:
                    client.delete(key)
            except Exception:
                pass
