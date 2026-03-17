from django.http import Http404, HttpResponse
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView

from .models import ImageAsset


class ImageAssetRetrieveAPIView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, image_id, *args, **kwargs):
        image = ImageAsset.objects.filter(pk=image_id).first()
        if image is None:
            raise Http404("Image not found.")

        response = HttpResponse(image.data, content_type=image.mime_type)
        if image.sha256:
            response["ETag"] = image.sha256
        response["Cache-Control"] = "public, max-age=86400"
        return response
