from django.urls import path

from .views import (
    DeviceControlStatusAPIView,
    HealthCheckAPIView,
    ProcessCommandAPIView,
    ProcessCommandStatusAPIView,
    WifiCredentialsAPIView,
    WifiCredentialsStatusAPIView,
)


urlpatterns = [
    path("process/", ProcessCommandAPIView.as_view(), name="device-control-process"),
    path(
        "process/status/",
        ProcessCommandStatusAPIView.as_view(),
        name="device-control-process-status",
    ),
    path("wifi/", WifiCredentialsAPIView.as_view(), name="device-control-wifi"),
    path(
        "wifi/status/",
        WifiCredentialsStatusAPIView.as_view(),
        name="device-control-wifi-status",
    ),
    path("health/", HealthCheckAPIView.as_view(), name="device-control-health"),
    path("status/", DeviceControlStatusAPIView.as_view(), name="device-control-status"),
]

