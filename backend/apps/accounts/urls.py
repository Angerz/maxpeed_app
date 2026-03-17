from django.urls import path

from .views import AuthLoginAPIView, AuthLogoutAPIView, AuthMeAPIView, CapabilitiesAPIView


urlpatterns = [
    path("auth/login/", AuthLoginAPIView.as_view(), name="auth-login"),
    path("auth/logout/", AuthLogoutAPIView.as_view(), name="auth-logout"),
    path("auth/me/", AuthMeAPIView.as_view(), name="auth-me"),
    path("capabilities/", CapabilitiesAPIView.as_view(), name="capabilities"),
]
