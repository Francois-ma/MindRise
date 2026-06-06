from django.db.models import Q
from django.utils import timezone
from rest_framework import decorators, permissions, response, status, viewsets

from .models import (
    CallSession,
    CrisisResource,
    PractitionerProfile,
    SupportMessage,
    SupportNotification,
    SupportThread,
)
from .serializers import (
    CallSessionSerializer,
    CreateMessageSerializer,
    CrisisResourceSerializer,
    PractitionerAvailabilitySerializer,
    PractitionerContactSerializer,
    PractitionerProfileSerializer,
    PractitionerProfileUpdateSerializer,
    SupportMessageSerializer,
    SupportNotificationSerializer,
    SupportThreadSerializer,
)


class PractitionerProfileViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PractitionerProfileSerializer
    queryset = PractitionerProfile.objects.none()
    filterset_fields = ("availability_status", "is_available", "specialization")
    search_fields = ("display_name", "specialization", "bio")

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False) or not self.request.user.is_authenticated:
            return self.queryset
        user = self.request.user
        queryset = PractitionerProfile.objects.select_related("user").filter(
            user__is_active=True,
            user__is_approved=True,
        )
        if user.is_staff or user.is_superuser:
            return queryset
        if user.role == user.Role.PRACTITIONER:
            return queryset.filter(user=user)
        return queryset.filter(availability_status=PractitionerProfile.AvailabilityStatus.ONLINE)

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

    @decorators.action(detail=False, methods=["patch"], url_path="me/profile")
    def me_profile(self, request):
        if request.user.role != request.user.Role.PRACTITIONER:
            return response.Response(
                {"detail": "Only practitioner accounts can update a professional profile."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not request.user.is_approved:
            return response.Response(
                {"detail": "Your practitioner account is waiting for superuser approval."},
                status=status.HTTP_403_FORBIDDEN,
            )

        profile = PractitionerProfile.ensure_for_user(request.user)
        serializer = PractitionerProfileUpdateSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        data = PractitionerProfileSerializer(profile, context=self.get_serializer_context()).data
        return response.Response(data)

    @decorators.action(detail=False, methods=["patch"], url_path="me/contact")
    def me_contact(self, request):
        if request.user.role != request.user.Role.PRACTITIONER:
            return response.Response(
                {"detail": "Only practitioner accounts can update practitioner contact options."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not request.user.is_approved:
            return response.Response(
                {"detail": "Your practitioner account is waiting for superuser approval."},
                status=status.HTTP_403_FORBIDDEN,
            )

        profile = PractitionerProfile.ensure_for_user(request.user)
        serializer = PractitionerContactSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return response.Response(PractitionerProfileSerializer(profile, context=self.get_serializer_context()).data)


class SupportThreadViewSet(viewsets.ModelViewSet):
    serializer_class = SupportThreadSerializer
    queryset = SupportThread.objects.none()
    http_method_names = ["get", "post", "head", "options"]
    filterset_fields = ("status", "thread_type", "contact_method")

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False) or not self.request.user.is_authenticated:
            return self.queryset
        user = self.request.user
        queryset = SupportThread.objects.select_related(
            "practitioner",
            "practitioner__user",
            "patient",
        ).prefetch_related("messages")
        if user.is_staff or user.is_superuser:
            return queryset
        if user.role == user.Role.PRACTITIONER:
            if not user.is_approved:
                return queryset.none()
            return queryset.filter(practitioner__user=user)
        return queryset.filter(patient=user)

    @decorators.action(detail=True, methods=["get", "post"])
    def messages(self, request, pk=None):
        thread = self.get_object()
        if request.user.is_staff or request.user.is_superuser:
            return response.Response(
                {"detail": "Administrators cannot read private support messages."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if request.method == "GET":
            thread.messages.filter(read_at__isnull=True).exclude(sender=request.user).update(read_at=timezone.now())
            messages = thread.messages.select_related("sender")
            return response.Response(SupportMessageSerializer(messages, many=True).data)

        if thread.status not in {SupportThread.Status.PENDING, SupportThread.Status.ACCEPTED} or thread.is_closed:
            return response.Response(
                {"detail": "This support session is not open for messages."},
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
        recipient = _other_participant(thread, request.user)
        if recipient is not None:
            SupportNotification.objects.create(
                recipient=recipient,
                session=thread,
                notification_type=SupportNotification.Type.NEW_MESSAGE,
                title="New private support message",
                body="A new message is waiting in your MindRise support session.",
            )
        return response.Response(SupportMessageSerializer(message).data, status=status.HTTP_201_CREATED)

    @decorators.action(detail=True, methods=["post"])
    def accept(self, request, pk=None):
        thread = self.get_object()
        denied = _practitioner_action_denied(request.user, thread)
        if denied is not None:
            return denied
        if thread.status != SupportThread.Status.PENDING:
            return response.Response({"detail": "Only pending support requests can be accepted."}, status=400)
        thread.accept()
        SupportNotification.objects.create(
            recipient=thread.patient,
            session=thread,
            notification_type=SupportNotification.Type.REQUEST_ACCEPTED,
            title="Your support request was accepted",
            body=f"{thread.practitioner.display_name} accepted your MindRise support request.",
        )
        return response.Response(self.get_serializer(thread).data)

    @decorators.action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        thread = self.get_object()
        denied = _practitioner_action_denied(request.user, thread)
        if denied is not None:
            return denied
        if thread.status != SupportThread.Status.PENDING:
            return response.Response({"detail": "Only pending support requests can be rejected."}, status=400)
        thread.reject()
        SupportNotification.objects.create(
            recipient=thread.patient,
            session=thread,
            notification_type=SupportNotification.Type.REQUEST_REJECTED,
            title="Support request unavailable",
            body="The practitioner could not accept this request. Please choose another online practitioner.",
        )
        return response.Response(self.get_serializer(thread).data)

    @decorators.action(detail=True, methods=["post"])
    def close(self, request, pk=None):
        thread = self.get_object()
        if request.user.is_staff or request.user.is_superuser:
            return response.Response({"detail": "Administrators cannot close private support sessions."}, status=403)
        thread.close()
        return response.Response(self.get_serializer(thread).data)


class CallSessionViewSet(viewsets.ModelViewSet):
    serializer_class = CallSessionSerializer
    queryset = CallSession.objects.none()
    http_method_names = ["get", "post", "head", "options"]
    filterset_fields = ("session", "status", "call_type")

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False) or not self.request.user.is_authenticated:
            return self.queryset
        user = self.request.user
        queryset = CallSession.objects.select_related(
            "session",
            "session__patient",
            "session__practitioner",
            "session__practitioner__user",
            "started_by",
        )
        if user.is_staff or user.is_superuser:
            return queryset
        return queryset.filter(Q(session__patient=user) | Q(session__practitioner__user=user))

    def create(self, request, *args, **kwargs):
        try:
            session_id = int(request.data.get("session"))
        except (TypeError, ValueError):
            return response.Response({"detail": "A valid session is required."}, status=400)
        session = SupportThread.objects.select_related("patient", "practitioner__user").filter(pk=session_id).first()
        if session is None or not _is_participant(request.user, session):
            return response.Response({"detail": "You cannot start a call for this support session."}, status=403)
        if session.status != SupportThread.Status.ACCEPTED or session.is_closed:
            return response.Response({"detail": "Calls require an accepted support session."}, status=400)
        call_type = request.data.get("call_type")
        if call_type not in CallSession.CallType.values:
            return response.Response({"detail": "Choose audio or video call_type."}, status=400)
        call = CallSession.objects.create(session=session, started_by=request.user, call_type=call_type)
        recipient = _other_participant(session, request.user)
        if recipient is not None:
            SupportNotification.objects.create(
                recipient=recipient,
                session=session,
                notification_type=SupportNotification.Type.CALL_UPDATE,
                title=f"Incoming {call.get_call_type_display().lower()} call",
                body="Open your MindRise support session to respond.",
            )
        return response.Response(self.get_serializer(call).data, status=status.HTTP_201_CREATED)

    @decorators.action(detail=True, methods=["post"])
    def accept(self, request, pk=None):
        call = self.get_object()
        if not _is_participant(request.user, call.session):
            return response.Response({"detail": "Only assigned session participants can manage calls."}, status=403)
        if call.started_by_id == request.user.id:
            return response.Response({"detail": "The other participant must accept the call."}, status=400)
        if call.status != CallSession.Status.RINGING:
            return response.Response({"detail": "Only ringing calls can be accepted."}, status=400)
        call.finish(CallSession.Status.ACCEPTED)
        return response.Response(self.get_serializer(call).data)

    @decorators.action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        call = self.get_object()
        if not _is_participant(request.user, call.session):
            return response.Response({"detail": "Only assigned session participants can manage calls."}, status=403)
        if call.status != CallSession.Status.RINGING:
            return response.Response({"detail": "Only ringing calls can be rejected."}, status=400)
        call.finish(CallSession.Status.REJECTED)
        return response.Response(self.get_serializer(call).data)

    @decorators.action(detail=True, methods=["post"])
    def end(self, request, pk=None):
        call = self.get_object()
        if not _is_participant(request.user, call.session):
            return response.Response({"detail": "Only assigned session participants can manage calls."}, status=403)
        if call.status not in {CallSession.Status.RINGING, CallSession.Status.ACCEPTED}:
            return response.Response({"detail": "This call has already ended."}, status=400)
        call.finish(CallSession.Status.ENDED)
        return response.Response(self.get_serializer(call).data)


class SupportNotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SupportNotificationSerializer
    queryset = SupportNotification.objects.none()
    filterset_fields = ("notification_type", "read_at")

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False) or not self.request.user.is_authenticated:
            return self.queryset
        return SupportNotification.objects.filter(recipient=self.request.user).select_related("session")

    @decorators.action(detail=True, methods=["post"], url_path="mark-read")
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.mark_read()
        return response.Response(self.get_serializer(notification).data)

    @decorators.action(detail=False, methods=["post"], url_path="mark-all-read")
    def mark_all_read(self, request):
        for notification in self.get_queryset().filter(read_at__isnull=True):
            notification.mark_read()
        return response.Response(status=status.HTTP_204_NO_CONTENT)


class CrisisResourceViewSet(viewsets.ReadOnlyModelViewSet):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = CrisisResourceSerializer
    queryset = CrisisResource.objects.filter(is_active=True)
    filterset_fields = ("country_code",)


def _is_participant(user, thread) -> bool:
    return thread.patient_id == user.id or (
        thread.practitioner_id is not None and thread.practitioner.user_id == user.id
    )


def _other_participant(thread, user):
    if thread.patient_id == user.id:
        return thread.practitioner.user if thread.practitioner_id else None
    if thread.practitioner_id and thread.practitioner.user_id == user.id:
        return thread.patient
    return None


def _practitioner_action_denied(user, thread):
    if user.role != user.Role.PRACTITIONER or not user.is_approved:
        return response.Response({"detail": "Only approved practitioners can manage support requests."}, status=403)
    if thread.practitioner_id is None or thread.practitioner.user_id != user.id:
        return response.Response({"detail": "This support request is not assigned to you."}, status=403)
    return None