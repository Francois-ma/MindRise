import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.models import EmailVerificationChallenge
from apps.accounts.serializers import PRACTITIONER_APPROVAL_MESSAGE


@pytest.fixture(autouse=True)
def relax_auth_throttle(settings):
    settings.REST_FRAMEWORK = {
        **settings.REST_FRAMEWORK,
        "DEFAULT_THROTTLE_RATES": {
            **settings.REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"],
            "auth": "1000/minute",
        },
    }


@pytest.mark.django_db
def test_register_sends_verification_code_without_returning_tokens(monkeypatch):
    client = APIClient()
    monkeypatch.setattr(
        "apps.accounts.services.generate_email_verification_code",
        lambda: "123456",
    )
    monkeypatch.setattr(
        "apps.accounts.services.ResendEmailClient.send_email",
        lambda *args, **kwargs: "resend-message-id",
    )

    response = client.post(
        reverse("auth-register"),
        {
            "name": "Francois",
            "email": "francois@example.com",
            "password": "MindRiseStrong123!",
            "accepted_terms": True,
        },
        format="json",
    )

    assert response.status_code == 201
    assert "access" not in response.data
    assert response.data["email"] == "francois@example.com"

    user = get_user_model().objects.get(email="francois@example.com")
    assert user.role == user.Role.PATIENT
    assert user.is_approved is True
    assert user.is_email_verified is False
    challenge = EmailVerificationChallenge.objects.get(user=user)
    assert challenge.provider_message_id == "resend-message-id"


@pytest.mark.django_db
def test_email_verification_returns_tokens_and_marks_user_verified(monkeypatch):
    client = APIClient()
    monkeypatch.setattr(
        "apps.accounts.services.generate_email_verification_code",
        lambda: "123456",
    )
    monkeypatch.setattr(
        "apps.accounts.services.ResendEmailClient.send_email",
        lambda *args, **kwargs: "resend-message-id",
    )
    client.post(
        reverse("auth-register"),
        {
            "name": "Francois",
            "email": "francois@example.com",
            "password": "MindRiseStrong123!",
            "accepted_terms": True,
        },
        format="json",
    )

    response = client.post(
        reverse("auth-email-verify"),
        {"email": "francois@example.com", "code": "123456"},
        format="json",
    )

    assert response.status_code == 200
    assert response.data["access"]
    assert response.data["refresh"]
    assert response.data["user"]["is_email_verified"] is True
    assert response.data["user"]["is_approved"] is True
    user = get_user_model().objects.get(email="francois@example.com")
    assert user.is_email_verified is True


@pytest.mark.django_db
def test_login_rejects_unverified_email():
    user = get_user_model().objects.create_user(
        email="pending@example.com",
        password="MindRiseStrong123!",
        first_name="Pending",
    )
    user.is_email_verified = False
    user.save(update_fields=("is_email_verified",))
    client = APIClient()

    response = client.post(
        reverse("auth-login"),
        {"email": "pending@example.com", "password": "MindRiseStrong123!"},
        format="json",
    )

    assert response.status_code == 400
    assert "Verify your email" in str(response.data)


@pytest.mark.django_db
def test_verified_user_can_login():
    user = get_user_model().objects.create_user(
        email="verified@example.com",
        password="MindRiseStrong123!",
        first_name="Verified",
    )
    user.is_email_verified = True
    user.save(update_fields=("is_email_verified",))
    client = APIClient()

    response = client.post(
        reverse("auth-login"),
        {"email": "verified@example.com", "password": "MindRiseStrong123!"},
        format="json",
    )

    assert response.status_code == 200
    assert response.data["access"]


@pytest.mark.django_db
def test_practitioner_registration_is_pending_until_approval(monkeypatch):
    client = APIClient()
    monkeypatch.setattr(
        "apps.accounts.services.generate_email_verification_code",
        lambda: "123456",
    )
    monkeypatch.setattr(
        "apps.accounts.services.ResendEmailClient.send_email",
        lambda *args, **kwargs: "resend-message-id",
    )

    response = client.post(
        reverse("auth-register"),
        {
            "name": "Aline Practitioner",
            "email": "aline@example.com",
            "password": "MindRiseStrong123!",
            "accepted_terms": True,
            "role": "practitioner",
        },
        format="json",
    )

    assert response.status_code == 201
    assert response.data["role"] == "practitioner"
    assert response.data["is_approved"] is False
    user = get_user_model().objects.get(email="aline@example.com")
    assert user.role == user.Role.PRACTITIONER
    assert user.is_approved is False


@pytest.mark.django_db
def test_pending_practitioner_email_verification_does_not_return_tokens(monkeypatch):
    client = APIClient()
    monkeypatch.setattr(
        "apps.accounts.services.generate_email_verification_code",
        lambda: "123456",
    )
    monkeypatch.setattr(
        "apps.accounts.services.ResendEmailClient.send_email",
        lambda *args, **kwargs: "resend-message-id",
    )
    client.post(
        reverse("auth-register"),
        {
            "name": "Pending Practitioner",
            "email": "pending-practitioner@example.com",
            "password": "MindRiseStrong123!",
            "accepted_terms": True,
            "role": "PRACTITIONER",
        },
        format="json",
    )

    response = client.post(
        reverse("auth-email-verify"),
        {"email": "pending-practitioner@example.com", "code": "123456"},
        format="json",
    )

    assert response.status_code == 403
    assert response.data["detail"] == PRACTITIONER_APPROVAL_MESSAGE
    assert "access" not in response.data
    user = get_user_model().objects.get(email="pending-practitioner@example.com")
    assert user.is_email_verified is True
    assert user.is_approved is False


@pytest.mark.django_db
def test_pending_practitioner_login_is_blocked():
    user = get_user_model().objects.create_user(
        email="practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
        role=get_user_model().Role.PRACTITIONER,
        is_approved=False,
    )
    user.is_email_verified = True
    user.save(update_fields=("is_email_verified",))
    client = APIClient()

    response = client.post(
        reverse("auth-login"),
        {"email": "practitioner@example.com", "password": "MindRiseStrong123!"},
        format="json",
    )

    assert response.status_code == 400
    assert PRACTITIONER_APPROVAL_MESSAGE in str(response.data)


@pytest.mark.django_db
def test_admin_can_list_and_approve_pending_practitioner():
    user_model = get_user_model()
    admin = user_model.objects.create_superuser(
        email="admin@example.com",
        password="MindRiseStrong123!",
        first_name="Admin",
    )
    practitioner = user_model.objects.create_user(
        email="pending-approval@example.com",
        password="MindRiseStrong123!",
        first_name="Pending",
        role=user_model.Role.PRACTITIONER,
        is_approved=False,
    )
    practitioner.is_email_verified = True
    practitioner.save(update_fields=("is_email_verified",))
    client = APIClient()
    client.force_authenticate(user=admin)

    list_response = client.get(reverse("admin-practitioner-pending"))
    assert list_response.status_code == 200
    assert list_response.data["results"][0]["email"] == "pending-approval@example.com"

    response = client.patch(reverse("admin-practitioner-approve", args=[practitioner.id]), format="json")

    assert response.status_code == 200
    practitioner.refresh_from_db()
    assert practitioner.is_approved is True
    assert practitioner.practitioner_profile.display_name == practitioner.name


@pytest.mark.django_db
def test_normal_user_cannot_approve_practitioner():
    user_model = get_user_model()
    normal_user = user_model.objects.create_user(
        email="normal@example.com",
        password="MindRiseStrong123!",
        first_name="Normal",
    )
    practitioner = user_model.objects.create_user(
        email="cannot-approve@example.com",
        password="MindRiseStrong123!",
        first_name="Pending",
        role=user_model.Role.PRACTITIONER,
        is_approved=False,
    )
    client = APIClient()
    client.force_authenticate(user=normal_user)

    response = client.patch(reverse("admin-practitioner-approve", args=[practitioner.id]), format="json")

    assert response.status_code == 403
    practitioner.refresh_from_db()
    assert practitioner.is_approved is False


@pytest.mark.django_db
def test_approved_practitioner_can_login():
    user_model = get_user_model()
    practitioner = user_model.objects.create_user(
        email="approved-practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Approved",
        role=user_model.Role.PRACTITIONER,
        is_approved=True,
    )
    practitioner.is_email_verified = True
    practitioner.save(update_fields=("is_email_verified",))
    client = APIClient()

    response = client.post(
        reverse("auth-login"),
        {"email": "approved-practitioner@example.com", "password": "MindRiseStrong123!"},
        format="json",
    )

    assert response.status_code == 200
    assert response.data["access"]
    assert response.data["user"]["role"] == "practitioner"
    assert response.data["user"]["is_approved"] is True


@pytest.mark.django_db
def test_unauthenticated_profile_is_rejected():
    client = APIClient()

    response = client.get(reverse("auth-me"))

    assert response.status_code == 401


@pytest.mark.django_db
def test_email_verification_code_locks_after_repeated_failures(monkeypatch, settings):
    max_attempts = settings.EMAIL_VERIFICATION_MAX_ATTEMPTS
    client = APIClient()
    monkeypatch.setattr(
        "apps.accounts.services.generate_email_verification_code",
        lambda: "123456",
    )
    monkeypatch.setattr(
        "apps.accounts.services.ResendEmailClient.send_email",
        lambda *args, **kwargs: "resend-message-id",
    )
    client.post(
        reverse("auth-register"),
        {
            "name": "Lock Test",
            "email": "lock@example.com",
            "password": "MindRiseStrong123!",
            "accepted_terms": True,
        },
        format="json",
    )

    for _ in range(max_attempts):
        response = client.post(
            reverse("auth-email-verify"),
            {"email": "lock@example.com", "code": "000000"},
            format="json",
        )
        assert response.status_code == 400

    response = client.post(
        reverse("auth-email-verify"),
        {"email": "lock@example.com", "code": "123456"},
        format="json",
    )

    assert response.status_code == 400
    user = get_user_model().objects.get(email="lock@example.com")
    challenge = EmailVerificationChallenge.objects.get(user=user)
    assert user.is_email_verified is False
    assert challenge.failed_attempts == max_attempts
    assert challenge.used_at is not None

@pytest.mark.django_db
def test_patient_can_edit_profile_and_upload_picture(settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path
    user = get_user_model().objects.create_user(
        email="profile-patient@example.com",
        password="MindRiseStrong123!",
        first_name="Old",
    )
    client = APIClient()
    client.force_authenticate(user=user)
    picture = SimpleUploadedFile(
        "profile.gif",
        b"GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xff\xff\xff!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;",
        content_type="image/gif",
    )

    response = client.patch(
        reverse("auth-me"),
        {
            "first_name": "Claire",
            "last_name": "Patient",
            "phone_number": "+250788123456",
            "timezone": "Africa/Kigali",
            "profile_picture": picture,
        },
        format="multipart",
    )

    assert response.status_code == 200
    assert response.data["email"] == user.email
    assert response.data["name"] == "Claire Patient"
    assert response.data["role"] == user.Role.PATIENT
    assert response.data["profile_picture_url"].endswith(".gif")
    user.refresh_from_db()
    assert user.profile_picture.name.startswith(f"accounts/profile-pictures/{user.id}/")


@pytest.mark.django_db
def test_user_can_remove_profile_picture(settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path
    user = get_user_model().objects.create_user(
        email="remove-picture@example.com",
        password="MindRiseStrong123!",
        first_name="Remove",
    )
    user.profile_picture.save(
        "profile.gif",
        SimpleUploadedFile(
            "profile.gif",
            b"GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xff\xff\xff!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;",
            content_type="image/gif",
        ),
    )
    stored_path = tmp_path / user.profile_picture.name
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.patch(reverse("auth-me"), {"remove_profile_picture": True}, format="json")

    assert response.status_code == 200
    assert response.data["profile_picture_url"] == ""
    user.refresh_from_db()
    assert not user.profile_picture
    assert not stored_path.exists()
