from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import AuthResponseSerializer, LoginSerializer
from .services import compute_capabilities


def _auth_payload(user, token_value=None):
    payload = {
        "user": {
            "id": user.id,
            "username": user.username,
            "first_name": user.first_name,
            "last_name": user.last_name,
        },
        "groups": list(user.groups.values_list("name", flat=True).order_by("name")),
        "capabilities": compute_capabilities(user),
    }
    if token_value is not None:
        payload["token"] = token_value
    return payload


class AuthLoginAPIView(APIView):
    permission_classes = []

    def post(self, request, *args, **kwargs):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        payload = _auth_payload(user, token.key)
        output = AuthResponseSerializer(payload)
        return Response(output.data, status=status.HTTP_200_OK)


class AuthLogoutAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        Token.objects.filter(user=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class AuthMeAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        payload = _auth_payload(request.user)
        output = AuthResponseSerializer(payload)
        return Response(output.data, status=status.HTTP_200_OK)


class CapabilitiesAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response(compute_capabilities(request.user), status=status.HTTP_200_OK)
