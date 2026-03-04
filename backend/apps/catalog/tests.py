from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.catalog.models import Brand


class CatalogApiTests(APITestCase):
    def test_choices_endpoint_returns_backend_choices(self):
        response = self.client.get(reverse("catalog-choices"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("tire_type", response.data)
        self.assertIn("rim_diameter", response.data)
        self.assertIn("origin", response.data)
        self.assertIn("ply_rating", response.data)
        self.assertIn("tread_type", response.data)
        self.assertIn("letter_color", response.data)

    def test_brands_endpoint_returns_brands(self):
        Brand.objects.create(name="MICHELIN")
        Brand.objects.create(name="AUSTONE")

        response = self.client.get(reverse("catalog-brands"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        self.assertEqual(response.data[0]["name"], "AUSTONE")
