from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.views import APIView

from .choices import ProductCategory
from apps.inventory.models import Owner

from .models import Brand
from .serializers import BrandSerializer, CatalogChoicesSerializer, CatalogServiceSerializer

RIM_BRAND_NAMES = ["ROMAX", "HCW", "URD", "ZEHLENDORF", "FUEL", "ORIGINAL"]


class CatalogChoicesAPIView(APIView):
    def get(self, request, *args, **kwargs):
        owners = [
            {"value": owner.id, "label": owner.name}
            for owner in Owner.objects.filter(is_active=True).order_by("name")
        ]
        serializer = CatalogChoicesSerializer(
            CatalogChoicesSerializer.build_payload(owners=owners)
        )
        return Response(serializer.data)


class BrandListAPIView(ListAPIView):
    serializer_class = BrandSerializer
    pagination_class = None

    def get_queryset(self):
        return Brand.objects.exclude(name__in=RIM_BRAND_NAMES).order_by("name")


class RimBrandListAPIView(ListAPIView):
    serializer_class = BrandSerializer
    pagination_class = None

    def get_queryset(self):
        return Brand.objects.filter(name__in=RIM_BRAND_NAMES).order_by("name")


class CatalogServiceListAPIView(APIView):
    SERVICES_SPANISH_LABELS = {
        ProductCategory.RIM_REPAIR: "Reparación de Aros",
        ProductCategory.RIM_BALANCE: "Balanceo de Aros",
        ProductCategory.PAINTING: "Pintado",
        ProductCategory.TIRE_MOUNTING: "Montaje de Llantas",
        ProductCategory.TIRE_PATCHING: "Parchado de Llantas",
        ProductCategory.SERVICE_GENERAL: "Servicio General",
    }
    def get(self, request, *args, **kwargs):
        excluded = {ProductCategory.TIRE, ProductCategory.RIM, ProductCategory.ACCESSORY}

        payload = [
            {"value": value, "label": label}
            for value, label in self.SERVICES_SPANISH_LABELS.items()
            if value not in excluded
        ]
        serializer = CatalogServiceSerializer(payload, many=True)
        return Response(serializer.data)
