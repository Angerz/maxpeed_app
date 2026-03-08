from decimal import Decimal

from rest_framework import serializers

from apps.sales.models import Sale, SaleLine, SaleLineType


class SaleLineCreateSerializer(serializers.Serializer):
    line_type = serializers.ChoiceField(choices=SaleLineType.choices)
    inventory_item_id = serializers.IntegerField(required=False, allow_null=True)
    quantity = serializers.IntegerField(min_value=1)
    unit_price = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.00"),
        required=False,
        allow_null=True,
    )
    discount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.00"),
        required=False,
        allow_null=True,
    )
    description = serializers.CharField(required=False, allow_blank=True, allow_null=True, max_length=255)
    assessed_value = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.00"),
        required=False,
        allow_null=True,
    )
    tire_condition_percent = serializers.IntegerField(min_value=10, max_value=100, required=False, allow_null=True)
    rim_requires_repair = serializers.BooleanField(required=False, allow_null=True)

    def validate(self, attrs):
        line_type = attrs["line_type"]
        description = (attrs.get("description") or "").strip() or None
        attrs["description"] = description

        if line_type in SaleLineType.inventory_values():
            if attrs.get("inventory_item_id") is None:
                raise serializers.ValidationError({"inventory_item_id": "inventory_item_id is required."})
            if attrs.get("unit_price") is None:
                raise serializers.ValidationError({"unit_price": "unit_price is required."})
            attrs["discount"] = attrs.get("discount") or Decimal("0.00")
            attrs["assessed_value"] = None
            attrs["tire_condition_percent"] = None
            attrs["rim_requires_repair"] = None
            return attrs

        if line_type in SaleLineType.manual_values():
            if not description:
                raise serializers.ValidationError({"description": "description is required."})
            if attrs.get("unit_price") is None:
                raise serializers.ValidationError({"unit_price": "unit_price is required."})
            attrs["inventory_item_id"] = None
            attrs["discount"] = attrs.get("discount") or Decimal("0.00")
            attrs["assessed_value"] = None
            attrs["tire_condition_percent"] = None
            attrs["rim_requires_repair"] = None
            return attrs

        if attrs.get("assessed_value") is None:
            raise serializers.ValidationError({"assessed_value": "assessed_value is required."})

        if line_type == SaleLineType.TRADEIN_TIRE and attrs.get("tire_condition_percent") is None:
            raise serializers.ValidationError(
                {"tire_condition_percent": "tire_condition_percent is required for TRADEIN_TIRE."}
            )
        if line_type == SaleLineType.TRADEIN_RIM and attrs.get("rim_requires_repair") is None:
            raise serializers.ValidationError(
                {"rim_requires_repair": "rim_requires_repair is required for TRADEIN_RIM."}
            )

        attrs["inventory_item_id"] = None
        attrs["unit_price"] = Decimal("0.00")
        attrs["discount"] = Decimal("0.00")
        return attrs


class SaleCreateSerializer(serializers.Serializer):
    sold_at = serializers.DateTimeField(required=False)
    discount_total = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.00"),
        required=False,
    )
    notes = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    lines = SaleLineCreateSerializer(many=True)

    def validate(self, attrs):
        lines = attrs.get("lines") or []
        if not lines:
            raise serializers.ValidationError({"lines": "At least one line is required."})

        has_sellable_line = any(
            line["line_type"] in SaleLineType.inventory_values() | SaleLineType.manual_values()
            for line in lines
        )
        if not has_sellable_line:
            raise serializers.ValidationError(
                {"lines": "Sale requires at least one inventory or service/accessory line."}
            )
        return attrs


class SaleTotalsSerializer(serializers.Serializer):
    subtotal = serializers.DecimalField(max_digits=12, decimal_places=2)
    discount_total = serializers.DecimalField(max_digits=12, decimal_places=2)
    tradein_credit_total = serializers.DecimalField(max_digits=12, decimal_places=2)
    total = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_due = serializers.DecimalField(max_digits=12, decimal_places=2)


class SaleStockUpdateSerializer(serializers.Serializer):
    inventory_item_id = serializers.IntegerField()
    stock_before = serializers.IntegerField()
    stock_after = serializers.IntegerField()


class SaleCreateResponseSerializer(serializers.Serializer):
    sale_id = serializers.IntegerField()
    totals = SaleTotalsSerializer()
    stock_updates = SaleStockUpdateSerializer(many=True)
    status = serializers.CharField()


class SaleListSerializer(serializers.ModelSerializer):
    item_count = serializers.IntegerField(read_only=True)
    created_by = serializers.SerializerMethodField()

    class Meta:
        model = Sale
        fields = (
            "id",
            "sold_at",
            "total_due",
            "total",
            "tradein_credit_total",
            "item_count",
            "created_by",
        )

    def get_created_by(self, obj):
        if not obj.created_by_id:
            return None
        return obj.created_by.get_username()


class SaleSummaryDaySerializer(serializers.Serializer):
    date = serializers.DateField()
    total = serializers.DecimalField(max_digits=12, decimal_places=2)
    sales_count = serializers.IntegerField()


class SaleSummarySerializer(serializers.Serializer):
    start_date = serializers.DateField(allow_null=True)
    end_date = serializers.DateField(allow_null=True)
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    best_day = SaleSummaryDaySerializer(allow_null=True)
    worst_day = SaleSummaryDaySerializer(allow_null=True)


class SaleLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = SaleLine
        fields = (
            "id",
            "line_type",
            "inventory_item_id",
            "quantity",
            "unit_price",
            "discount",
            "line_total",
            "description",
            "code",
            "brand",
            "owner_name",
            "details",
            "assessed_value",
            "tire_condition_percent",
            "rim_requires_repair",
        )


class SaleDetailSerializer(serializers.ModelSerializer):
    lines = SaleLineSerializer(many=True, read_only=True)
    created_by = serializers.SerializerMethodField()

    class Meta:
        model = Sale
        fields = (
            "id",
            "sold_at",
            "status",
            "subtotal",
            "discount_total",
            "tradein_credit_total",
            "total",
            "total_due",
            "notes",
            "created_by",
            "created_at",
            "lines",
        )

    def get_created_by(self, obj):
        if not obj.created_by_id:
            return None
        return obj.created_by.get_username()
