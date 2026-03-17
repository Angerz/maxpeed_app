import os

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.generics import ListAPIView
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.images.models import ImageKind
from apps.images.services import create_image_variants_from_upload
from .choices import ProductCategory
from apps.inventory.models import Owner

from .models import Brand
from .serializers import (
    BrandLogoUploadResponseSerializer,
    BrandSerializer,
    CatalogChoicesSerializer,
    CatalogServiceSerializer,
)

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


class BrandLogoUploadAPIView(APIView):
    permission_classes = [AllowAny]
    parser_classes = [MultiPartParser, FormParser]

    @staticmethod
    def _build_image_ref(image):
        if image is None:
            return None
        return {"id": image.id, "url": f"/api/images/{image.id}/"}

    def post(self, request, brand_id, *args, **kwargs):
        brand = get_object_or_404(Brand, pk=brand_id)
        file_obj = request.FILES.get("logo")
        if file_obj is None:
            return Response({"detail": "logo file is required."}, status=status.HTTP_400_BAD_REQUEST)

        max_size = int(os.getenv("MAX_IMAGE_SIZE_BYTES", 5 * 1024 * 1024))
        full, thumb = create_image_variants_from_upload(
            uploaded_file=file_obj,
            kind=ImageKind.BRAND_LOGO,
            max_size_bytes=max_size,
        )
        brand.logo_image = full
        brand.logo_image_full = full
        brand.logo_image_thumb = thumb
        brand.save(update_fields=["logo_image", "logo_image_full", "logo_image_thumb"])

        payload = {
            "brand_id": brand.id,
            "logo_image": self._build_image_ref(full),
        }
        serializer = BrandLogoUploadResponseSerializer(payload)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
