import hashlib
import io
from uuid import uuid4

from PIL import Image, ImageOps
from rest_framework.exceptions import ValidationError

from .models import ImageAsset, ImageVariant


ALLOWED_IMAGE_MIME_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
DEFAULT_MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024
FULL_MAX_SIDE = 1200
THUMB_MAX_SIDE = 500


def _normalize_and_resize(image_bytes, max_side):
    with Image.open(io.BytesIO(image_bytes)) as img:
        img = ImageOps.exif_transpose(img).convert("RGB")
        img.thumbnail((max_side, max_side))
        output = io.BytesIO()
        img.save(output, format="WEBP", quality=80 if max_side == FULL_MAX_SIDE else 75, method=6)
        return output.getvalue(), "image/webp"


def _create_image_asset(*, kind, variant, group_key, mime_type, binary):
    return ImageAsset.objects.create(
        kind=kind,
        variant=variant,
        group_key=group_key,
        mime_type=mime_type,
        data=binary,
        sha256=hashlib.sha256(binary).hexdigest(),
        size_bytes=len(binary),
    )


def create_image_variants_from_upload(*, uploaded_file, kind, max_size_bytes=DEFAULT_MAX_IMAGE_SIZE_BYTES):
    mime_type = (uploaded_file.content_type or "").lower()
    if mime_type not in ALLOWED_IMAGE_MIME_TYPES:
        raise ValidationError({"file": "Unsupported file type. Use jpg/jpeg, png, or webp."})
    if uploaded_file.size > max_size_bytes:
        raise ValidationError({"file": f"Image too large. Max {max_size_bytes} bytes."})

    source = uploaded_file.read()
    group_key = uuid4()
    full_binary, full_mime = _normalize_and_resize(source, FULL_MAX_SIDE)
    thumb_binary, thumb_mime = _normalize_and_resize(source, THUMB_MAX_SIDE)

    full = _create_image_asset(
        kind=kind,
        variant=ImageVariant.FULL,
        group_key=group_key,
        mime_type=full_mime,
        binary=full_binary,
    )
    thumb = _create_image_asset(
        kind=kind,
        variant=ImageVariant.THUMB,
        group_key=group_key,
        mime_type=thumb_mime,
        binary=thumb_binary,
    )
    return full, thumb


def create_thumb_variant_from_full(*, image_asset):
    if image_asset is None:
        return None
    if image_asset.variant == ImageVariant.THUMB:
        return image_asset

    thumb_binary, thumb_mime = _normalize_and_resize(image_asset.data, THUMB_MAX_SIDE)
    return _create_image_asset(
        kind=image_asset.kind,
        variant=ImageVariant.THUMB,
        group_key=image_asset.group_key,
        mime_type=thumb_mime,
        binary=thumb_binary,
    )
