import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.models import EmailVerificationChallenge


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
def test_unauthenticated_profile_is_rejected():
    client = APIClient()

    response = client.get(reverse("auth-me"))

    assert response.status_code == 401
