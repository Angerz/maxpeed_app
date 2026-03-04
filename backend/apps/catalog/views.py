from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Brand
from .serializers import BrandSerializer, CatalogChoicesSerializer


class CatalogChoicesAPIView(APIView):
    def get(self, request, *args, **kwargs):
        serializer = CatalogChoicesSerializer(CatalogChoicesSerializer.build_payload())
        return Response(serializer.data)


class BrandListAPIView(ListAPIView):
    serializer_class = BrandSerializer
    pagination_class = None

    def get_queryset(self):
        return Brand.objects.all().order_by("name")
