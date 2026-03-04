from django.urls import path

from .views import StockReceiptCreateAPIView


urlpatterns = [
    path("stock-receipts/", StockReceiptCreateAPIView.as_view(), name="inventory-stock-receipts"),
]
