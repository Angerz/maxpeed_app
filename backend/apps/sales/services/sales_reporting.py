from decimal import Decimal

from django.db.models import Count, DecimalField, Sum, Value
from django.db.models.functions import Coalesce, TruncDate


def _serialize_day(day_payload):
    if not day_payload:
        return None
    return {
        "date": day_payload["sale_date"],
        "total": day_payload["total"],
        "sales_count": day_payload["sales_count"],
    }


def compute_sales_summary(*, queryset, start_date, end_date, tz):
    # We use Sale.total as business revenue for period reporting
    # (before trade-in credit), keeping consistency with sales totals.
    total_revenue = queryset.aggregate(
        total=Coalesce(
            Sum("total"),
            Value(Decimal("0.00")),
            output_field=DecimalField(max_digits=12, decimal_places=2),
        )
    )["total"]

    daily = queryset.annotate(sale_date=TruncDate("sold_at", tzinfo=tz)).values("sale_date").annotate(
        total=Coalesce(
            Sum("total"),
            Value(Decimal("0.00")),
            output_field=DecimalField(max_digits=12, decimal_places=2),
        ),
        sales_count=Count("id"),
    )
    best_day = daily.order_by("-total", "-sales_count", "sale_date").first()
    worst_day = daily.order_by("total", "sales_count", "sale_date").first()

    return {
        "start_date": start_date,
        "end_date": end_date,
        "total_revenue": total_revenue,
        "best_day": _serialize_day(best_day),
        "worst_day": _serialize_day(worst_day),
    }
