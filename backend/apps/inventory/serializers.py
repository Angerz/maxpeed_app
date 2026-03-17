import os
from decimal import Decimal, ROUND_HALF_UP

from rest_framework import serializers

from apps.catalog.choices import (
    LetterColor,
    Origin,
    PlyRating,
    RimDiameter,
    RimHoles,
    RimMaterial,
    RimWidthIn,
    TireType,
    TreadType,
)
from apps.catalog.models import Brand, TireSpec
from apps.images.serializers import ImageRefSerializer
from apps.inventory.models import Owner


DATETIME_DISPLAY_FORMAT = "%d/%m/%Y %H:%M:%S"


class StockReceiptCreateSerializer(serializers.Serializer):
    tire_type = serializers.ChoiceField(choices=TireType.choices)
    brand_id = serializers.PrimaryKeyRelatedField(
        source="brand",
        queryset=Brand.objects.all(),
    )
    owner_id = serializers.PrimaryKeyRelatedField(
        source="owner",
        queryset=Owner.objects.filter(is_active=True),
        required=False,
        allow_null=True,
    )
    rim_diameter = serializers.ChoiceField(choices=RimDiameter.choices)
    origin = serializers.ChoiceField(choices=Origin.choices)
    ply_rating = serializers.ChoiceField(choices=PlyRating.choices)
    tread_type = serializers.ChoiceField(choices=TreadType.choices)
    letter_color = serializers.ChoiceField(choices=LetterColor.choices)
    width = serializers.IntegerField(min_value=1)
    aspect_ratio = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    quantity = serializers.IntegerField(min_value=1)
    unit_purchase_price = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=Decimal("0.01"))
    recommended_sale_price = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.01"),
        required=False,
        allow_null=True,
    )
    model = serializers.CharField(required=False, allow_blank=True, allow_null=True, max_length=120)

    def validate_model(self, value):
        if value is None:
            return None
        value = value.strip()
        return value or None

    def validate(self, attrs):
        tire_type = attrs["tire_type"]
        aspect_ratio = attrs.get("aspect_ratio")

        if tire_type in TireSpec.ASPECT_RATIO_REQUIRED_TYPES and aspect_ratio is None:
            raise serializers.ValidationError(
                {"aspect_ratio": "Aspect ratio is required for the selected tire type."}
            )

        if tire_type in {TireType.CARGO, TireType.CONVENTIONAL} and aspect_ratio is not None:
            raise serializers.ValidationError(
                {"aspect_ratio": "Aspect ratio must be omitted for the selected tire type."}
            )

        if attrs.get("recommended_sale_price") is None:
            attrs["recommended_sale_price"] = (
                attrs["unit_purchase_price"] * Decimal("1.30")
            ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        if attrs.get("owner") is None:
            attrs["owner"] = Owner.objects.filter(name__iexact="Maxpeed").first() or Owner.objects.order_by("id").first()
            if attrs["owner"] is None:
                raise serializers.ValidationError({"owner_id": "No owners configured in the system."})

        return attrs


class CurrentPricesSerializer(serializers.Serializer):
    purchase = serializers.DecimalField(max_digits=12, decimal_places=2)
    suggested_sale = serializers.DecimalField(max_digits=12, decimal_places=2)


class StockReceiptCreateResponseSerializer(serializers.Serializer):
    receipt_id = serializers.IntegerField()
    catalog_item_id = serializers.IntegerField()
    inventory_item_id = serializers.IntegerField()
    stock_after = serializers.IntegerField()
    prices_current = CurrentPricesSerializer()
    created_new_catalog_item = serializers.BooleanField()


class InventoryOwnerSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class InventoryCardSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    code = serializers.CharField(allow_null=True)
    brand = serializers.CharField(allow_null=True)
    stock = serializers.IntegerField()
    details = serializers.CharField()
    owner = InventoryOwnerSerializer()
    image = ImageRefSerializer(allow_null=True)
    image_thumb = ImageRefSerializer(allow_null=True)


class InventoryDetailSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    code = serializers.CharField(allow_null=True)
    tire_type = serializers.CharField(allow_null=True)
    brand = serializers.CharField(allow_null=True)
    stock = serializers.IntegerField()
    owner = InventoryOwnerSerializer()
    details = serializers.CharField()
    purchase_price = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True)
    suggested_sale_price = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True)
    last_restock_at = serializers.DateTimeField(allow_null=True, format=DATETIME_DISPLAY_FORMAT)
    created_at = serializers.DateTimeField(allow_null=True, format=DATETIME_DISPLAY_FORMAT)
    updated_at = serializers.DateTimeField(allow_null=True, format=DATETIME_DISPLAY_FORMAT)
    image = ImageRefSerializer(allow_null=True)
    image_thumb = ImageRefSerializer(allow_null=True)


class RestockSerializer(serializers.Serializer):
    quantity = serializers.IntegerField(min_value=1)
    unit_purchase_price = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.01"),
    )
    suggested_sale_price = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.01"),
        required=False,
        allow_null=True,
    )
    notes = serializers.CharField(required=False, allow_blank=True, allow_null=True, max_length=1000)

    def validate(self, attrs):
        if attrs.get("suggested_sale_price") is None:
            attrs["suggested_sale_price"] = (
                attrs["unit_purchase_price"] * Decimal("1.30")
            ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        return attrs


class RestockResponseSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    stock_before = serializers.IntegerField()
    stock_after = serializers.IntegerField()
    purchase_price_current = serializers.DecimalField(max_digits=12, decimal_places=2)
    suggested_sale_price_current = serializers.DecimalField(max_digits=12, decimal_places=2)
    receipt_id = serializers.IntegerField()
    receipt_line_id = serializers.IntegerField()
    movement_id = serializers.IntegerField()
    last_restock_at = serializers.DateTimeField(allow_null=True)


class RimReceiptCreateSerializer(serializers.Serializer):
    owner_id = serializers.PrimaryKeyRelatedField(
        source="owner",
        queryset=Owner.objects.filter(is_active=True),
        required=False,
        allow_null=True,
    )
    brand_id = serializers.PrimaryKeyRelatedField(
        source="brand",
        queryset=Brand.objects.all(),
    )
    internal_code = serializers.CharField(max_length=64)
    rim_diameter = serializers.ChoiceField(choices=RimDiameter.choices)
    holes = serializers.ChoiceField(choices=RimHoles.choices)
    width_in = serializers.ChoiceField(choices=RimWidthIn.choices)
    material = serializers.ChoiceField(choices=RimMaterial.choices)
    is_set = serializers.BooleanField()
    quantity = serializers.IntegerField(min_value=1)
    unit_purchase_price = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=Decimal("0.01"))
    suggested_sale_price = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.01"),
        required=False,
        allow_null=True,
    )
    notes = serializers.CharField(required=False, allow_blank=True, allow_null=True, max_length=1000)
    rim_photo = serializers.FileField(required=False, allow_null=True)

    def validate_rim_photo(self, value):
        if value is None:
            return None
        allowed_mimes = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
        content_type = (value.content_type or "").lower()
        if content_type not in allowed_mimes:
            raise serializers.ValidationError("Unsupported image type. Use jpg/jpeg, png, or webp.")
        max_size = int(os.getenv("MAX_IMAGE_SIZE_BYTES", 5 * 1024 * 1024))
        if value.size > max_size:
            raise serializers.ValidationError(f"Image too large. Max {max_size} bytes.")
        return value

    def validate_internal_code(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("internal_code is required.")
        return value

    def validate(self, attrs):
        if attrs.get("suggested_sale_price") is None:
            attrs["suggested_sale_price"] = (
                attrs["unit_purchase_price"] * Decimal("1.30")
            ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        if attrs.get("owner") is None:
            attrs["owner"] = Owner.objects.filter(name__iexact="Maxpeed").first() or Owner.objects.order_by("id").first()
            if attrs["owner"] is None:
                raise serializers.ValidationError({"owner_id": "No owners configured in the system."})
        return attrs


class RimReceiptCreateResponseSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    catalog_item_id = serializers.IntegerField()
    created_new_catalog_item = serializers.BooleanField()
    stock_after = serializers.IntegerField()
    prices_current = CurrentPricesSerializer()
    receipt_id = serializers.IntegerField()
    receipt_line_id = serializers.IntegerField()
    movement_id = serializers.IntegerField()


class RimInventoryCardSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    internal_code = serializers.CharField()
    brand = serializers.CharField(allow_null=True)
    stock = serializers.IntegerField()
    details = serializers.CharField()
    owner = InventoryOwnerSerializer()
    image = ImageRefSerializer(allow_null=True)
    image_thumb = ImageRefSerializer(allow_null=True)


class RimDeactivateSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, allow_null=True, max_length=255)
    notes = serializers.CharField(required=False, allow_blank=True, allow_null=True, max_length=1000)


class RimDeactivateResponseSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    is_active = serializers.BooleanField()
    deactivated_at = serializers.DateTimeField(allow_null=True)
    owner = InventoryOwnerSerializer()
    message = serializers.CharField()
