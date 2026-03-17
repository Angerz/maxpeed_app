import os

from rest_framework import status
from rest_framework.generics import RetrieveAPIView
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import (
    CanCreateStockReceipt,
    CanDeactivateRims,
    CanRestock,
    CanViewInventory,
)
from apps.accounts.permissions import CanViewZeroStock
from apps.images.models import ImageKind
from apps.images.services import create_image_variants_from_upload

from .services import get_inventory_cards_grouped_by_rim, get_inventory_item_detail_payload
from .services.rims import (
    RimDeactivateForbiddenError,
    RimDeactivateValidationError,
    RimSpecConflictError,
    create_rim_stock_receipt,
    deactivate_rim_inventory_item,
    get_rim_inventory_cards_grouped,
)
from .services.restock import RestockConflictError, restock_inventory_item
from .models import InventoryItem
from .serializers import (
    InventoryCardSerializer,
    InventoryDetailSerializer,
    RimInventoryCardSerializer,
    RimDeactivateResponseSerializer,
    RimDeactivateSerializer,
    RimReceiptCreateResponseSerializer,
    RimReceiptCreateSerializer,
    RestockResponseSerializer,
    RestockSerializer,
    StockReceiptCreateResponseSerializer,
    StockReceiptCreateSerializer,
)
from .stock_receipts import create_tire_stock_receipt


class StockReceiptCreateAPIView(APIView):
    permission_classes = [IsAuthenticated, CanCreateStockReceipt]

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
    permission_classes = [IsAuthenticated, CanViewInventory]

    def get(self, request, *args, **kwargs):
        include_zero_stock = str(request.query_params.get("include_zero_stock", "false")).lower() == "true"
        if include_zero_stock and not CanViewZeroStock().has_permission(request, self):
            return Response({"detail": "You do not have permission to view zero stock."}, status=status.HTTP_403_FORBIDDEN)
        grouped = get_inventory_cards_grouped_by_rim(include_zero_stock=include_zero_stock)
        response_data = {
            rim: InventoryCardSerializer(cards, many=True).data
            for rim, cards in grouped.items()
        }
        return Response(response_data)


class InventoryItemDetailAPIView(RetrieveAPIView):
    permission_classes = [IsAuthenticated, CanViewInventory]
    queryset = InventoryItem.objects.select_related(
        "catalog_item",
        "catalog_item__brand",
        "catalog_item__brand__logo_image",
        "catalog_item__brand__logo_image_full",
        "catalog_item__brand__logo_image_thumb",
        "catalog_item__tire_spec",
        "catalog_item__rim_spec",
        "catalog_item__rim_spec__photo_image",
        "catalog_item__rim_spec__photo_image_full",
        "catalog_item__rim_spec__photo_image_thumb",
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
    permission_classes = [IsAuthenticated, CanRestock]

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


class RimReceiptCreateAPIView(APIView):
    permission_classes = [IsAuthenticated, CanCreateStockReceipt]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def post(self, request, *args, **kwargs):
        serializer = RimReceiptCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payload = dict(serializer.validated_data)
        rim_photo = payload.pop("rim_photo", None)
        if rim_photo is not None:
            full, thumb = create_image_variants_from_upload(
                uploaded_file=rim_photo,
                kind=ImageKind.RIM_PHOTO,
                max_size_bytes=int(os.getenv("MAX_IMAGE_SIZE_BYTES", 5 * 1024 * 1024)),
            )
            payload["photo_image_full"] = full
            payload["photo_image_thumb"] = thumb

        user = request.user if getattr(request.user, "is_authenticated", False) else None
        try:
            payload = create_rim_stock_receipt(
                payload=payload,
                user=user,
            )
        except RimSpecConflictError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)

        response_serializer = RimReceiptCreateResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class RimInventoryListAPIView(APIView):
    permission_classes = [IsAuthenticated, CanViewInventory]

    def get(self, request, *args, **kwargs):
        grouped = get_rim_inventory_cards_grouped()
        response_data = {
            rim: RimInventoryCardSerializer(cards, many=True).data
            for rim, cards in grouped.items()
        }
        return Response(response_data)


class RimInventoryDeactivateAPIView(APIView):
    permission_classes = [IsAuthenticated, CanDeactivateRims]

    def post(self, request, inventory_item_id, *args, **kwargs):
        serializer = RimDeactivateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user if getattr(request.user, "is_authenticated", False) else None
        try:
            payload = deactivate_rim_inventory_item(
                inventory_item_id=inventory_item_id,
                reason=serializer.validated_data.get("reason"),
                notes=serializer.validated_data.get("notes"),
                user=user,
            )
        except RimDeactivateForbiddenError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_403_FORBIDDEN)
        except RimDeactivateValidationError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        if payload is None:
            return Response({"detail": "Inventory item not found."}, status=status.HTTP_404_NOT_FOUND)

        response_serializer = RimDeactivateResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_200_OK)
