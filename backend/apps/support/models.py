from django.conf import settings
from django.db import models


class PractitionerProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="practitioner_profile",
    )
    display_name = models.CharField(max_length=150)
    specialization = models.CharField(max_length=150)
    bio = models.TextField(blank=True, max_length=1200)
    license_number = models.CharField(max_length=80)
    is_available = models.BooleanField(default=False)
    next_available_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-is_available", "next_available_at", "display_name")

    def __str__(self) -> str:
        return self.display_name

    def save(self, *args, **kwargs):
        if self.user_id and self.user.role != self.user.Role.PRACTITIONER:
            self.user.role = self.user.Role.PRACTITIONER
            self.user.save(update_fields=["role"])
        super().save(*args, **kwargs)


class SupportThread(models.Model):
    class ThreadType(models.TextChoices):
        AI = "ai", "AI Coach"
        PRACTITIONER = "practitioner", "Practitioner"

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
    is_closed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-updated_at",)
        indexes = [models.Index(fields=("patient", "-updated_at"))]

    def __str__(self) -> str:
        return f"{self.patient_id}:{self.thread_type}:{self.subject}"


class SupportMessage(models.Model):
    thread = models.ForeignKey(SupportThread, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="support_messages",
    )
    body = models.TextField(max_length=4000)
    is_system = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("created_at",)
        indexes = [models.Index(fields=("thread", "created_at"))]

    def __str__(self) -> str:
        return f"{self.thread_id}:{self.sender_id}:{self.created_at:%Y-%m-%d %H:%M}"


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
