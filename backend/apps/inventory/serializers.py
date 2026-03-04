from decimal import Decimal, ROUND_HALF_UP

from rest_framework import serializers

from apps.catalog.choices import (
    LetterColor,
    Origin,
    PlyRating,
    RimDiameter,
    TireType,
    TreadType,
)
from apps.catalog.models import Brand, TireSpec


class StockReceiptCreateSerializer(serializers.Serializer):
    tire_type = serializers.ChoiceField(choices=TireType.choices)
    brand_id = serializers.PrimaryKeyRelatedField(
        source="brand",
        queryset=Brand.objects.all(),
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
