import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.chatbot.services import ChatbotReply, ChatbotUnavailable


@pytest.mark.django_db
def test_chatbot_message_returns_openai_reply(monkeypatch, settings):
    settings.OPENAI_API_KEY = "test-key"
    settings.OPENAI_CHATBOT_MODEL = "gpt-5.5"
    captured = {}

    def fake_generate_reply(self, *, message, history):
        captured["message"] = message
        captured["history"] = history
        return ChatbotReply(reply="Try one slow breathing round, then name the next small step.", model="gpt-5.5")

    monkeypatch.setattr("apps.chatbot.services.OpenAIChatbotClient.generate_reply", fake_generate_reply)
    client = APIClient()

    response = client.post(
        reverse("chatbot-message"),
        {
            "message": "I feel overwhelmed before exams.",
            "history": [{"role": "assistant", "content": "I am here with you."}],
        },
        format="json",
    )

    assert response.status_code == 200
    assert response.data == {
        "reply": "Try one slow breathing round, then name the next small step.",
        "model": "gpt-5.5",
    }
    assert captured["message"] == "I feel overwhelmed before exams."
    assert captured["history"] == [{"role": "assistant", "content": "I am here with you."}]


@pytest.mark.django_db
def test_chatbot_message_returns_503_when_openai_is_unavailable(monkeypatch):
    def fail_generate_reply(self, *, message, history):
        raise ChatbotUnavailable()

    monkeypatch.setattr("apps.chatbot.services.OpenAIChatbotClient.generate_reply", fail_generate_reply)
    client = APIClient()

    response = client.post(reverse("chatbot-message"), {"message": "Can you help me calm down?"}, format="json")

    assert response.status_code == 503
    assert response.data["error"]["message"] == "MindRise AI assistant is temporarily unavailable. Please try again later."


@pytest.mark.django_db
def test_chatbot_message_uses_local_crisis_response(settings):
    settings.OPENAI_API_KEY = ""
    settings.DJANGO_DEBUG = False
    client = APIClient()

    response = client.post(reverse("chatbot-message"), {"message": "I want to kill myself"}, format="json")

    assert response.status_code == 200
    assert response.data["model"] == "mindrise-safety"
    assert "local emergency services" in response.data["reply"]
