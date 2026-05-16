from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import CrisisResource, PractitionerProfile, SupportMessage, SupportThread


class PractitionerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PractitionerProfile
        fields = (
            "id",
            "display_name",
            "specialization",
            "bio",
            "is_available",
            "next_available_at",
        )


class SupportMessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source="sender.name", read_only=True)

    class Meta:
        model = SupportMessage
        fields = ("id", "thread", "sender", "sender_name", "body", "is_system", "created_at")
        read_only_fields = ("id", "thread", "sender", "sender_name", "is_system", "created_at")


class SupportThreadSerializer(serializers.ModelSerializer):
    practitioner = PractitionerProfileSerializer(read_only=True)
    practitioner_id = serializers.PrimaryKeyRelatedField(
        queryset=PractitionerProfile.objects.filter(user__is_active=True),
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
        return attrs

    @extend_schema_field(SupportMessageSerializer)
    def get_latest_message(self, obj) -> dict | None:
        message = obj.messages.order_by("-created_at").first()
        return SupportMessageSerializer(message).data if message else None

    def create(self, validated_data):
        patient = self.context["request"].user
        practitioner = validated_data.get("practitioner")
        thread_type = validated_data["thread_type"]

        if thread_type == SupportThread.ThreadType.PRACTITIONER and practitioner:
            thread, _ = SupportThread.objects.get_or_create(
                patient=patient,
                practitioner=practitioner,
                thread_type=thread_type,
                is_closed=False,
                defaults={"subject": validated_data.get("subject", "")},
            )
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
