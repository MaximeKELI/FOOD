"""Normalize notification copy (no em/en dashes in user-facing text)."""

from __future__ import annotations

import re

_DASHES = ("\u2014", "\u2013", "\u2212")  # — – −


def sanitize_notification_text(value: str) -> str:
    if not value:
        return value
    out = value
    for ch in _DASHES:
        out = out.replace(ch, ", ")
    out = re.sub(r"\s+,\s+", ", ", out)
    out = re.sub(r",\s*,", ",", out)
    return out.strip()
