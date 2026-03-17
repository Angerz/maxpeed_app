from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.catalog.choices import ItemKind, Origin, ProductCategory, TireType
from apps.catalog.models import Brand, CatalogItem, TireSpec
from apps.inventory.models import InventoryCondition, InventoryItem, Owner


class AuthCapabilityApiTests(APITestCase):
    def setUp(self):
        self.user_model = get_user_model()
        self.password = "TestPass123!"

        self.gerencia = self.user_model.objects.create_user(username="gerencia", password=self.password)
        self.manager = self.user_model.objects.create_user(username="manager", password=self.password)
        self.vendedor = self.user_model.objects.create_user(username="vendedor", password=self.password)

        self.group_gerencia, _ = Group.objects.get_or_create(name="Gerencia")
        self.group_manager, _ = Group.objects.get_or_create(name="Manager")
        self.group_vendedor, _ = Group.objects.get_or_create(name="Vendedor")

        self._set_group_permissions()
        self.gerencia.groups.add(self.group_gerencia)
        self.manager.groups.add(self.group_manager)
        self.vendedor.groups.add(self.group_vendedor)

        self.owner, _ = Owner.objects.get_or_create(name="Maxpeed")
        self.brand = Brand.objects.create(name="AUSTONE")
        catalog_item = CatalogItem.objects.create(
            sku="TIRE-AUSTONE-195-65-R15-SECURITY",
            code="195/65R15",
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.TIRE,
            brand=self.brand,
            model="SECURITY",
            origin=Origin.CHINA,
        )
        TireSpec.objects.create(
            catalog_item=catalog_item,
            tire_type=TireType.RADIAL,
            width=195,
            aspect_ratio=65,
            rim_diameter="R15",
            ply_rating="PR8",
            tread_type="LINEAR",
            letter_color="BLACK",
        )
        InventoryItem.objects.create(
            catalog_item=catalog_item,
            owner=self.owner,
            condition=InventoryCondition.NEW,
            stock=0,
        )

    @staticmethod
    def _perm(app_label, codename):
        permission = Permission.objects.filter(content_type__app_label=app_label, codename=codename).first()
        if permission:
            return permission
        model = "inventoryitem" if app_label == "inventory" else "sale"
        content_type = ContentType.objects.get(app_label=app_label, model=model)
        return Permission.objects.create(
            content_type=content_type,
            codename=codename,
            name=codename.replace("_", " ").title(),
        )

    def _set_group_permissions(self):
        self.group_gerencia.permissions.set(
            [
                self._perm("inventory", "view_inventory"),
                self._perm("inventory", "view_zero_stock"),
                self._perm("inventory", "create_stock_receipt"),
                self._perm("inventory", "restock"),
                self._perm("inventory", "deactivate_rims"),
                self._perm("sales", "create_sale"),
                self._perm("sales", "view_sales"),
                self._perm("sales", "view_sale_detail"),
            ]
        )
        self.group_manager.permissions.set(
            [
                self._perm("inventory", "view_inventory"),
                self._perm("inventory", "view_zero_stock"),
                self._perm("sales", "view_sales"),
                self._perm("sales", "view_sale_detail"),
            ]
        )
        self.group_vendedor.permissions.set(
            [
                self._perm("inventory", "view_inventory"),
                self._perm("sales", "create_sale"),
                self._perm("sales", "view_sales"),
                self._perm("sales", "view_sale_detail"),
            ]
        )

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def test_login_returns_token_and_capabilities(self):
        response = self.client.post(
            reverse("auth-login"),
            {"username": "vendedor", "password": self.password},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("token", response.data)
        self.assertIn("capabilities", response.data)
        self.assertTrue(response.data["capabilities"]["can_create_sale"])
        self.assertFalse(response.data["capabilities"]["can_view_zero_stock"])

    def test_auth_me_and_logout(self):
        login = self.client.post(
            reverse("auth-login"),
            {"username": "manager", "password": self.password},
            format="json",
        )
        token = login.data["token"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

        me = self.client.get(reverse("auth-me"))
        self.assertEqual(me.status_code, status.HTTP_200_OK)
        self.assertEqual(me.data["user"]["username"], "manager")
        self.assertIn("capabilities", me.data)

        logout = self.client.post(reverse("auth-logout"))
        self.assertEqual(logout.status_code, status.HTTP_204_NO_CONTENT)

        me_after = self.client.get(reverse("auth-me"))
        self.assertEqual(me_after.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_vendedor_permissions_matrix(self):
        self._auth(self.vendedor)

        inv_response = self.client.get(f"{reverse('inventory-items')}?include_zero_stock=true")
        self.assertEqual(inv_response.status_code, status.HTTP_403_FORBIDDEN)

        sale_response = self.client.post(
            reverse("sales-list-create"),
            {
                "lines": [
                    {
                        "line_type": "SERVICE",
                        "description": "Balanceo",
                        "quantity": 1,
                        "unit_price": "40.00",
                    }
                ]
            },
            format="json",
        )
        self.assertEqual(sale_response.status_code, status.HTTP_201_CREATED)

        stock_response = self.client.post(reverse("inventory-stock-receipts"), {}, format="json")
        self.assertEqual(stock_response.status_code, status.HTTP_403_FORBIDDEN)

    def test_manager_permissions_matrix(self):
        self._auth(self.manager)

        caps = self.client.get(reverse("capabilities"))
        self.assertEqual(caps.status_code, status.HTTP_200_OK)
        self.assertTrue(caps.data["can_view_zero_stock"])
        self.assertFalse(caps.data["can_create_sale"])

        inv_response = self.client.get(f"{reverse('inventory-items')}?include_zero_stock=true")
        self.assertEqual(inv_response.status_code, status.HTTP_200_OK)

        sale_response = self.client.post(
            reverse("sales-list-create"),
            {
                "lines": [
                    {
                        "line_type": "SERVICE",
                        "description": "Balanceo",
                        "quantity": 1,
                        "unit_price": "40.00",
                    }
                ]
            },
            format="json",
        )
        self.assertEqual(sale_response.status_code, status.HTTP_403_FORBIDDEN)

    def test_gerencia_permissions_matrix(self):
        self._auth(self.gerencia)

        inv_response = self.client.get(f"{reverse('inventory-items')}?include_zero_stock=true")
        self.assertEqual(inv_response.status_code, status.HTTP_200_OK)

        sale_response = self.client.post(
            reverse("sales-list-create"),
            {
                "lines": [
                    {
                        "line_type": "SERVICE",
                        "description": "Balanceo",
                        "quantity": 1,
                        "unit_price": "40.00",
                    }
                ]
            },
            format="json",
        )
        self.assertEqual(sale_response.status_code, status.HTTP_201_CREATED)

        stock_payload = {
            "tire_type": "RADIAL",
            "brand_id": self.brand.id,
            "rim_diameter": "R15",
            "origin": "CHINA",
            "ply_rating": "PR8",
            "tread_type": "LINEAR",
            "letter_color": "BLACK",
            "width": 195,
            "aspect_ratio": 65,
            "quantity": 1,
            "unit_purchase_price": "100.00",
            "recommended_sale_price": "130.00",
            "model": "GERENCIA",
            "owner_id": self.owner.id,
        }
        stock_response = self.client.post(reverse("inventory-stock-receipts"), stock_payload, format="json")
        self.assertEqual(stock_response.status_code, status.HTTP_201_CREATED)
