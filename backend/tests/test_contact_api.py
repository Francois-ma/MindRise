import pytest
from django.urls import reverse
from rest_framework.test import APIClient


@pytest.mark.django_db
def test_contact_message_sends_to_mindrise_inbox(monkeypatch, settings):
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
    assert sent["to_email"] == "mindriserwanda@gmail.com"
    assert sent["reply_to_email"] == "aline@example.com"
    assert "Partnership" in sent["subject"]
    assert "Rwanda Youth Club" in sent["text"]


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