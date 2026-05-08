from django.conf import settings
from rest_framework.permissions import BasePermission


class HasOptionalDeviceApiKey(BasePermission):
    def has_permission(self, request, view):
        expected_key = getattr(settings, "DEVICE_CONTROL_API_KEY", "")
        if not expected_key:
            return True

        provided_key = (
            request.headers.get("X-Device-Key")
            or request.query_params.get("api_key")
            or ""
        )
        return provided_key == expected_key

