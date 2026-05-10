from django.utils import timezone
from rest_framework import serializers

from .models import DeviceControlState, ProcessMode, ProcessStatus


class ProcessCommandWriteSerializer(serializers.Serializer):
    delay_seconds = serializers.IntegerField(min_value=0, required=False)
    mode = serializers.ChoiceField(choices=ProcessMode.choices, required=False)
    start = serializers.BooleanField(required=False, default=False)

    def validate(self, attrs):
        mode = attrs.get("mode")
        start = attrs.get("start", False)
        delay_seconds = attrs.get("delay_seconds")

        if start or mode == ProcessMode.MANUAL:
            attrs["mode"] = ProcessMode.MANUAL
            attrs["start"] = True
            attrs["delay_seconds"] = 0
            return attrs

        if delay_seconds is None:
            raise serializers.ValidationError(
                {"delay_seconds": "This field is required unless start=true."}
            )

        attrs["mode"] = ProcessMode.DELAY
        attrs["start"] = False
        return attrs


class WifiCredentialsWriteSerializer(serializers.Serializer):
    ssid = serializers.CharField(max_length=64, trim_whitespace=True)
    password = serializers.CharField(
        max_length=128,
        allow_blank=True,
        trim_whitespace=False,
    )


class HealthWriteSerializer(serializers.Serializer):
    status = serializers.CharField(max_length=32, default="online")
    is_initializing = serializers.BooleanField(required=False, default=False)
    message = serializers.CharField(
        max_length=160,
        allow_blank=True,
        required=False,
        default="",
    )


class ProcessStateWriteSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=ProcessStatus.choices)
    message = serializers.CharField(
        max_length=160,
        allow_blank=True,
        required=False,
        default="",
    )


def _remaining_seconds(state: DeviceControlState) -> int:
    if (
        state.process_status != ProcessStatus.IN_PROCESS
        or state.process_mode != ProcessMode.DELAY
        or state.process_requested_at is None
    ):
        return 0

    elapsed = int((timezone.now() - state.process_requested_at).total_seconds())
    return max(state.delay_seconds - elapsed, 0)


def serialize_process_command(state: DeviceControlState) -> dict:
    return {
        "command_id": str(state.process_command_id),
        "mode": state.process_mode,
        "status": state.process_status,
        "delay_seconds": state.delay_seconds,
        "remaining_seconds": _remaining_seconds(state),
        "start": state.start_requested,
        "requested_at": state.process_requested_at,
        "picked_up": state.process_picked_up_at is not None,
        "picked_up_at": state.process_picked_up_at,
        "started_at": state.process_started_at,
        "finished_at": state.process_finished_at,
    }


def serialize_wifi_credentials(state: DeviceControlState, include_secret: bool) -> dict:
    payload = {
        "command_id": str(state.wifi_command_id),
        "ssid": state.wifi_ssid,
        "requested_at": state.wifi_requested_at,
        "picked_up": state.wifi_picked_up_at is not None,
        "picked_up_at": state.wifi_picked_up_at,
    }
    if include_secret:
        payload["password"] = state.wifi_password
    return payload


def serialize_health(state: DeviceControlState) -> dict:
    now = timezone.now()
    is_stale = True
    age_seconds = None
    if state.health_reported_at is not None:
        age_seconds = int((now - state.health_reported_at).total_seconds())
        is_stale = age_seconds > 30 and not state.health_is_initializing

    return {
        "status": state.health_status,
        "message": state.health_message,
        "is_initializing": state.health_is_initializing,
        "reported_at": state.health_reported_at,
        "age_seconds": age_seconds,
        "is_stale": is_stale,
    }
