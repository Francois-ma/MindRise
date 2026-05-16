import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient


@pytest.mark.django_db
def test_user_can_create_private_mood_entry():
    user = get_user_model().objects.create_user(
        email="patient@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post(
        reverse("mood-entry-list"),
        {
            "mood": "happy",
            "score": 8,
            "note": "Feeling steady today",
            "occurred_at": timezone.now().isoformat(),
        },
        format="json",
    )

    assert response.status_code == 201
    assert response.data["mood"] == "happy"


@pytest.mark.django_db
def test_ai_insights_are_personalized_by_mood():
    user = get_user_model().objects.create_user(
        email="stressed@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    client = APIClient()
    client.force_authenticate(user=user)
    client.post(
        reverse("mood-entry-list"),
        {
            "mood": "stressed",
            "score": 3,
            "note": "Work pressure is high",
            "occurred_at": timezone.now().isoformat(),
        },
        format="json",
    )

    response = client.get(reverse("mood-entry-ai-insights"), {"mood": "stressed"})

    assert response.status_code == 200
    assert response.data["current_mood"] == "stressed"
    assert response.data["cards"]
    assert "stress" in response.data["cards"][0]["title"].lower()
