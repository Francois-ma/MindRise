from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.settings import api_settings
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from apps.support.models import PractitionerProfile

from .models import User
from .serializers import (
    EmailVerificationSerializer,
    LoginSerializer,
    LogoutSerializer,
    PRACTITIONER_APPROVAL_MESSAGE,
    PasswordChangeSerializer,
    PendingPractitionerSerializer,
    ProfileUpdateSerializer,
    RegisterSerializer,
    ResendEmailVerificationSerializer,
    UserSerializer,
)
from .services import issue_email_verification, send_email_verification, verify_email_code


class RegisterView(generics.CreateAPIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        with transaction.atomic():
            user = serializer.save()
            issued = issue_email_verification(user=user, request_ip=_client_ip(request))
            send_email_verification(user=user, issued=issued)
        data = serializer.to_representation(user)
        data["verification_expires_at"] = issued.challenge.expires_at.isoformat()
        return Response(data, status=status.HTTP_201_CREATED)


class LoginView(generics.GenericAPIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = LoginSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data)


class RefreshView(TokenRefreshView):
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"


class EmailVerificationView(generics.GenericAPIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = EmailVerificationSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = verify_email_code(
            email=serializer.validated_data["email"],
            code=serializer.validated_data["code"],
        )
        if user.role == User.Role.PRACTITIONER and not user.is_approved:
            return Response({"detail": PRACTITIONER_APPROVAL_MESSAGE}, status=status.HTTP_403_FORBIDDEN)
        return Response(serializer.to_representation(user))


class ResendEmailVerificationView(generics.GenericAPIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = ResendEmailVerificationSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = User.objects.normalize_email(serializer.validated_data["email"]).lower()
        user = User.objects.filter(email=email, is_email_verified=False).first()
        if user is not None:
            issued = issue_email_verification(
                user=user,
                request_ip=_client_ip(request),
                enforce_cooldown=True,
            )
            send_email_verification(user=user, issued=issued)
        return Response(
            {"detail": "If verification is needed, a new code has been sent."},
            status=status.HTTP_200_OK,
        )


class LogoutView(generics.GenericAPIView):
    serializer_class = LogoutSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            token = RefreshToken(serializer.validated_data["refresh"])
            token.blacklist()
        except TokenError:
            pass
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(generics.RetrieveUpdateAPIView):
    def get_serializer_class(self):
        if self.request.method in {"PUT", "PATCH"}:
            return ProfileUpdateSerializer
        return UserSerializer

    def get_object(self):
        return self.request.user


class PasswordChangeView(generics.GenericAPIView):
    serializer_class = PasswordChangeSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(status=status.HTTP_204_NO_CONTENT)


class PendingPractitionerListView(generics.ListAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = PendingPractitionerSerializer

    def get_queryset(self):
        return (
            User.objects.filter(role=User.Role.PRACTITIONER, is_approved=False, is_active=True)
            .select_related("practitioner_profile")
            .order_by("created_at")
        )


class ApprovePractitionerView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def patch(self, request, pk):
        user = get_object_or_404(User.objects.select_related("practitioner_profile"), pk=pk)
        validation_response = _validate_practitioner_target(request.user, user)
        if validation_response is not None:
            return validation_response

        user.is_approved = True
        user.save(update_fields=["is_approved", "updated_at"])
        PractitionerProfile.ensure_for_user(user)
        return Response(
            {
                "detail": "Practitioner account approved successfully.",
                "practitioner": PendingPractitionerSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


class DeactivatePractitionerView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def patch(self, request, pk):
        user = get_object_or_404(User.objects.select_related("practitioner_profile"), pk=pk)
        validation_response = _validate_practitioner_target(request.user, user)
        if validation_response is not None:
            return validation_response

        user.is_active = False
        user.is_approved = False
        user.save(update_fields=["is_active", "is_approved", "updated_at"])
        return Response(
            {
                "detail": "Practitioner account deactivated.",
                "practitioner": PendingPractitionerSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


def _validate_practitioner_target(actor, user):
    if user.role != User.Role.PRACTITIONER:
        return Response(
            {"detail": "Only practitioner accounts can be managed from this endpoint."},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if user.pk == actor.pk:
        return Response(
            {"detail": "You cannot approve or deactivate your own practitioner account."},
            status=status.HTTP_400_BAD_REQUEST,
        )
    return None


def _client_ip(request) -> str | None:
    remote_addr = request.META.get("REMOTE_ADDR")
    forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR", "")
    addresses = [address.strip() for address in forwarded_for.split(",") if address.strip()]
    num_proxies = api_settings.NUM_PROXIES

    if not addresses or num_proxies is None or num_proxies <= 0:
        return remote_addr
    if len(addresses) > num_proxies:
        return addresses[-(num_proxies + 1)]
    return addresses[0]