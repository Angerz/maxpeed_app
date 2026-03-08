from decimal import Decimal
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.catalog.choices import ItemKind, Origin, ProductCategory, TireType
from apps.catalog.models import Brand, CatalogItem, RimSpec, TireSpec
from apps.inventory.models import InventoryCondition, InventoryItem, Owner
from apps.sales.models import Sale, SaleLineType


class SaleApiTests(APITestCase):
    def setUp(self):
        self.maxpeed_owner, _ = Owner.objects.get_or_create(name="Maxpeed")
        self.aldo_owner, _ = Owner.objects.get_or_create(name="ALDO")

        tire_brand = Brand.objects.create(name="AUSTONE")
        rim_brand = Brand.objects.create(name="ROMAX")

        tire_catalog = CatalogItem.objects.create(
            sku="TIRE-AUSTONE-195-65-R15-SP303",
            code="195/65R15",
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.TIRE,
            brand=tire_brand,
            model="SP303",
            origin=Origin.CHINA,
        )
        TireSpec.objects.create(
            catalog_item=tire_catalog,
            tire_type=TireType.RADIAL,
            width=195,
            aspect_ratio=65,
            rim_diameter="R15",
            ply_rating="PR8",
            tread_type="LINEAR",
            letter_color="BLACK",
        )
        self.tire_inventory = InventoryItem.objects.create(
            catalog_item=tire_catalog,
            owner=self.maxpeed_owner,
            condition=InventoryCondition.NEW,
            stock=5,
            is_active=True,
        )

        rim_catalog = CatalogItem.objects.create(
            sku="RIM-ROMAX-RIM-001",
            code="RIM-001",
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.RIM,
            brand=rim_brand,
            model=None,
            origin=None,
        )
        RimSpec.objects.create(
            catalog_item=rim_catalog,
            rim_diameter="R15",
            holes=5,
            width_in=8,
            material="ALUMINUM",
            is_set=True,
        )
        self.rim_inventory_aldo = InventoryItem.objects.create(
            catalog_item=rim_catalog,
            owner=self.aldo_owner,
            condition=InventoryCondition.NEW,
            stock=2,
            is_active=True,
        )

        self.sales_url = reverse("sales-list-create")
        self.services_url = reverse("catalog-services")

    def test_create_sale_with_service_only(self):
        payload = {
            "discount_total": "0.00",
            "lines": [
                {
                    "line_type": SaleLineType.SERVICE,
                    "description": "Balanceo",
                    "quantity": 1,
                    "unit_price": "40.00",
                }
            ],
        }

        response = self.client.post(self.sales_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["totals"]["subtotal"], "40.00")
        self.assertEqual(response.data["totals"]["total_due"], "40.00")
        self.assertEqual(Sale.objects.count(), 1)

    def test_create_sale_with_inventory_tire_decrements_stock(self):
        payload = {
            "lines": [
                {
                    "line_type": SaleLineType.INVENTORY_TIRE,
                    "inventory_item_id": self.tire_inventory.id,
                    "quantity": 2,
                    "unit_price": "390.00",
                    "discount": "10.00",
                }
            ],
        }

        response = self.client.post(self.sales_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        self.tire_inventory.refresh_from_db()
        self.assertEqual(self.tire_inventory.stock, 3)
        self.assertEqual(response.data["stock_updates"][0]["stock_before"], 5)
        self.assertEqual(response.data["stock_updates"][0]["stock_after"], 3)

    def test_create_sale_returns_409_for_insufficient_stock(self):
        payload = {
            "lines": [
                {
                    "line_type": SaleLineType.INVENTORY_TIRE,
                    "inventory_item_id": self.tire_inventory.id,
                    "quantity": 50,
                    "unit_price": "390.00",
                }
            ],
        }

        response = self.client.post(self.sales_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)

    def test_create_sale_rejects_aldo_rim_sale(self):
        payload = {
            "lines": [
                {
                    "line_type": SaleLineType.INVENTORY_RIM,
                    "inventory_item_id": self.rim_inventory_aldo.id,
                    "quantity": 1,
                    "unit_price": "500.00",
                }
            ],
        }

        response = self.client.post(self.sales_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_create_sale_with_tradein_sets_tradein_credit_total(self):
        payload = {
            "discount_total": "5.00",
            "lines": [
                {
                    "line_type": SaleLineType.SERVICE,
                    "description": "Alineamiento",
                    "quantity": 1,
                    "unit_price": "50.00",
                },
                {
                    "line_type": SaleLineType.TRADEIN_TIRE,
                    "description": "Llanta usada",
                    "quantity": 1,
                    "assessed_value": "20.00",
                    "tire_condition_percent": 70,
                },
            ],
        }

        response = self.client.post(self.sales_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["totals"]["subtotal"], "50.00")
        self.assertEqual(response.data["totals"]["tradein_credit_total"], "20.00")
        self.assertEqual(response.data["totals"]["total"], "45.00")
        self.assertEqual(response.data["totals"]["total_due"], "25.00")
        self.assertTrue(
            InventoryItem.objects.filter(
                condition=InventoryCondition.USED,
                catalog_item__code="TRADEIN-TIRE",
            ).exists()
        )

    def test_catalog_services_endpoint_excludes_tire_rim_accessory(self):
        response = self.client.get(self.services_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        values = {item["value"] for item in response.data}
        self.assertNotIn(ProductCategory.TIRE, values)
        self.assertNotIn(ProductCategory.RIM, values)
        self.assertNotIn(ProductCategory.ACCESSORY, values)
        self.assertIn(ProductCategory.SERVICE_GENERAL, values)

    def test_get_sales_list_and_detail(self):
        create_payload = {
            "lines": [
                {
                    "line_type": SaleLineType.SERVICE,
                    "description": "Balanceo",
                    "quantity": 1,
                    "unit_price": "30.00",
                }
            ],
        }
        create_response = self.client.post(self.sales_url, create_payload, format="json")
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        sale_id = create_response.data["sale_id"]

        list_response = self.client.get(self.sales_url)
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data["count"], 1)
        self.assertEqual(len(list_response.data["results"]), 1)

        detail_response = self.client.get(reverse("sales-detail", kwargs={"sale_id": sale_id}))
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data["id"], sale_id)
        self.assertEqual(len(detail_response.data["lines"]), 1)
        self.assertEqual(Decimal(detail_response.data["total_due"]), Decimal("30.00"))

    def _create_summary_sale(self, *, sold_at, total):
        return Sale.objects.create(
            sold_at=sold_at,
            status="CONFIRMED",
            subtotal=Decimal(total),
            discount_total=Decimal("0.00"),
            tradein_credit_total=Decimal("0.00"),
            total=Decimal(total),
            total_due=Decimal(total),
        )

    def test_sales_list_without_filters_includes_summary(self):
        self._create_summary_sale(sold_at=timezone.now(), total="100.00")

        response = self.client.get(self.sales_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("summary", response.data)
        self.assertIn("total_revenue", response.data["summary"])

    def test_sales_list_filters_last_two_days_by_lima_date(self):
        lima_tz = ZoneInfo("America/Lima")
        now_lima = timezone.now().astimezone(lima_tz)
        today = now_lima.date()
        yesterday = today - timedelta(days=1)
        three_days_ago = today - timedelta(days=3)

        self._create_summary_sale(
            sold_at=datetime.combine(today, datetime.min.time(), tzinfo=lima_tz).replace(hour=12),
            total="100.00",
        )
        self._create_summary_sale(
            sold_at=datetime.combine(yesterday, datetime.min.time(), tzinfo=lima_tz).replace(hour=9),
            total="200.00",
        )
        self._create_summary_sale(
            sold_at=datetime.combine(three_days_ago, datetime.min.time(), tzinfo=lima_tz).replace(hour=15),
            total="300.00",
        )

        response = self.client.get(
            f"{self.sales_url}?start_date={yesterday.isoformat()}&end_date={today.isoformat()}"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 2)
        self.assertEqual(response.data["summary"]["total_revenue"], "300.00")

    def test_sales_list_returns_400_when_start_date_is_after_end_date(self):
        response = self.client.get(f"{self.sales_url}?start_date=2026-03-10&end_date=2026-03-08")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_sales_summary_best_and_worst_day_are_correct(self):
        lima_tz = ZoneInfo("America/Lima")
        self._create_summary_sale(sold_at=datetime(2026, 3, 1, 10, 0, tzinfo=lima_tz), total="100.00")
        self._create_summary_sale(sold_at=datetime(2026, 3, 1, 18, 0, tzinfo=lima_tz), total="40.00")
        self._create_summary_sale(sold_at=datetime(2026, 3, 2, 11, 0, tzinfo=lima_tz), total="20.00")

        response = self.client.get(f"{self.sales_url}?start_date=2026-03-01&end_date=2026-03-02")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["summary"]["total_revenue"], "160.00")
        self.assertEqual(response.data["summary"]["best_day"]["date"], "2026-03-01")
        self.assertEqual(response.data["summary"]["best_day"]["total"], "140.00")
        self.assertEqual(response.data["summary"]["best_day"]["sales_count"], 2)
        self.assertEqual(response.data["summary"]["worst_day"]["date"], "2026-03-02")
        self.assertEqual(response.data["summary"]["worst_day"]["total"], "20.00")
        self.assertEqual(response.data["summary"]["worst_day"]["sales_count"], 1)

    def test_sales_list_results_are_sorted_desc_by_sold_at(self):
        lima_tz = ZoneInfo("America/Lima")
        older = self._create_summary_sale(sold_at=datetime(2026, 3, 1, 8, 0, tzinfo=lima_tz), total="10.00")
        newer = self._create_summary_sale(sold_at=datetime(2026, 3, 3, 8, 0, tzinfo=lima_tz), total="20.00")

        response = self.client.get(self.sales_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        result_ids = [item["id"] for item in response.data["results"]]
        self.assertTrue(result_ids.index(newer.id) < result_ids.index(older.id))
