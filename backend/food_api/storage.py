"""S3/MinIO media URL helpers (django-storages)."""

from django.conf import settings
from django.core.files.storage import default_storage


def media_url(name: str, *, signed: bool | None = None) -> str:
    """
    Return a public or presigned URL for a stored media object.

    When USE_S3 is enabled, signed URLs are used when AWS_QUERYSTRING_AUTH is True.
    """
    if not name:
        return ""
    if signed is None:
        signed = getattr(settings, "AWS_QUERYSTRING_AUTH", False)
    if signed and hasattr(default_storage, "url"):
        return default_storage.url(name)
    return default_storage.url(name)
