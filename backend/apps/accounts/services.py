import json
import logging
import secrets
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import timedelta

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import APIException, Throttled, ValidationError

from .models import EmailVerificationChallenge, User

logger = logging.getLogger(__name__)


class EmailDeliveryUnavailable(APIException):
    status_code = 503
    default_detail = "We could not send the verification email. Please try again."
    default_code = "email_delivery_unavailable"


@dataclass(frozen=True)
class IssuedEmailVerification:
    challenge: EmailVerificationChallenge
    code: str


def generate_email_verification_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


class ResendEmailClient:
    def __init__(self) -> None:
        self.api_key = settings.RESEND_API_KEY
        self.from_email = settings.RESEND_FROM_EMAIL
        self.api_url = settings.RESEND_API_URL.rstrip("/")
        self.timeout = settings.RESEND_TIMEOUT_SECONDS
        parsed_api_url = urllib.parse.urlparse(self.api_url)
        if parsed_api_url.scheme != "https" or not parsed_api_url.netloc:
            raise ImproperlyConfigured("RESEND_API_URL must be an HTTPS URL.")

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.from_email)

    def send_email(
        self,
        *,
        to_email: str,
        subject: str,
        text: str,
        html: str,
        idempotency_key: str,
        reply_to_email: str | None = None,
        use_default_reply_to: bool = False,
    ) -> str:
        if not self.is_configured:
            if settings.DEBUG:
                return "debug-resend-disabled"
            logger.error(
                "Resend email delivery is not configured. RESEND_API_KEY set=%s, RESEND_FROM_EMAIL set=%s.",
                bool(self.api_key),
                bool(self.from_email),
            )
            raise EmailDeliveryUnavailable()

        payload = {
            "from": self.from_email,
            "to": [to_email],
            "subject": subject,
            "text": text,
            "html": html,
        }
        reply_to = reply_to_email
        if reply_to is None and use_default_reply_to:
            reply_to = settings.RESEND_REPLY_TO_EMAIL
        if reply_to:
            payload["reply_to"] = reply_to

        request = urllib.request.Request(  # noqa: S310 - RESEND_API_URL is validated as HTTPS above.
            f"{self.api_url}/emails",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "User-Agent": "MindRise/1.0",
                "Idempotency-Key": idempotency_key,
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:  # noqa: S310
                body = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            error_body = exc.read().decode("utf-8", errors="replace")
            logger.error(
                "Resend rejected email. status=%s reason=%s body=%s",
                exc.code,
                exc.reason,
                error_body,
            )
            raise EmailDeliveryUnavailable() from exc
        except urllib.error.URLError as exc:
            logger.error("Resend email delivery failed before response: %s", exc)
            raise EmailDeliveryUnavailable() from exc
        except TimeoutError as exc:
            logger.error("Resend email delivery timed out after %s seconds.", self.timeout)
            raise EmailDeliveryUnavailable() from exc

        try:
            response_payload = json.loads(body)
        except json.JSONDecodeError:
            return ""
        return response_payload.get("id", "")


def issue_email_verification(
    *,
    user: User,
    request_ip: str | None = None,
    enforce_cooldown: bool = False,
) -> IssuedEmailVerification:
    if user.is_email_verified:
        raise ValidationError("This email address is already verified.")

    now = timezone.now()
    cooldown_seconds = settings.EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS
    latest = user.email_verification_challenges.filter(used_at__isnull=True).first()
    if enforce_cooldown and latest is not None:
        elapsed = (now - latest.sent_at).total_seconds()
        if elapsed < cooldown_seconds:
            raise Throttled(
                wait=int(cooldown_seconds - elapsed),
                detail="Please wait before requesting another verification email.",
            )

    code = generate_email_verification_code()
    expires_at = now + timedelta(minutes=settings.EMAIL_VERIFICATION_CODE_TTL_MINUTES)
    with transaction.atomic():
        user.email_verification_challenges.filter(used_at__isnull=True).update(used_at=now)
        challenge = EmailVerificationChallenge.objects.create(
            user=user,
            sent_to_email=user.email,
            code_hash=EmailVerificationChallenge.hash_code(user.id, user.email, code),
            expires_at=expires_at,
            request_ip=request_ip,
        )
    return IssuedEmailVerification(challenge=challenge, code=code)


def send_email_verification(*, user: User, issued: IssuedEmailVerification) -> None:
    html = _verification_email_html(user=user, code=issued.code)
    text = _verification_email_text(user=user, code=issued.code)
    client = ResendEmailClient()
    if settings.DEBUG and not client.is_configured:
        logger.info("MindRise verification code for %s: %s", user.email, issued.code)
    message_id = client.send_email(
        to_email=user.email,
        subject="Verify your MindRise email",
        text=text,
        html=html,
        idempotency_key=f"email-verification-{issued.challenge.id}",
    )
    if message_id:
        issued.challenge.provider_message_id = message_id
        issued.challenge.save(update_fields=("provider_message_id",))


def verify_email_code(*, email: str, code: str) -> User:
    normalized_email = User.objects.normalize_email(email).lower()
    try:
        user = User.objects.get(email=normalized_email)
    except User.DoesNotExist as exc:
        raise ValidationError("Invalid or expired verification code.") from exc

    invalid_code = False
    with transaction.atomic():
        challenge = user.email_verification_challenges.select_for_update().filter(
            used_at__isnull=True,
            expires_at__gt=timezone.now(),
        ).first()
        if challenge is None:
            raise ValidationError("Invalid or expired verification code.")

        if challenge.failed_attempts >= settings.EMAIL_VERIFICATION_MAX_ATTEMPTS:
            challenge.mark_used()
            invalid_code = True
        elif not challenge.matches_code(code):
            challenge.failed_attempts += 1
            update_fields = ["failed_attempts"]
            if challenge.failed_attempts >= settings.EMAIL_VERIFICATION_MAX_ATTEMPTS:
                challenge.used_at = timezone.now()
                update_fields.append("used_at")
            challenge.save(update_fields=update_fields)
            invalid_code = True
        else:
            challenge.mark_used()
            user.is_email_verified = True
            user.save(update_fields=("is_email_verified", "updated_at"))

    if invalid_code:
        raise ValidationError("Invalid or expired verification code.")
    return user


def _verification_email_text(*, user: User, code: str) -> str:
    return (
        f"Hi {user.name},\n\n"
        f"Your MindRise verification code is {code}.\n"
        f"This code expires in {settings.EMAIL_VERIFICATION_CODE_TTL_MINUTES} minutes.\n\n"
        "If you did not create a MindRise account, you can ignore this email."
    )


def _verification_email_html(*, user: User, code: str) -> str:
    escaped_name = user.name.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return f"""
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#13231f">
      <h1 style="color:#0f9f7a">Verify your MindRise email</h1>
      <p>Hi {escaped_name},</p>
      <p>Use this code to finish creating your MindRise account:</p>
      <p style="font-size:32px;font-weight:700;letter-spacing:6px;color:#0f766e">{code}</p>
      <p>This code expires in {settings.EMAIL_VERIFICATION_CODE_TTL_MINUTES} minutes.</p>
      <p>If you did not create a MindRise account, you can ignore this email.</p>
    </div>
    """
