from django.contrib.auth import authenticate
from rest_framework import serializers


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, attrs):
        user = authenticate(username=attrs["username"], password=attrs["password"])
        if user is None:
            raise serializers.ValidationError({"detail": "Invalid credentials."})
        if not user.is_active:
            raise serializers.ValidationError({"detail": "User is inactive."})
        attrs["user"] = user
        return attrs


class AuthUserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()
    first_name = serializers.CharField(allow_blank=True)
    last_name = serializers.CharField(allow_blank=True)


class AuthResponseSerializer(serializers.Serializer):
    user = AuthUserSerializer()
    token = serializers.CharField(required=False)
    groups = serializers.ListField(child=serializers.CharField())
    capabilities = serializers.DictField(child=serializers.BooleanField())
