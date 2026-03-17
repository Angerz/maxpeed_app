import hashlib

from rest_framework.exceptions import ValidationError

from .models import ImageAsset


ALLOWED_IMAGE_MIME_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
DEFAULT_MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024


def create_image_asset_from_upload(*, uploaded_file, kind, max_size_bytes=DEFAULT_MAX_IMAGE_SIZE_BYTES):
    mime_type = (uploaded_file.content_type or "").lower()
    if mime_type not in ALLOWED_IMAGE_MIME_TYPES:
        raise ValidationError({"file": "Unsupported file type. Use jpeg, png, or webp."})

    if uploaded_file.size > max_size_bytes:
        raise ValidationError({"file": f"Image too large. Max {max_size_bytes} bytes."})

    binary = uploaded_file.read()
    sha256 = hashlib.sha256(binary).hexdigest()
    return ImageAsset.objects.create(
        kind=kind,
        mime_type=mime_type,
        data=binary,
        sha256=sha256,
        size_bytes=len(binary),
    )
