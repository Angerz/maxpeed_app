from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from django.db.models import Count
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.exceptions import APIException, PermissionDenied, ValidationError
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
    SaleSummarySerializer,
)
from apps.sales.services import SaleConflictError, SaleForbiddenError, compute_sales_summary, create_sale


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

    @staticmethod
    def _parse_date_param(raw_value, field_name):
        if not raw_value:
            return None
        try:
            return date.fromisoformat(raw_value)
        except ValueError as exc:
            raise ValidationError({field_name: f"Invalid date format. Use YYYY-MM-DD for {field_name}."}) from exc

    def get(self, request, *args, **kwargs):
        lima_tz = ZoneInfo("America/Lima")

        start_date = self._parse_date_param(request.query_params.get("start_date"), "start_date")
        end_date = self._parse_date_param(request.query_params.get("end_date"), "end_date")
        if start_date and end_date and start_date > end_date:
            raise ValidationError({"detail": "start_date cannot be later than end_date."})

        base_queryset = Sale.objects.all()

        effective_start_date = start_date
        effective_end_date = end_date

        if start_date:
            start_dt = datetime.combine(start_date, time.min, tzinfo=lima_tz)
            base_queryset = base_queryset.filter(sold_at__gte=start_dt)
            if end_date:
                end_dt_exclusive = datetime.combine(end_date + timedelta(days=1), time.min, tzinfo=lima_tz)
                base_queryset = base_queryset.filter(sold_at__lt=end_dt_exclusive)
            else:
                effective_end_date = timezone.now().astimezone(lima_tz).date()
        elif end_date:
            end_dt_exclusive = datetime.combine(end_date + timedelta(days=1), time.min, tzinfo=lima_tz)
            base_queryset = base_queryset.filter(sold_at__lt=end_dt_exclusive)

        summary_payload = compute_sales_summary(
            queryset=base_queryset,
            start_date=effective_start_date,
            end_date=effective_end_date,
            tz=lima_tz,
        )
        summary = SaleSummarySerializer(summary_payload).data

        queryset = (
            base_queryset.select_related("created_by")
            .annotate(item_count=Count("lines"))
            .order_by("-sold_at", "-id")
        )
        paginator = self.pagination_class()
        paginated = paginator.paginate_queryset(queryset, request, view=self)
        serializer = SaleListSerializer(paginated, many=True)
        return Response(
            {
                "summary": summary,
                "count": paginator.page.paginator.count,
                "next": paginator.get_next_link(),
                "previous": paginator.get_previous_link(),
                "results": serializer.data,
            }
        )

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
