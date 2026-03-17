from django.urls import path

from .views import (
    BrandLogoUploadAPIView,
    BrandListAPIView,
    CatalogChoicesAPIView,
    CatalogServiceListAPIView,
    RimBrandListAPIView,
)


urlpatterns = [
    path("choices/", CatalogChoicesAPIView.as_view(), name="catalog-choices"),
    path("brands/", BrandListAPIView.as_view(), name="catalog-brands"),
    path("brands/<int:brand_id>/logo/", BrandLogoUploadAPIView.as_view(), name="catalog-brand-logo-upload"),
    path("rim-brands/", RimBrandListAPIView.as_view(), name="catalog-rim-brands"),
    path("services/", CatalogServiceListAPIView.as_view(), name="catalog-services"),
]
