from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import (
    StockReceiptCreateResponseSerializer,
    StockReceiptCreateSerializer,
)
from .stock_receipts import create_tire_stock_receipt


class StockReceiptCreateAPIView(APIView):
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
