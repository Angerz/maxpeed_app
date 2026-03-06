from rest_framework import status
from rest_framework.generics import RetrieveAPIView
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .services import get_inventory_cards_grouped_by_rim, get_inventory_item_detail_payload
from .services.restock import RestockConflictError, restock_inventory_item
from .models import InventoryItem
from .serializers import (
    InventoryCardSerializer,
    InventoryDetailSerializer,
    RestockResponseSerializer,
    RestockSerializer,
    StockReceiptCreateResponseSerializer,
    StockReceiptCreateSerializer,
)
from .stock_receipts import create_tire_stock_receipt


class StockReceiptCreateAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = StockReceiptCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user if getattr(request.user, "is_authenticated", False) else None
        result = create_tire_stock_receipt(
            payload=serializer.validated_data,
            user=user,
        )

        response_serializer = StockReceiptCreateResponseSerializer(result)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class InventoryItemListAPIView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, *args, **kwargs):
        include_zero_stock = str(request.query_params.get("include_zero_stock", "false")).lower() == "true"
        grouped = get_inventory_cards_grouped_by_rim(include_zero_stock=include_zero_stock)
        response_data = {
            rim: InventoryCardSerializer(cards, many=True).data
            for rim, cards in grouped.items()
        }
        return Response(response_data)


class InventoryItemDetailAPIView(RetrieveAPIView):
    permission_classes = [AllowAny]
    queryset = InventoryItem.objects.select_related(
        "catalog_item",
        "catalog_item__brand",
        "catalog_item__tire_spec",
        "owner",
    )
    lookup_url_kwarg = "inventory_item_id"
    serializer_class = InventoryDetailSerializer

    def retrieve(self, request, *args, **kwargs):
        inventory_item = self.get_object()
        payload = get_inventory_item_detail_payload(inventory_item)
        serializer = self.get_serializer(payload)
        return Response(serializer.data)


class InventoryItemRestockAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, inventory_item_id, *args, **kwargs):
        serializer = RestockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user if getattr(request.user, "is_authenticated", False) else None

        try:
            payload = restock_inventory_item(
                inventory_item_id=inventory_item_id,
                quantity=serializer.validated_data["quantity"],
                unit_purchase_price=serializer.validated_data["unit_purchase_price"],
                suggested_sale_price=serializer.validated_data["suggested_sale_price"],
                notes=serializer.validated_data.get("notes"),
                user=user,
            )
        except RestockConflictError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)

        if payload is None:
            return Response({"detail": "Inventory item not found."}, status=status.HTTP_404_NOT_FOUND)

        response_serializer = RestockResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
