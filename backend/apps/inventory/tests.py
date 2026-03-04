from decimal import Decimal

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.catalog.models import Brand, CatalogItem
from apps.inventory.models import InventoryItem, PriceRecord, PriceType
from apps.purchases.models import StockReceipt


class StockReceiptApiTests(APITestCase):
    def setUp(self):
        self.brand = Brand.objects.create(name="AUSTONE")
        self.url = reverse("inventory-stock-receipts")
        self.payload = {
            "tire_type": "RADIAL",
            "brand_id": self.brand.id,
            "rim_diameter": "R15",
            "origin": "CHINA",
            "ply_rating": "PR8",
            "tread_type": "LINEAR",
            "letter_color": "BLACK",
            "width": 195,
            "aspect_ratio": 65,
            "quantity": 4,
            "unit_purchase_price": "100.00",
            "recommended_sale_price": "145.00",
            "model": "SP-303",
        }

    def test_create_stock_receipt_creates_new_catalog_item(self):
        response = self.client.post(self.url, self.payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data["created_new_catalog_item"])
        self.assertEqual(CatalogItem.objects.count(), 1)
        self.assertEqual(InventoryItem.objects.count(), 1)
        self.assertEqual(StockReceipt.objects.count(), 1)
        self.assertEqual(PriceRecord.objects.filter(price_type=PriceType.PURCHASE, valid_to__isnull=True).count(), 1)
        self.assertEqual(PriceRecord.objects.filter(price_type=PriceType.SUGGESTED_SALE, valid_to__isnull=True).count(), 1)
        self.assertEqual(response.data["stock_after"], 4)

    def test_create_stock_receipt_reuses_existing_catalog_item(self):
        first_response = self.client.post(self.url, self.payload, format="json")
        second_payload = {**self.payload, "quantity": 2, "unit_purchase_price": "101.00"}

        second_response = self.client.post(self.url, second_payload, format="json")

        self.assertEqual(first_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(second_response.status_code, status.HTTP_201_CREATED)
        self.assertFalse(second_response.data["created_new_catalog_item"])
        self.assertEqual(CatalogItem.objects.count(), 1)
        self.assertEqual(InventoryItem.objects.get().stock, 6)

    def test_create_stock_receipt_requires_aspect_ratio_for_radial(self):
        payload = {**self.payload, "aspect_ratio": None}

        response = self.client.post(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("aspect_ratio", response.data)

    def test_create_stock_receipt_computes_recommended_sale_price_when_missing(self):
        payload = {**self.payload, "recommended_sale_price": None}

        response = self.client.post(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["prices_current"]["purchase"], "100.00")
        self.assertEqual(response.data["prices_current"]["suggested_sale"], "130.00")

        suggested_sale = PriceRecord.objects.get(price_type=PriceType.SUGGESTED_SALE, valid_to__isnull=True)
        self.assertEqual(suggested_sale.amount, Decimal("130.00"))
