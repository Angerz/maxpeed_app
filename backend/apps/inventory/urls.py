from django.urls import path

from .views import (
    InventoryItemDetailAPIView,
    InventoryItemListAPIView,
    InventoryItemRestockAPIView,
    StockReceiptCreateAPIView,
)


urlpatterns = [
    path("stock-receipts/", StockReceiptCreateAPIView.as_view(), name="inventory-stock-receipts"),
    path("items/", InventoryItemListAPIView.as_view(), name="inventory-items"),
    path("items/<int:inventory_item_id>/", InventoryItemDetailAPIView.as_view(), name="inventory-item-detail"),
    path("items/<int:inventory_item_id>/restock/", InventoryItemRestockAPIView.as_view(), name="inventory-item-restock"),
]
