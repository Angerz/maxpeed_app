from django.urls import path

from .views import ImageAssetRetrieveAPIView


urlpatterns = [
    path("<int:image_id>/", ImageAssetRetrieveAPIView.as_view(), name="image-asset-download"),
]
