from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.inventory.models import Owner

from .models import Brand
from .serializers import BrandSerializer, CatalogChoicesSerializer


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
        return Brand.objects.all().order_by("name")
