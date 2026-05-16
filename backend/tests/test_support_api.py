import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient

from apps.support.models import PractitionerProfile, SupportThread


@pytest.mark.django_db
def test_admin_created_practitioner_profile_marks_user_as_practitioner():
    user = get_user_model().objects.create_user(
        email="psychologist@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
    )

    profile = PractitionerProfile.objects.create(
        user=user,
        display_name="Dr. Aline",
        specialization="Stress and anxiety",
        license_number="PSY-123",
        is_available=True,
    )

    user.refresh_from_db()
    assert profile.display_name == "Dr. Aline"
    assert user.role == user.Role.PRACTITIONER


@pytest.mark.django_db
def test_patient_can_start_and_message_psychologist_thread():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="patient@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    psychologist_user = user_model.objects.create_user(
        email="psychologist@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
    )
    practitioner = PractitionerProfile.objects.create(
        user=psychologist_user,
        display_name="Dr. Aline",
        specialization="Stress and anxiety",
        license_number="PSY-123",
        is_available=True,
    )
    client = APIClient()
    client.force_authenticate(user=patient)

    thread_response = client.post(
        reverse("support-thread-list"),
        {
            "thread_type": "practitioner",
            "practitioner_id": practitioner.id,
            "subject": "Dr. Aline",
        },
        format="json",
    )

    assert thread_response.status_code == 201
    assert thread_response.data["practitioner"]["display_name"] == "Dr. Aline"

    message_response = client.post(
        reverse("support-thread-messages", args=[thread_response.data["id"]]),
        {"body": "Hello, I would like to consult."},
        format="json",
    )

    assert message_response.status_code == 201
    assert message_response.data["body"] == "Hello, I would like to consult."
    assert SupportThread.objects.filter(patient=patient, practitioner=practitioner).exists()
