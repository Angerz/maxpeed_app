from django.db.models import Count
from rest_framework import generics, status
from rest_framework.exceptions import APIException, PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.sales.models import Sale
from apps.sales.serializers import (
    SaleCreateResponseSerializer,
    SaleCreateSerializer,
    SaleDetailSerializer,
    SaleListSerializer,
)
from apps.sales.services import SaleConflictError, SaleForbiddenError, create_sale


class ConflictError(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_detail = "Conflict."
    default_code = "conflict"


class SalePagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class SaleListCreateAPIView(APIView):
    permission_classes = [AllowAny]
    pagination_class = SalePagination

    def get(self, request, *args, **kwargs):
        queryset = Sale.objects.select_related("created_by").annotate(item_count=Count("lines")).order_by("-sold_at", "-id")
        paginator = self.pagination_class()
        paginated = paginator.paginate_queryset(queryset, request, view=self)
        serializer = SaleListSerializer(paginated, many=True)
        return paginator.get_paginated_response(serializer.data)

    def post(self, request, *args, **kwargs):
        serializer = SaleCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user if getattr(request.user, "is_authenticated", False) else None
        try:
            payload = create_sale(payload=serializer.validated_data, user=user)
        except SaleForbiddenError as exc:
            raise PermissionDenied(detail=str(exc))
        except SaleConflictError as exc:
            raise ConflictError(detail=str(exc))

        response_serializer = SaleCreateResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class SaleDetailAPIView(generics.RetrieveAPIView):
    permission_classes = [AllowAny]
    serializer_class = SaleDetailSerializer
    lookup_url_kwarg = "sale_id"
    queryset = Sale.objects.select_related("created_by").prefetch_related("lines").order_by("-sold_at", "-id")
