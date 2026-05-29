"""Upload validation helpers shared across apps."""

from rest_framework import serializers

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/webm", "video/quicktime"}
MAX_IMAGE_BYTES = 5 * 1024 * 1024
MAX_VIDEO_BYTES = 50 * 1024 * 1024
MIN_VIDEO_BYTES = 1024


def validate_image_upload(file):
    if file is None:
        return
    content_type = getattr(file, "content_type", "") or ""
    if content_type and content_type not in ALLOWED_IMAGE_TYPES:
        raise serializers.ValidationError(
            "Format d'image non supporté (jpeg, png, webp, gif)."
        )
    if file.size > MAX_IMAGE_BYTES:
        raise serializers.ValidationError(
            f"Image trop volumineuse (max {MAX_IMAGE_BYTES // (1024 * 1024)} Mo)."
        )


def validate_video_upload(file):
    if file is None:
        return
    if file.size < MIN_VIDEO_BYTES:
        raise serializers.ValidationError(
            "Fichier vidéo invalide ou trop petit. Utilise un vrai fichier mp4."
        )
    content_type = getattr(file, "content_type", "") or ""
    if content_type and content_type not in ALLOWED_VIDEO_TYPES:
        raise serializers.ValidationError(
            "Format vidéo non supporté (mp4, webm, mov)."
        )
    if file.size > MAX_VIDEO_BYTES:
        raise serializers.ValidationError(
            f"Vidéo trop volumineuse (max {MAX_VIDEO_BYTES // (1024 * 1024)} Mo)."
        )
