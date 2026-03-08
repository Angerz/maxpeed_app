from django.urls import path

from .views import SaleDetailAPIView, SaleListCreateAPIView


urlpatterns = [
    path("", SaleListCreateAPIView.as_view(), name="sales-list-create"),
    path("<int:sale_id>/", SaleDetailAPIView.as_view(), name="sales-detail"),
]
