import json
import logging
from dataclasses import dataclass
from urllib import error, request
from urllib.parse import urlparse

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from rest_framework.exceptions import APIException

logger = logging.getLogger(__name__)


class ChatbotUnavailable(APIException):
    status_code = 503
    default_detail = "MindRise AI assistant is temporarily unavailable. Please try again later."
    default_code = "chatbot_unavailable"


@dataclass(frozen=True)
class ChatbotReply:
    reply: str
    model: str


SYSTEM_PROMPT = """
You are the MindRise Wellness Initiative AI assistant.
MindRise is a youth-driven mental health organization in Rwanda focused on emotional well-being, psychological resilience, mental health literacy, stigma reduction, awareness, education, and youth-friendly support.

Your role:
- Provide general mental health education, supportive reflection, and practical coping steps.
- Use warm, respectful, culturally sensitive language suitable for young people and community members.
- Keep answers concise, grounded, and action-oriented.
- Encourage safe conversation, trusted support, school/community resources, or professional help when needed.

Safety rules:
- Do not diagnose, prescribe medication, or present yourself as a therapist, doctor, emergency service, or crisis line.
- Do not ask for unnecessary personal data.
- If someone describes immediate danger, self-harm, suicidal intent, abuse, or violence, urge them to contact local emergency services, go to the nearest health facility, and reach a trusted person immediately.
- For severe or persistent symptoms, advise contacting a qualified mental health professional.
- If the question is outside mental health, MindRise programs, emotional well-being, or youth support, briefly redirect to relevant wellness guidance.
""".strip()

CRISIS_TERMS = (
    "kill myself",
    "suicide",
    "end my life",
    "hurt myself",
    "self harm",
    "self-harm",
    "i want to die",
    "i do not want to live",
    "harm someone",
    "hurt someone",
)

CRISIS_REPLY = (
    "I am really sorry you are carrying this. If you might hurt yourself or someone else, "
    "please contact local emergency services now, go to the nearest health facility, or reach a trusted person who can stay with you immediately. "
    "MindRise can support awareness and guidance, but urgent safety needs real-time human help. If you can, move away from anything you could use to harm yourself and message or call someone you trust right now."
)


class OpenAIChatbotClient:
    def __init__(self) -> None:
        self.api_key = settings.OPENAI_API_KEY
        self.api_url = settings.OPENAI_API_URL.rstrip("/")
        self.model = settings.OPENAI_CHATBOT_MODEL
        self.timeout = settings.OPENAI_CHATBOT_TIMEOUT_SECONDS
        parsed_api_url = urlparse(self.api_url)
        allowed_schemes = {"https"} if not settings.DEBUG else {"http", "https"}
        if parsed_api_url.scheme not in allowed_schemes or not parsed_api_url.netloc:
            raise ImproperlyConfigured("OPENAI_API_URL must be a valid URL.")

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.model)

    def generate_reply(self, *, message: str, history: list[dict[str, str]]) -> ChatbotReply:
        if _looks_like_crisis(message):
            return ChatbotReply(reply=CRISIS_REPLY, model="mindrise-safety")

        if not self.is_configured:
            if settings.DEBUG:
                return ChatbotReply(reply=_local_fallback_reply(message), model="local-fallback")
            logger.error(
                "OpenAI chatbot is not configured. OPENAI_API_KEY set=%s, OPENAI_CHATBOT_MODEL set=%s.",
                bool(self.api_key),
                bool(self.model),
            )
            raise ChatbotUnavailable()

        payload = {
            "model": self.model,
            "instructions": SYSTEM_PROMPT,
            "input": _build_input_messages(message=message, history=history),
            "max_output_tokens": settings.OPENAI_CHATBOT_MAX_OUTPUT_TOKENS,
            "store": False,
        }
        if settings.OPENAI_CHATBOT_REASONING_EFFORT:
            payload["reasoning"] = {"effort": settings.OPENAI_CHATBOT_REASONING_EFFORT}
        if settings.OPENAI_CHATBOT_VERBOSITY:
            payload["text"] = {"verbosity": settings.OPENAI_CHATBOT_VERBOSITY}

        req = request.Request(  # noqa: S310 - OPENAI_API_URL scheme is validated above.
            f"{self.api_url}/responses",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "User-Agent": "MindRise/1.0",
            },
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=self.timeout) as res:  # noqa: S310
                response_payload = json.loads(res.read().decode("utf-8"))
        except error.HTTPError as exc:
            error_body = exc.read().decode("utf-8", errors="replace")
            logger.error("OpenAI chatbot request rejected. status=%s reason=%s body=%s", exc.code, exc.reason, error_body)
            raise ChatbotUnavailable() from exc
        except (TimeoutError, OSError, error.URLError, json.JSONDecodeError) as exc:
            logger.error("OpenAI chatbot request failed: %s", exc)
            raise ChatbotUnavailable() from exc

        reply = _extract_output_text(response_payload)
        if not reply:
            logger.error("OpenAI chatbot response did not include output text.")
            raise ChatbotUnavailable()
        return ChatbotReply(reply=reply[:1800], model=self.model)


def _build_input_messages(*, message: str, history: list[dict[str, str]]) -> list[dict[str, str]]:
    messages = []
    for item in history[-8:]:
        role = item.get("role")
        content = str(item.get("content", "")).strip()
        if role in {"user", "assistant"} and content:
            messages.append({"role": role, "content": content[:1200]})
    messages.append({"role": "user", "content": message[:1200]})
    return messages


def _extract_output_text(payload: dict) -> str:
    output_text = payload.get("output_text")
    if isinstance(output_text, str) and output_text.strip():
        return output_text.strip()

    parts = []
    for item in payload.get("output", []):
        if not isinstance(item, dict):
            continue
        for content in item.get("content", []):
            if not isinstance(content, dict):
                continue
            text = content.get("text")
            if isinstance(text, str) and text.strip():
                parts.append(text.strip())
    return "\n\n".join(parts).strip()


def _looks_like_crisis(message: str) -> bool:
    normalized = message.lower()
    return any(term in normalized for term in CRISIS_TERMS)


def _local_fallback_reply(message: str) -> str:
    return (
        "I can help with general MindRise wellness guidance. A helpful first step is to name what you are feeling, "
        "take three slow breaths, and choose one small action: talk to someone you trust, write down the pressure point, "
        "or take a short grounding break. For serious or urgent concerns, contact a qualified professional or local emergency support."
    )
