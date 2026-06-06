from django.conf import settings
from django.db import models
from django.utils import timezone


class PractitionerProfile(models.Model):
    class AvailabilityStatus(models.TextChoices):
        ONLINE = "online", "Online"
        OFFLINE = "offline", "Offline"
        BUSY = "busy", "Busy"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="practitioner_profile",
    )
    display_name = models.CharField(max_length=150)
    specialization = models.CharField(max_length=150)
    bio = models.TextField(blank=True, max_length=1200)
    license_number = models.CharField(max_length=80)
    contact_phone = models.CharField(max_length=50, blank=True)
    video_call_url = models.URLField(blank=True)
    is_available = models.BooleanField(default=False)
    availability_status = models.CharField(
        max_length=16,
        choices=AvailabilityStatus.choices,
        default=AvailabilityStatus.OFFLINE,
    )
    next_available_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("availability_status", "next_available_at", "display_name")

    def __str__(self) -> str:
        return self.display_name

    @classmethod
    def ensure_for_user(cls, user):
        if user.role != user.Role.PRACTITIONER:
            raise ValueError("A practitioner profile can only belong to a practitioner account.")
        profile, _ = cls.objects.get_or_create(
            user=user,
            defaults={
                "display_name": user.name,
                "specialization": "",
                "license_number": "",
            },
        )
        return profile

    def save(self, *args, **kwargs):
        if self.user_id and self.user.role != self.user.Role.PRACTITIONER:
            self.user.role = self.user.Role.PRACTITIONER
            self.user.save(update_fields=["role"])
        if self._state.adding and self.is_available and self.availability_status == self.AvailabilityStatus.OFFLINE:
            self.availability_status = self.AvailabilityStatus.ONLINE
        self.is_available = self.availability_status == self.AvailabilityStatus.ONLINE
        super().save(*args, **kwargs)


class SupportThread(models.Model):
    class ThreadType(models.TextChoices):
        AI = "ai", "AI Coach"
        PRACTITIONER = "practitioner", "Practitioner"

    class ContactMethod(models.TextChoices):
        TEXT = "text", "Text"
        PHONE = "phone", "Phone call"
        VIDEO = "video", "Video call"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"
        CLOSED = "closed", "Closed"

    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="support_threads",
    )
    practitioner = models.ForeignKey(
        PractitionerProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="threads",
    )
    thread_type = models.CharField(max_length=24, choices=ThreadType.choices)
    subject = models.CharField(max_length=160, blank=True)
    contact_method = models.CharField(max_length=16, choices=ContactMethod.choices, default=ContactMethod.TEXT)
    status = models.CharField(max_length=16, choices=Status.choices, default=Status.ACCEPTED)
    is_closed = models.BooleanField(default=False)
    requested_at = models.DateTimeField(default=timezone.now)
    accepted_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-updated_at",)
        indexes = [
            models.Index(fields=("patient", "-updated_at")),
            models.Index(fields=("practitioner", "status", "-updated_at")),
        ]

    def __str__(self) -> str:
        return f"{self.patient_id}:{self.thread_type}:{self.subject}"

    def accept(self) -> None:
        self.status = self.Status.ACCEPTED
        self.accepted_at = timezone.now()
        self.is_closed = False
        self.save(update_fields=["status", "accepted_at", "is_closed", "updated_at"])

    def reject(self) -> None:
        self.status = self.Status.REJECTED
        self.ended_at = timezone.now()
        self.is_closed = True
        self.save(update_fields=["status", "ended_at", "is_closed", "updated_at"])

    def close(self) -> None:
        self.status = self.Status.CLOSED
        self.ended_at = timezone.now()
        self.is_closed = True
        self.save(update_fields=["status", "ended_at", "is_closed", "updated_at"])


class SupportSession(SupportThread):
    """Semantic API name for the existing persisted support-thread session."""

    class Meta:
        proxy = True
        verbose_name = "support session"
        verbose_name_plural = "support sessions"


class SupportMessage(models.Model):
    thread = models.ForeignKey(SupportThread, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="support_messages",
    )
    body = models.TextField(max_length=4000)
    is_system = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("created_at",)
        indexes = [
            models.Index(fields=("thread", "created_at")),
            models.Index(fields=("thread", "read_at", "created_at")),
        ]

    def __str__(self) -> str:
        return f"{self.thread_id}:{self.sender_id}:{self.created_at:%Y-%m-%d %H:%M}"


class SupportNotification(models.Model):
    class Type(models.TextChoices):
        SUPPORT_REQUEST = "support_request", "Support request"
        REQUEST_ACCEPTED = "request_accepted", "Request accepted"
        REQUEST_REJECTED = "request_rejected", "Request rejected"
        NEW_MESSAGE = "new_message", "New message"
        CALL_UPDATE = "call_update", "Call update"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="support_notifications",
    )
    session = models.ForeignKey(SupportThread, on_delete=models.CASCADE, related_name="notifications")
    notification_type = models.CharField(max_length=32, choices=Type.choices)
    title = models.CharField(max_length=160)
    body = models.CharField(max_length=280, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=("recipient", "read_at", "-created_at"))]

    @property
    def is_read(self) -> bool:
        return self.read_at is not None

    def mark_read(self) -> None:
        if self.read_at is None:
            self.read_at = timezone.now()
            self.save(update_fields=["read_at"])


class CallSession(models.Model):
    class CallType(models.TextChoices):
        AUDIO = "audio", "Audio"
        VIDEO = "video", "Video"

    class Status(models.TextChoices):
        RINGING = "ringing", "Ringing"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"
        ENDED = "ended", "Ended"
        MISSED = "missed", "Missed"

    session = models.ForeignKey(SupportThread, on_delete=models.CASCADE, related_name="calls")
    started_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="started_support_calls",
    )
    call_type = models.CharField(max_length=16, choices=CallType.choices)
    status = models.CharField(max_length=16, choices=Status.choices, default=Status.RINGING)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-started_at",)
        indexes = [models.Index(fields=("session", "status", "-started_at"))]

    def finish(self, status_value: str) -> None:
        self.status = status_value
        if status_value in {self.Status.REJECTED, self.Status.ENDED, self.Status.MISSED}:
            self.ended_at = timezone.now()
            self.save(update_fields=["status", "ended_at"])
        else:
            self.save(update_fields=["status"])


class CrisisResource(models.Model):
    country_code = models.CharField(max_length=2, db_index=True)
    title = models.CharField(max_length=160)
    phone_number = models.CharField(max_length=50, blank=True)
    url = models.URLField(blank=True)
    description = models.TextField(blank=True, max_length=1000)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ("country_code", "title")

    def __str__(self) -> str:
        return f"{self.country_code}: {self.title}"