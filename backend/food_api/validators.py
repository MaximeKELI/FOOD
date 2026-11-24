"""Upload validation helpers shared across apps."""

from rest_framework import serializers

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/webm", "video/quicktime"}
ALLOWED_IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".webp", ".gif")
ALLOWED_VIDEO_EXTS = (".mp4", ".webm", ".mov", ".m4v")
MAX_IMAGE_BYTES = 5 * 1024 * 1024
MAX_VIDEO_BYTES = 50 * 1024 * 1024
MIN_VIDEO_BYTES = 1024

_JPEG = (b"\xff\xd8\xff",)
_PNG = (b"\x89PNG\r\n\x1a\n",)
_GIF = (b"GIF87a", b"GIF89a")
_WEBP_RIFF = b"RIFF"
_WEBP_WEBP = b"WEBP"
_MP4_FTYP = b"ftyp"
_WEBM = b"\x1a\x45\xdf\xa3"


def _name_ext(file) -> str:
    name = (getattr(file, "name", "") or "").lower()
    for ext in ALLOWED_IMAGE_EXTS + ALLOWED_VIDEO_EXTS:
        if name.endswith(ext):
            return ext
    return ""


def _read_header(file, size: int = 32) -> bytes:
    pos = file.tell() if hasattr(file, "tell") else None
    header = file.read(size) or b""
    if hasattr(file, "seek"):
        if pos is not None:
            file.seek(pos)
        else:
            file.seek(0)
    return header


def _looks_like_image(header: bytes) -> bool:
    if any(header.startswith(sig) for sig in _JPEG + _PNG + _GIF):
        return True
    if len(header) >= 12 and header.startswith(_WEBP_RIFF) and header[8:12] == _WEBP_WEBP:
        return True
    return False


def _looks_like_video(header: bytes) -> bool:
    if _WEBM in header[:4] or header.startswith(_WEBM):
        return True
    # ISO BMFF (mp4/mov): bytes 4..8 often "ftyp"
    if len(header) >= 8 and header[4:8] == _MP4_FTYP:
        return True
    return False


def validate_image_upload(file):
    if file is None:
        return
    content_type = getattr(file, "content_type", "") or ""
    ext = _name_ext(file)
    if content_type:
        if content_type not in ALLOWED_IMAGE_TYPES:
            raise serializers.ValidationError(
                "Format d'image non supporté (jpeg, png, webp, gif)."
            )
    elif ext not in ALLOWED_IMAGE_EXTS:
        raise serializers.ValidationError(
            "Format d'image non supporté (jpeg, png, webp, gif)."
        )
    if file.size > MAX_IMAGE_BYTES:
        raise serializers.ValidationError(
            f"Image trop volumineuse (max {MAX_IMAGE_BYTES // (1024 * 1024)} Mo)."
        )
    header = _read_header(file)
    if not _looks_like_image(header):
        raise serializers.ValidationError("Fichier image invalide (contenu non reconnu).")


def validate_video_upload(file):
    if file is None:
        return
    if file.size < MIN_VIDEO_BYTES:
        raise serializers.ValidationError(
            "Fichier vidéo invalide ou trop petit. Utilise un vrai fichier mp4."
        )
    content_type = getattr(file, "content_type", "") or ""
    ext = _name_ext(file)
    if content_type:
        if content_type not in ALLOWED_VIDEO_TYPES:
            raise serializers.ValidationError(
                "Format vidéo non supporté (mp4, webm, mov)."
            )
    elif ext not in ALLOWED_VIDEO_EXTS:
        raise serializers.ValidationError(
            "Format vidéo non supporté (mp4, webm, mov)."
        )
    if file.size > MAX_VIDEO_BYTES:
        raise serializers.ValidationError(
            f"Vidéo trop volumineuse (max {MAX_VIDEO_BYTES // (1024 * 1024)} Mo)."
        )
    header = _read_header(file)
    if not _looks_like_video(header):
        raise serializers.ValidationError("Fichier vidéo invalide (contenu non reconnu).")


def validate_story_media(file):
    """Stories accept image or short video."""
    if file is None:
        raise serializers.ValidationError("Média requis.")
    content_type = getattr(file, "content_type", "") or ""
    ext = _name_ext(file)
    is_image = content_type in ALLOWED_IMAGE_TYPES or ext in ALLOWED_IMAGE_EXTS
    is_video = content_type in ALLOWED_VIDEO_TYPES or ext in ALLOWED_VIDEO_EXTS
    if is_video and not is_image:
        validate_video_upload(file)
    else:
        validate_image_upload(file)
