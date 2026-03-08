from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.catalog.models import Brand
from apps.inventory.models import Owner


class CatalogApiTests(APITestCase):
    def test_choices_endpoint_returns_backend_choices(self):
        Owner.objects.get_or_create(name="Maxpeed")
        Owner.objects.get_or_create(name="Ruel")
        Owner.objects.get_or_create(name="ALDO")
        response = self.client.get(reverse("catalog-choices"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("tire_type", response.data)
        self.assertIn("rim_diameter", response.data)
        self.assertIn("origin", response.data)
        self.assertIn("ply_rating", response.data)
        self.assertIn("tread_type", response.data)
        self.assertIn("letter_color", response.data)
        self.assertIn("rim_holes", response.data)
        self.assertIn("rim_width_in", response.data)
        self.assertIn("rim_material", response.data)
        self.assertIn("rim_is_set", response.data)
        self.assertIn("owners", response.data)
        owner_labels = {owner["label"] for owner in response.data["owners"]}
        self.assertIn("Maxpeed", owner_labels)
        self.assertIn("Ruel", owner_labels)
        self.assertIn("ALDO", owner_labels)

    def test_brands_endpoint_returns_brands(self):
        Brand.objects.get_or_create(name="MICHELIN")
        Brand.objects.get_or_create(name="AUSTONE")
        Brand.objects.get_or_create(name="ROMAX")
        Brand.objects.get_or_create(name="HCW")

        response = self.client.get(reverse("catalog-brands"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = {brand["name"] for brand in response.data}
        self.assertIn("AUSTONE", names)
        self.assertIn("MICHELIN", names)
        self.assertNotIn("ROMAX", names)
        self.assertNotIn("HCW", names)

    def test_rim_brands_endpoint_returns_only_rim_brands(self):
        Brand.objects.get_or_create(name="ROMAX")
        Brand.objects.get_or_create(name="HCW")
        Brand.objects.get_or_create(name="URD")
        Brand.objects.get_or_create(name="ZEHLENDORF")
        Brand.objects.get_or_create(name="MICHELIN")

        response = self.client.get(reverse("catalog-rim-brands"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = {brand["name"] for brand in response.data}
        self.assertSetEqual(names, {"ROMAX", "HCW", "URD", "ZEHLENDORF"})
