from django.urls import path

from .views import (
    InventoryItemDetailAPIView,
    InventoryItemListAPIView,
    InventoryItemPurchasePriceHistoryAPIView,
    InventoryItemRestockAPIView,
    RimInventoryDeactivateAPIView,
    RimInventoryListAPIView,
    RimReceiptCreateAPIView,
    StockReceiptCreateAPIView,
)


urlpatterns = [
    path("stock-receipts/", StockReceiptCreateAPIView.as_view(), name="inventory-stock-receipts"),
    path("items/", InventoryItemListAPIView.as_view(), name="inventory-items"),
    path("items/<int:inventory_item_id>/", InventoryItemDetailAPIView.as_view(), name="inventory-item-detail"),
    path(
        "items/<int:inventory_item_id>/purchase-price-history/",
        InventoryItemPurchasePriceHistoryAPIView.as_view(),
        name="inventory-item-purchase-price-history",
    ),
    path("items/<int:inventory_item_id>/restock/", InventoryItemRestockAPIView.as_view(), name="inventory-item-restock"),
    path("rim-receipts/", RimReceiptCreateAPIView.as_view(), name="inventory-rim-receipts"),
    path("rims/", RimInventoryListAPIView.as_view(), name="inventory-rims"),
    path("rims/<int:inventory_item_id>/deactivate/", RimInventoryDeactivateAPIView.as_view(), name="inventory-rim-deactivate"),
]
