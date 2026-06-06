import re

from django.contrib.auth import get_user_model
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import (
    CallSession,
    CrisisResource,
    PractitionerProfile,
    SupportMessage,
    SupportNotification,
    SupportThread,
)

User = get_user_model()


class PractitionerProfileSerializer(serializers.ModelSerializer):
    phone_number = serializers.SerializerMethodField()
    can_call = serializers.SerializerMethodField()
    can_video_call = serializers.SerializerMethodField()
    can_whatsapp = serializers.SerializerMethodField()
    whatsapp_url = serializers.SerializerMethodField()
    is_my_profile = serializers.SerializerMethodField()

    class Meta:
        model = PractitionerProfile
        fields = (
            "id",
            "display_name",
            "specialization",
            "bio",
            "availability_status",
            "is_available",
            "next_available_at",
            "phone_number",
            "video_call_url",
            "can_call",
            "can_video_call",
            "can_whatsapp",
            "whatsapp_url",
            "is_my_profile",
        )

    def get_phone_number(self, obj) -> str:
        return obj.contact_phone or obj.user.phone_number

    def get_can_call(self, obj) -> bool:
        return bool(self.get_phone_number(obj))

    def get_can_video_call(self, obj) -> bool:
        return bool(obj.video_call_url or self.get_phone_number(obj))

    def get_can_whatsapp(self, obj) -> bool:
        return bool(self.get_phone_number(obj))

    def get_whatsapp_url(self, obj) -> str:
        digits = re.sub(r"\D", "", self.get_phone_number(obj))
        return f"https://wa.me/{digits}" if digits else ""

    def get_is_my_profile(self, obj) -> bool:
        request = self.context.get("request")
        return bool(request and request.user.is_authenticated and obj.user_id == request.user.id)


class PractitionerContactSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source="contact_phone", required=False, allow_blank=True, max_length=50)

    class Meta:
        model = PractitionerProfile
        fields = ("phone_number", "video_call_url")

    def validate_phone_number(self, value):
        digits = re.sub(r"\D", "", value)
        if value and not value.strip().startswith("+"):
            raise serializers.ValidationError("Include the country code, starting with +.")
        if value and not 8 <= len(digits) <= 15:
            raise serializers.ValidationError("Enter a valid international telephone number.")
        return value.strip()


class PractitionerAvailabilitySerializer(serializers.ModelSerializer):
    is_available = serializers.BooleanField(required=False, write_only=True)

    class Meta:
        model = PractitionerProfile
        fields = ("availability_status", "is_available", "next_available_at")

    def validate(self, attrs):
        status_value = attrs.get("availability_status")
        is_available = attrs.pop("is_available", None)
        if status_value is None and is_available is not None:
            attrs["availability_status"] = (
                PractitionerProfile.AvailabilityStatus.ONLINE
                if is_available
                else PractitionerProfile.AvailabilityStatus.OFFLINE
            )
        return attrs


class SupportMessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source="sender.name", read_only=True)

    class Meta:
        model = SupportMessage
        fields = ("id", "thread", "sender", "sender_name", "body", "is_system", "read_at", "created_at")
        read_only_fields = ("id", "thread", "sender", "sender_name", "is_system", "read_at", "created_at")


class SupportThreadSerializer(serializers.ModelSerializer):
    patient_id = serializers.IntegerField(read_only=True)
    patient_name = serializers.CharField(source="patient.name", read_only=True)
    practitioner = PractitionerProfileSerializer(read_only=True)
    practitioner_id = serializers.PrimaryKeyRelatedField(
        queryset=PractitionerProfile.objects.filter(
            user__is_active=True,
            user__is_approved=True,
        ).select_related("user"),
        source="practitioner",
        write_only=True,
        required=False,
        allow_null=True,
    )
    latest_message = serializers.SerializerMethodField()
    can_message = serializers.SerializerMethodField()
    can_call = serializers.SerializerMethodField()

    class Meta:
        model = SupportThread
        fields = (
            "id",
            "thread_type",
            "subject",
            "contact_method",
            "status",
            "patient_id",
            "patient_name",
            "practitioner",
            "practitioner_id",
            "is_closed",
            "can_message",
            "can_call",
            "latest_message",
            "requested_at",
            "accepted_at",
            "ended_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "status",
            "is_closed",
            "can_message",
            "can_call",
            "latest_message",
            "requested_at",
            "accepted_at",
            "ended_at",
            "created_at",
            "updated_at",
        )

    def validate(self, attrs):
        thread_type = attrs.get("thread_type")
        practitioner = attrs.get("practitioner")
        if thread_type == SupportThread.ThreadType.PRACTITIONER and practitioner is None:
            raise serializers.ValidationError("Practitioner support requires practitioner_id.")
        if thread_type != SupportThread.ThreadType.PRACTITIONER or practitioner is None:
            return attrs

        request = self.context.get("request")
        user = getattr(request, "user", None)
        if getattr(user, "role", None) != User.Role.PATIENT:
            raise serializers.ValidationError("Practitioner support can only be requested by patient accounts.")
        if not practitioner.user.is_approved or not practitioner.user.is_active:
            raise serializers.ValidationError("This practitioner is not approved for support.")
        if practitioner.availability_status != PractitionerProfile.AvailabilityStatus.ONLINE:
            raise serializers.ValidationError("This practitioner is not online right now.")

        contact_method = attrs.get("contact_method", SupportThread.ContactMethod.TEXT)
        phone_number = practitioner.contact_phone or practitioner.user.phone_number
        if contact_method == SupportThread.ContactMethod.PHONE and not phone_number:
            raise serializers.ValidationError("This practitioner does not have a phone call option yet.")
        if contact_method == SupportThread.ContactMethod.VIDEO and not (practitioner.video_call_url or phone_number):
            raise serializers.ValidationError("This practitioner does not have a WhatsApp or video call option yet.")
        return attrs

    @extend_schema_field(SupportMessageSerializer)
    def get_latest_message(self, obj) -> dict | None:
        request = self.context.get("request")
        if request and (request.user.is_staff or request.user.is_superuser):
            return None
        message = obj.messages.order_by("-created_at").first()
        return SupportMessageSerializer(message).data if message else None

    def get_can_message(self, obj) -> bool:
        return obj.status in {SupportThread.Status.PENDING, SupportThread.Status.ACCEPTED} and not obj.is_closed

    def get_can_call(self, obj) -> bool:
        return obj.status == SupportThread.Status.ACCEPTED and not obj.is_closed

    def create(self, validated_data):
        patient = self.context["request"].user
        practitioner = validated_data.get("practitioner")
        thread_type = validated_data["thread_type"]
        contact_method = validated_data.get("contact_method", SupportThread.ContactMethod.TEXT)
        subject = validated_data.get("subject", "")

        if thread_type == SupportThread.ThreadType.PRACTITIONER and practitioner:
            session, created = SupportThread.objects.get_or_create(
                patient=patient,
                practitioner=practitioner,
                thread_type=thread_type,
                status__in=(SupportThread.Status.PENDING, SupportThread.Status.ACCEPTED),
                defaults={
                    "subject": subject,
                    "contact_method": contact_method,
                    "status": SupportThread.Status.PENDING,
                },
            )
            if created:
                SupportNotification.objects.create(
                    recipient=practitioner.user,
                    session=session,
                    notification_type=SupportNotification.Type.SUPPORT_REQUEST,
                    title="New patient support request",
                    body=f"{patient.name} requested private MindRise support.",
                )
            else:
                update_fields = []
                if session.contact_method != contact_method:
                    session.contact_method = contact_method
                    update_fields.append("contact_method")
                if subject and session.subject != subject:
                    session.subject = subject
                    update_fields.append("subject")
                if update_fields:
                    session.save(update_fields=(*update_fields, "updated_at"))
            return session

        return SupportThread.objects.create(patient=patient, **validated_data)


class CreateMessageSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=4000, trim_whitespace=True)

    def validate_body(self, value):
        if not value:
            raise serializers.ValidationError("Message cannot be blank.")
        return value


class CallSessionSerializer(serializers.ModelSerializer):
    started_by_name = serializers.CharField(source="started_by.name", read_only=True)

    class Meta:
        model = CallSession
        fields = (
            "id",
            "session",
            "started_by",
            "started_by_name",
            "call_type",
            "status",
            "started_at",
            "ended_at",
        )
        read_only_fields = ("id", "session", "started_by", "started_by_name", "status", "started_at", "ended_at")


class SupportNotificationSerializer(serializers.ModelSerializer):
    is_read = serializers.BooleanField(read_only=True)

    class Meta:
        model = SupportNotification
        fields = ("id", "session", "notification_type", "title", "body", "is_read", "read_at", "created_at")
        read_only_fields = fields


class CrisisResourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CrisisResource
        fields = ("id", "country_code", "title", "phone_number", "url", "description")