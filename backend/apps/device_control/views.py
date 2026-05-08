import uuid

from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DeviceControlState
from .permissions import HasOptionalDeviceApiKey
from .serializers import (
    HealthWriteSerializer,
    ProcessCommandWriteSerializer,
    WifiCredentialsWriteSerializer,
    serialize_health,
    serialize_process_command,
    serialize_wifi_credentials,
)


def _get_state() -> DeviceControlState:
    state, _ = DeviceControlState.objects.get_or_create(singleton_key="main")
    return state


class ProcessCommandAPIView(APIView):
    permission_classes = [HasOptionalDeviceApiKey]

    def post(self, request, *args, **kwargs):
        serializer = ProcessCommandWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        with transaction.atomic():
            state = DeviceControlState.objects.select_for_update().get_or_create(
                singleton_key="main"
            )[0]
            state.process_command_id = uuid.uuid4()
            state.process_mode = data["mode"]
            state.delay_seconds = data["delay_seconds"]
            state.start_requested = data["start"]
            state.process_requested_at = timezone.now()
            state.process_picked_up_at = None
            state.save(
                update_fields=[
                    "process_command_id",
                    "process_mode",
                    "delay_seconds",
                    "start_requested",
                    "process_requested_at",
                    "process_picked_up_at",
                    "updated_at",
                ]
            )

        return Response(serialize_process_command(state), status=status.HTTP_201_CREATED)

    def get(self, request, *args, **kwargs):
        with transaction.atomic():
            state = DeviceControlState.objects.select_for_update().get_or_create(
                singleton_key="main"
            )[0]
            if state.process_requested_at and state.process_picked_up_at is None:
                state.process_picked_up_at = timezone.now()
                state.save(update_fields=["process_picked_up_at", "updated_at"])

        return Response(serialize_process_command(state), status=status.HTTP_200_OK)


class ProcessCommandStatusAPIView(APIView):
    permission_classes = [HasOptionalDeviceApiKey]

    def get(self, request, *args, **kwargs):
        return Response(serialize_process_command(_get_state()), status=status.HTTP_200_OK)


class WifiCredentialsAPIView(APIView):
    permission_classes = [HasOptionalDeviceApiKey]

    def post(self, request, *args, **kwargs):
        serializer = WifiCredentialsWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        with transaction.atomic():
            state = DeviceControlState.objects.select_for_update().get_or_create(
                singleton_key="main"
            )[0]
            state.wifi_command_id = uuid.uuid4()
            state.wifi_ssid = data["ssid"]
            state.wifi_password = data["password"]
            state.wifi_requested_at = timezone.now()
            state.wifi_picked_up_at = None
            state.save(
                update_fields=[
                    "wifi_command_id",
                    "wifi_ssid",
                    "wifi_password",
                    "wifi_requested_at",
                    "wifi_picked_up_at",
                    "updated_at",
                ]
            )

        return Response(
            serialize_wifi_credentials(state, include_secret=False),
            status=status.HTTP_201_CREATED,
        )

    def get(self, request, *args, **kwargs):
        with transaction.atomic():
            state = DeviceControlState.objects.select_for_update().get_or_create(
                singleton_key="main"
            )[0]
            if state.wifi_requested_at and state.wifi_picked_up_at is None:
                state.wifi_picked_up_at = timezone.now()
                state.save(update_fields=["wifi_picked_up_at", "updated_at"])

        return Response(
            serialize_wifi_credentials(state, include_secret=True),
            status=status.HTTP_200_OK,
        )


class WifiCredentialsStatusAPIView(APIView):
    permission_classes = [HasOptionalDeviceApiKey]

    def get(self, request, *args, **kwargs):
        return Response(
            serialize_wifi_credentials(_get_state(), include_secret=False),
            status=status.HTTP_200_OK,
        )


class HealthCheckAPIView(APIView):
    permission_classes = [HasOptionalDeviceApiKey]

    def post(self, request, *args, **kwargs):
        serializer = HealthWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        state = _get_state()
        state.health_status = data["status"]
        state.health_is_initializing = data["is_initializing"]
        state.health_message = data["message"]
        state.health_reported_at = timezone.now()
        state.save(
            update_fields=[
                "health_status",
                "health_is_initializing",
                "health_message",
                "health_reported_at",
                "updated_at",
            ]
        )
        return Response(serialize_health(state), status=status.HTTP_200_OK)

    def get(self, request, *args, **kwargs):
        return Response(serialize_health(_get_state()), status=status.HTTP_200_OK)


class DeviceControlStatusAPIView(APIView):
    permission_classes = [HasOptionalDeviceApiKey]

    def get(self, request, *args, **kwargs):
        state = _get_state()
        return Response(
            {
                "process": serialize_process_command(state),
                "wifi": serialize_wifi_credentials(state, include_secret=False),
                "health": serialize_health(state),
            },
            status=status.HTTP_200_OK,
        )

