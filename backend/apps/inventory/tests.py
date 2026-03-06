from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.catalog.choices import ItemKind, Origin, ProductCategory, TireType
from apps.catalog.models import Brand, CatalogItem, TireSpec
from apps.inventory.models import (
    InventoryCondition,
    InventoryItem,
    MovementType,
    Owner,
    PriceRecord,
    PriceType,
)
from apps.purchases.models import StockReceipt, StockReceiptLine
from apps.inventory.services.core import set_current_price


class StockReceiptApiTests(APITestCase):
    def setUp(self):
        self.brand = Brand.objects.create(name="AUSTONE")
        self.maxpeed, _ = Owner.objects.get_or_create(name="Maxpeed")
        self.ruel, _ = Owner.objects.get_or_create(name="Ruel")
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
            "owner_id": self.maxpeed.id,
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
        self.assertEqual(InventoryItem.objects.get().owner, self.maxpeed)

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

    def test_inventory_item_unique_by_catalog_condition_owner(self):
        catalog_item = CatalogItem.objects.create(
            sku="TIRE-AUSTONE-155-R12-SP101",
            code="155R12",
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.TIRE,
            brand=self.brand,
            model="SP101",
            origin=Origin.CHINA,
        )
        TireSpec.objects.create(
            catalog_item=catalog_item,
            tire_type=TireType.CARGO,
            width=155,
            aspect_ratio=None,
            rim_diameter="R12",
            ply_rating="PR8",
            tread_type="LINEAR",
            letter_color="BLACK",
        )

        InventoryItem.objects.create(
            catalog_item=catalog_item,
            condition=InventoryCondition.NEW,
            owner=self.maxpeed,
            stock=0,
        )
        InventoryItem.objects.create(
            catalog_item=catalog_item,
            condition=InventoryCondition.NEW,
            owner=self.ruel,
            stock=0,
        )

        with self.assertRaises((ValidationError, IntegrityError)):
            InventoryItem.objects.create(
                catalog_item=catalog_item,
                condition=InventoryCondition.NEW,
                owner=self.maxpeed,
                stock=0,
            )

    def test_inventory_items_grouped_by_rim_and_include_zero_stock(self):
        first_response = self.client.post(self.url, self.payload, format="json")
        self.assertEqual(first_response.status_code, status.HTTP_201_CREATED)
        item_r15 = InventoryItem.objects.get(pk=first_response.data["inventory_item_id"])

        payload_r12 = {
            **self.payload,
            "rim_diameter": "R12",
            "width": 155,
            "aspect_ratio": None,
            "tire_type": "CARGO",
            "model": "SP-101",
            "quantity": 0 + 1,
        }
        second_response = self.client.post(self.url, payload_r12, format="json")
        self.assertEqual(second_response.status_code, status.HTTP_201_CREATED)
        item_r12 = InventoryItem.objects.get(pk=second_response.data["inventory_item_id"])

        item_r12.stock = 0
        item_r12.save(update_fields=["stock"])

        list_url = reverse("inventory-items")
        default_response = self.client.get(list_url)
        with_zero_response = self.client.get(f"{list_url}?include_zero_stock=true")

        self.assertEqual(default_response.status_code, status.HTTP_200_OK)
        self.assertEqual(with_zero_response.status_code, status.HTTP_200_OK)
        self.assertIn("R15", default_response.data)
        self.assertNotIn("R12", default_response.data)
        self.assertIn("R12", with_zero_response.data)
        self.assertEqual(default_response.data["R15"][0]["inventory_item_id"], item_r15.id)
        self.assertEqual(with_zero_response.data["R12"][0]["inventory_item_id"], item_r12.id)

    def test_inventory_item_detail_uses_last_historical_price_when_stock_zero(self):
        response = self.client.post(self.url, self.payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        inventory_item = InventoryItem.objects.get(pk=response.data["inventory_item_id"])

        purchase_current = PriceRecord.objects.get(
            inventory_item=inventory_item,
            price_type=PriceType.PURCHASE,
            valid_to__isnull=True,
        )
        purchase_current.valid_to = purchase_current.valid_from
        purchase_current.save(update_fields=["valid_to"])

        suggested_current = PriceRecord.objects.get(
            inventory_item=inventory_item,
            price_type=PriceType.SUGGESTED_SALE,
            valid_to__isnull=True,
        )
        suggested_current.valid_to = suggested_current.valid_from
        suggested_current.save(update_fields=["valid_to"])

        set_current_price(
            inventory_item=inventory_item,
            price_type=PriceType.PURCHASE,
            amount=Decimal("125.50"),
        )
        set_current_price(
            inventory_item=inventory_item,
            price_type=PriceType.SUGGESTED_SALE,
            amount=Decimal("160.90"),
        )

        current_purchase = PriceRecord.objects.get(
            inventory_item=inventory_item,
            price_type=PriceType.PURCHASE,
            valid_to__isnull=True,
        )
        current_purchase.valid_to = current_purchase.valid_from
        current_purchase.save(update_fields=["valid_to"])

        current_suggested = PriceRecord.objects.get(
            inventory_item=inventory_item,
            price_type=PriceType.SUGGESTED_SALE,
            valid_to__isnull=True,
        )
        current_suggested.valid_to = current_suggested.valid_from
        current_suggested.save(update_fields=["valid_to"])

        inventory_item.stock = 0
        inventory_item.save(update_fields=["stock"])

        detail_url = reverse("inventory-item-detail", kwargs={"inventory_item_id": inventory_item.id})
        detail_response = self.client.get(detail_url)

        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data["inventory_item_id"], inventory_item.id)
        self.assertEqual(detail_response.data["purchase_price"], "125.50")
        self.assertEqual(detail_response.data["suggested_sale_price"], "160.90")


class InventoryItemRestockApiTests(APITestCase):
    def setUp(self):
        self.owner, _ = Owner.objects.get_or_create(name="Maxpeed")
        self.brand = Brand.objects.create(name="MICHELIN")
        self.catalog_item = CatalogItem.objects.create(
            sku="TIRE-MICHELIN-195-65-R15-PRIMACY4",
            code="195/65R15",
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.TIRE,
            brand=self.brand,
            model="PRIMACY 4",
            origin=Origin.CHINA,
        )
        TireSpec.objects.create(
            catalog_item=self.catalog_item,
            tire_type=TireType.RADIAL,
            width=195,
            aspect_ratio=65,
            rim_diameter="R15",
            ply_rating="PR8",
            tread_type="LINEAR",
            letter_color="BLACK",
        )
        self.inventory_item = InventoryItem.objects.create(
            catalog_item=self.catalog_item,
            condition=InventoryCondition.NEW,
            owner=self.owner,
            stock=2,
        )
        self.url = reverse("inventory-item-restock", kwargs={"inventory_item_id": self.inventory_item.id})

    def test_restock_increments_stock_and_creates_receipt_and_movement(self):
        response = self.client.post(
            self.url,
            {
                "quantity": 10,
                "unit_purchase_price": "300.00",
                "suggested_sale_price": "390.00",
                "notes": "Ingreso directo",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.inventory_item.refresh_from_db()
        self.assertEqual(response.data["stock_before"], 2)
        self.assertEqual(response.data["stock_after"], 12)
        self.assertEqual(self.inventory_item.stock, 12)
        self.assertEqual(StockReceipt.objects.count(), 1)
        self.assertEqual(StockReceiptLine.objects.count(), 1)
        self.assertEqual(
            self.inventory_item.movements.filter(movement_type=MovementType.RESTOCK_IN).count(),
            1,
        )

    def test_restock_computes_suggested_sale_price_when_null(self):
        response = self.client.post(
            self.url,
            {
                "quantity": 1,
                "unit_purchase_price": "100.00",
                "suggested_sale_price": None,
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["suggested_sale_price_current"], "130.00")

    def test_restock_returns_400_when_quantity_invalid(self):
        response = self.client.post(
            self.url,
            {
                "quantity": 0,
                "unit_purchase_price": "100.00",
                "suggested_sale_price": "130.00",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("quantity", response.data)

    def test_restock_works_when_stock_is_zero(self):
        self.inventory_item.stock = 0
        self.inventory_item.save(update_fields=["stock"])

        response = self.client.post(
            self.url,
            {
                "quantity": 3,
                "unit_purchase_price": "110.00",
                "suggested_sale_price": "143.00",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["stock_before"], 0)
        self.assertEqual(response.data["stock_after"], 3)

    def test_restock_returns_409_for_used_inventory(self):
        used_item = InventoryItem.objects.create(
            catalog_item=self.catalog_item,
            condition=InventoryCondition.USED,
            owner=self.owner,
            stock=1,
        )
        used_url = reverse("inventory-item-restock", kwargs={"inventory_item_id": used_item.id})

        response = self.client.post(
            used_url,
            {
                "quantity": 1,
                "unit_purchase_price": "90.00",
                "suggested_sale_price": "117.00",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
