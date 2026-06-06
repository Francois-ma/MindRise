import hmac
import uuid
from pathlib import Path

from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.files.storage import storages
from django.core.signing import salted_hmac
from django.db import models
from django.utils import timezone


def user_profile_picture_path(instance, filename: str) -> str:
    suffix = Path(filename).suffix.lower() or ".jpg"
    return f"accounts/profile-pictures/{instance.pk or 'new'}/{uuid.uuid4().hex}{suffix}"


def profile_picture_storage():
    return storages["profile_pictures"]


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email: str, password: str | None, **extra_fields):
        if not email:
            raise ValueError("Email address is required.")

        email = self.normalize_email(email).lower()
        user = self.model(email=email, username=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email: str, password: str | None = None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        extra_fields.setdefault("is_approved", True)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email: str, password: str | None = None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("role", User.Role.ADMIN)
        extra_fields.setdefault("is_approved", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    class Role(models.TextChoices):
        PATIENT = "patient", "Patient"
        PRACTITIONER = "practitioner", "Practitioner"
        ADMIN = "admin", "Admin"

    username = models.CharField(max_length=150, unique=True, blank=True)
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.PATIENT)
    phone_number = models.CharField(max_length=32, blank=True)
    profile_picture = models.ImageField(
        upload_to=user_profile_picture_path,
        storage=profile_picture_storage,
        blank=True,
        null=True,
    )
    date_of_birth = models.DateField(null=True, blank=True)
    timezone = models.CharField(max_length=64, default="UTC")
    is_email_verified = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True)
    accepted_terms_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: list[str] = []

    objects = UserManager()

    @property
    def name(self) -> str:
        full_name = f"{self.first_name} {self.last_name}".strip()
        return full_name or self.email

    def accept_terms(self) -> None:
        self.accepted_terms_at = timezone.now()

    def __str__(self) -> str:
        return self.email


class EmailVerificationChallenge(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="email_verification_challenges",
    )
    sent_to_email = models.EmailField()
    code_hash = models.CharField(max_length=64)
    expires_at = models.DateTimeField()
    sent_at = models.DateTimeField(auto_now_add=True)
    used_at = models.DateTimeField(null=True, blank=True)
    failed_attempts = models.PositiveSmallIntegerField(default=0)
    delivery_provider = models.CharField(max_length=32, default="resend")
    provider_message_id = models.CharField(max_length=128, blank=True)
    request_ip = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        ordering = ("-sent_at",)
        indexes = [
            models.Index(fields=("user", "-sent_at")),
            models.Index(fields=("code_hash", "expires_at")),
        ]

    def __str__(self) -> str:
        return f"{self.sent_to_email}:{self.sent_at:%Y-%m-%d %H:%M:%S}"

    @classmethod
    def hash_code(cls, user_id: int, email: str, code: str) -> str:
        return salted_hmac(
            "mindrise.email_verification",
            f"{user_id}:{email.lower()}:{code}",
        ).hexdigest()

    def matches_code(self, code: str) -> bool:
        expected = self.hash_code(self.user_id, self.sent_to_email, code)
        return hmac.compare_digest(expected, self.code_hash)

    @property
    def is_expired(self) -> bool:
        return timezone.now() >= self.expires_at

    @property
    def is_usable(self) -> bool:
        return self.used_at is None and not self.is_expired

    def mark_used(self) -> None:
        self.used_at = timezone.now()
        self.save(update_fields=("used_at",))