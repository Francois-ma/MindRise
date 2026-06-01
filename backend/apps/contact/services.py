import html
from uuid import uuid4

from django.conf import settings
from rest_framework.exceptions import APIException

from apps.accounts.services import EmailDeliveryUnavailable, ResendEmailClient


class ContactMessageDeliveryUnavailable(APIException):
    status_code = 503
    default_detail = "We could not send your message right now. Please try again."
    default_code = "contact_message_delivery_unavailable"


TOPIC_LABELS = {
    "school-outreach": "School outreach",
    "community-program": "Community program",
    "partnership": "Partnership",
    "media": "Media inquiry",
    "volunteer": "Volunteer interest",
    "general": "General inquiry",
}


def send_contact_message(*, message_data: dict) -> str:
    recipient = settings.CONTACT_RECIPIENT_EMAIL
    if not recipient:
        raise ContactMessageDeliveryUnavailable()

    topic = message_data.get("topic") or "general"
    topic_label = TOPIC_LABELS.get(topic, topic.replace("-", " ").title())
    organization = message_data.get("organization") or "Not provided"
    name = message_data["name"]
    email = message_data["email"]
    message = message_data["message"]

    client = ResendEmailClient()
    try:
        return client.send_email(
            to_email=recipient,
            subject=f"{settings.CONTACT_EMAIL_SUBJECT_PREFIX} {topic_label}: {name}",
            text=_contact_email_text(
                name=name,
                email=email,
                organization=organization,
                topic_label=topic_label,
                message=message,
            ),
            html=_contact_email_html(
                name=name,
                email=email,
                organization=organization,
                topic_label=topic_label,
                message=message,
            ),
            idempotency_key=f"contact-message-{uuid4().hex}",
            use_default_reply_to=False,
        )
    except EmailDeliveryUnavailable as exc:
        raise ContactMessageDeliveryUnavailable() from exc


def _contact_email_text(*, name: str, email: str, organization: str, topic_label: str, message: str) -> str:
    return (
        "New MindRise contact message\n\n"
        f"Name: {name}\n"
        f"Email: {email}\n"
        f"Organization: {organization}\n"
        f"Topic: {topic_label}\n\n"
        f"Reply to this person manually at: {email}\n\n"
        f"Message:\n{message}\n"
    )


def _contact_email_html(*, name: str, email: str, organization: str, topic_label: str, message: str) -> str:
    safe_name = html.escape(name)
    safe_email = html.escape(email)
    safe_organization = html.escape(organization)
    safe_topic = html.escape(topic_label)
    safe_message = html.escape(message).replace("\n", "<br>")
    return f"""
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#13231f">
      <h1 style="color:#064d3b">New MindRise contact message</h1>
      <p><strong>Name:</strong> {safe_name}</p>
      <p><strong>Email:</strong> <a href="mailto:{safe_email}">{safe_email}</a></p>
      <p><strong>Organization:</strong> {safe_organization}</p>
      <p><strong>Topic:</strong> {safe_topic}</p>
      <hr style="border:0;border-top:1px solid #d9e8df;margin:20px 0">
      <p><strong>Reply manually:</strong> <a href="mailto:{safe_email}">{safe_email}</a></p>
      <p>{safe_message}</p>
    </div>
    """
