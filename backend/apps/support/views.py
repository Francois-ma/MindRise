from rest_framework import decorators, permissions, response, status, viewsets

from .models import CrisisResource, PractitionerProfile, SupportMessage, SupportThread
from .serializers import (
    CreateMessageSerializer,
    CrisisResourceSerializer,
    PractitionerAvailabilitySerializer,
    PractitionerProfileSerializer,
    SupportMessageSerializer,
    SupportThreadSerializer,
)


class PractitionerProfileViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PractitionerProfileSerializer
    queryset = PractitionerProfile.objects.select_related("user").filter(user__is_active=True, user__is_approved=True)
    filterset_fields = ("is_available", "specialization")
    search_fields = ("display_name", "specialization", "bio")

    @decorators.action(detail=False, methods=["patch"], url_path="me/availability")
    def me_availability(self, request):
        if request.user.role != request.user.Role.PRACTITIONER:
            return response.Response(
                {"detail": "Only practitioner accounts can update practitioner availability."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not request.user.is_approved:
            return response.Response(
                {"detail": "Your practitioner account is waiting for superuser approval."},
                status=status.HTTP_403_FORBIDDEN,
            )

        profile = PractitionerProfile.ensure_for_user(request.user)
        serializer = PractitionerAvailabilitySerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return response.Response(PractitionerProfileSerializer(profile, context=self.get_serializer_context()).data)


class SupportThreadViewSet(viewsets.ModelViewSet):
    serializer_class = SupportThreadSerializer
    queryset = SupportThread.objects.none()
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False) or not self.request.user.is_authenticated:
            return self.queryset
        user = self.request.user
        practitioner_profile = getattr(user, "practitioner_profile", None)
        queryset = (
            SupportThread.objects
            .select_related("practitioner", "practitioner__user", "patient")
            .prefetch_related("messages")
        )
        if practitioner_profile:
            return queryset.filter(practitioner=practitioner_profile)
        return queryset.filter(patient=user)

    @decorators.action(detail=True, methods=["get", "post"])
    def messages(self, request, pk=None):
        thread = self.get_object()
        if request.method == "GET":
            messages = thread.messages.select_related("sender")
            return response.Response(SupportMessageSerializer(messages, many=True).data)

        if thread.is_closed:
            return response.Response(
                {"detail": "This support thread is closed."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CreateMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = SupportMessage.objects.create(
            thread=thread,
            sender=request.user,
            body=serializer.validated_data["body"],
        )
        thread.save(update_fields=["updated_at"])
        return response.Response(SupportMessageSerializer(message).data, status=status.HTTP_201_CREATED)

    @decorators.action(detail=True, methods=["post"])
    def close(self, request, pk=None):
        thread = self.get_object()
        thread.is_closed = True
        thread.save(update_fields=["is_closed", "updated_at"])
        return response.Response(status=status.HTTP_204_NO_CONTENT)


class CrisisResourceViewSet(viewsets.ReadOnlyModelViewSet):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = CrisisResourceSerializer
    queryset = CrisisResource.objects.filter(is_active=True)
    filterset_fields = ("country_code",)