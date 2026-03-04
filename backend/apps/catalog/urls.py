from django.urls import path

from .views import BrandListAPIView, CatalogChoicesAPIView


urlpatterns = [
    path("choices/", CatalogChoicesAPIView.as_view(), name="catalog-choices"),
    path("brands/", BrandListAPIView.as_view(), name="catalog-brands"),
]
