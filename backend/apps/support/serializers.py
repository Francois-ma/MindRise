from django.contrib.auth import get_user_model
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import CrisisResource, PractitionerProfile, SupportMessage, SupportThread

User = get_user_model()


class PractitionerProfileSerializer(serializers.ModelSerializer):
    phone_number = serializers.SerializerMethodField()
    can_call = serializers.SerializerMethodField()
    can_video_call = serializers.SerializerMethodField()
    is_my_profile = serializers.SerializerMethodField()

    class Meta:
        model = PractitionerProfile
        fields = (
            "id",
            "display_name",
            "specialization",
            "bio",
            "is_available",
            "next_available_at",
            "phone_number",
            "video_call_url",
            "can_call",
            "can_video_call",
            "is_my_profile",
        )

    def get_phone_number(self, obj) -> str:
        return obj.contact_phone or obj.user.phone_number

    def get_can_call(self, obj) -> bool:
        return bool(self.get_phone_number(obj))

    def get_can_video_call(self, obj) -> bool:
        return bool(obj.video_call_url)

    def get_is_my_profile(self, obj) -> bool:
        request = self.context.get("request")
        return bool(request and request.user.is_authenticated and obj.user_id == request.user.id)


class PractitionerAvailabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = PractitionerProfile
        fields = ("is_available", "next_available_at")


class SupportMessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source="sender.name", read_only=True)

    class Meta:
        model = SupportMessage
        fields = ("id", "thread", "sender", "sender_name", "body", "is_system", "created_at")
        read_only_fields = ("id", "thread", "sender", "sender_name", "is_system", "created_at")


class SupportThreadSerializer(serializers.ModelSerializer):
    patient_id = serializers.IntegerField(read_only=True)
    patient_name = serializers.CharField(source="patient.name", read_only=True)
    practitioner = PractitionerProfileSerializer(read_only=True)
    practitioner_id = serializers.PrimaryKeyRelatedField(
        queryset=PractitionerProfile.objects.filter(user__is_active=True, user__is_approved=True).select_related("user"),
        source="practitioner",
        write_only=True,
        required=False,
        allow_null=True,
    )
    latest_message = serializers.SerializerMethodField()

    class Meta:
        model = SupportThread
        fields = (
            "id",
            "thread_type",
            "subject",
            "contact_method",
            "patient_id",
            "patient_name",
            "practitioner",
            "practitioner_id",
            "is_closed",
            "latest_message",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "is_closed", "latest_message", "created_at", "updated_at")

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
            raise serializers.ValidationError("Practitioner support can only be started by patient accounts.")
        if not practitioner.is_available:
            raise serializers.ValidationError("This practitioner is not online right now.")

        contact_method = attrs.get("contact_method", SupportThread.ContactMethod.TEXT)
        phone_number = practitioner.contact_phone or practitioner.user.phone_number
        if contact_method == SupportThread.ContactMethod.PHONE and not phone_number:
            raise serializers.ValidationError("This practitioner does not have a phone call option yet.")
        if contact_method == SupportThread.ContactMethod.VIDEO and not practitioner.video_call_url:
            raise serializers.ValidationError("This practitioner does not have a video call option yet.")
        return attrs

    @extend_schema_field(SupportMessageSerializer)
    def get_latest_message(self, obj) -> dict | None:
        message = obj.messages.order_by("-created_at").first()
        return SupportMessageSerializer(message).data if message else None

    def create(self, validated_data):
        patient = self.context["request"].user
        practitioner = validated_data.get("practitioner")
        thread_type = validated_data["thread_type"]
        contact_method = validated_data.get("contact_method", SupportThread.ContactMethod.TEXT)
        subject = validated_data.get("subject", "")

        if thread_type == SupportThread.ThreadType.PRACTITIONER and practitioner:
            thread, created = SupportThread.objects.get_or_create(
                patient=patient,
                practitioner=practitioner,
                thread_type=thread_type,
                is_closed=False,
                defaults={"subject": subject, "contact_method": contact_method},
            )
            if not created:
                update_fields = []
                if thread.contact_method != contact_method:
                    thread.contact_method = contact_method
                    update_fields.append("contact_method")
                if subject and thread.subject != subject:
                    thread.subject = subject
                    update_fields.append("subject")
                if update_fields:
                    thread.save(update_fields=(*update_fields, "updated_at"))
            return thread

        return SupportThread.objects.create(patient=patient, **validated_data)


class CreateMessageSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=4000, trim_whitespace=True)

    def validate_body(self, value):
        if not value:
            raise serializers.ValidationError("Message cannot be blank.")
        return value


class CrisisResourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CrisisResource
        fields = ("id", "country_code", "title", "phone_number", "url", "description")