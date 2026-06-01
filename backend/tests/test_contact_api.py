import pytest
from django.apps import apps
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.services import EmailDeliveryUnavailable


@pytest.mark.django_db
def test_contact_message_sends_directly_to_mindrise_inbox(monkeypatch, settings):
    settings.CONTACT_RECIPIENT_EMAIL = "mindriserwanda@gmail.com"
    sent = {}

    def fake_send_email(self, **kwargs):
        sent.update(kwargs)
        return "contact-message-id"

    monkeypatch.setattr("apps.accounts.services.ResendEmailClient.send_email", fake_send_email)
    client = APIClient()

    response = client.post(
        reverse("contact-message"),
        {
            "name": "Aline Uwase",
            "email": "aline@example.com",
            "organization": "Rwanda Youth Club",
            "topic": "partnership",
            "message": "We would like to invite MindRise for a youth mental health awareness session.",
        },
        format="json",
    )

    assert response.status_code == 202
    assert response.data["detail"] == "Message sent to MindRise."
    assert sent["to_email"] == "mindriserwanda@gmail.com"
    assert "reply_to_email" not in sent
    assert sent["use_default_reply_to"] is False
    assert "Partnership" in sent["subject"]
    assert "Rwanda Youth Club" in sent["text"]
    assert "Reply to this person manually at: aline@example.com" in sent["text"]
    with pytest.raises(LookupError):
        apps.get_model("contact", "ContactMessage")


@pytest.mark.django_db
def test_contact_message_returns_503_when_resend_fails(monkeypatch, settings):
    settings.CONTACT_RECIPIENT_EMAIL = "mindriserwanda@gmail.com"

    def fail_send_email(self, **kwargs):
        raise EmailDeliveryUnavailable()

    monkeypatch.setattr("apps.accounts.services.ResendEmailClient.send_email", fail_send_email)
    client = APIClient()

    response = client.post(
        reverse("contact-message"),
        {
            "name": "Aline Uwase",
            "email": "aline@example.com",
            "topic": "general",
            "message": "Please connect us with the MindRise team about youth wellness programming.",
        },
        format="json",
    )

    assert response.status_code == 503
    assert response.data["detail"] == "We could not send your message right now. Please try again."


@pytest.mark.django_db
def test_contact_message_honeypot_does_not_send(monkeypatch):
    def fail_send_email(self, **kwargs):
        raise AssertionError("Bot-trap submissions should not send email.")

    monkeypatch.setattr("apps.accounts.services.ResendEmailClient.send_email", fail_send_email)
    client = APIClient()

    response = client.post(
        reverse("contact-message"),
        {
            "name": "Bot",
            "email": "bot@example.com",
            "topic": "general",
            "message": "This looks long enough to pass validation but should be trapped.",
            "website": "https://spam.example",
        },
        format="json",
    )

    assert response.status_code == 202
