import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient

from apps.support.models import PractitionerProfile, SupportThread


@pytest.mark.django_db
def test_admin_created_practitioner_profile_marks_user_as_practitioner():
    user = get_user_model().objects.create_user(
        email="practitioner@example.com",
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
def test_online_practitioner_list_exposes_connection_options():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="patient-list@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    practitioner_user = user_model.objects.create_user(
        email="online-practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
        phone_number="+250788000111",
    )
    PractitionerProfile.objects.create(
        user=practitioner_user,
        display_name="Dr. Aline",
        specialization="Stress and anxiety",
        license_number="PSY-123",
        is_available=True,
        video_call_url="https://meet.example.com/mindrise-aline",
    )
    client = APIClient()
    client.force_authenticate(user=patient)

    response = client.get(reverse("practitioner-list"), {"is_available": "true"})

    assert response.status_code == 200
    assert response.data["results"][0]["display_name"] == "Dr. Aline"
    assert response.data["results"][0]["phone_number"] == "+250788000111"
    assert response.data["results"][0]["can_call"] is True
    assert response.data["results"][0]["can_video_call"] is True
    assert response.data["results"][0]["is_my_profile"] is False


@pytest.mark.django_db
def test_patient_can_start_and_message_practitioner_thread():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="patient@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    practitioner_user = user_model.objects.create_user(
        email="practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
    )
    practitioner = PractitionerProfile.objects.create(
        user=practitioner_user,
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
            "contact_method": "text",
            "subject": "Dr. Aline",
        },
        format="json",
    )

    assert thread_response.status_code == 201
    assert thread_response.data["contact_method"] == "text"
    assert thread_response.data["practitioner"]["display_name"] == "Dr. Aline"

    message_response = client.post(
        reverse("support-thread-messages", args=[thread_response.data["id"]]),
        {"body": "Hello, I would like to consult."},
        format="json",
    )

    assert message_response.status_code == 201
    assert message_response.data["body"] == "Hello, I would like to consult."
    assert SupportThread.objects.filter(patient=patient, practitioner=practitioner, contact_method="text").exists()

    client.force_authenticate(user=practitioner_user)
    practitioner_threads = client.get(reverse("support-thread-list"))
    assert practitioner_threads.status_code == 200
    assert practitioner_threads.data["results"][0]["patient_name"] == "Patient"

    reply_response = client.post(
        reverse("support-thread-messages", args=[thread_response.data["id"]]),
        {"body": "Hello Patient, I am here to help."},
        format="json",
    )
    assert reply_response.status_code == 201
    assert reply_response.data["sender_name"] == "Aline"


@pytest.mark.django_db
def test_patient_can_start_phone_and_video_connections_when_configured():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="patient-connect@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    practitioner_user = user_model.objects.create_user(
        email="connect-practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
    )
    practitioner = PractitionerProfile.objects.create(
        user=practitioner_user,
        display_name="Dr. Aline",
        specialization="Stress and anxiety",
        license_number="PSY-123",
        contact_phone="+250788000222",
        video_call_url="https://meet.example.com/mindrise-aline",
        is_available=True,
    )
    client = APIClient()
    client.force_authenticate(user=patient)

    phone_response = client.post(
        reverse("support-thread-list"),
        {"thread_type": "practitioner", "practitioner_id": practitioner.id, "contact_method": "phone"},
        format="json",
    )
    video_response = client.post(
        reverse("support-thread-list"),
        {"thread_type": "practitioner", "practitioner_id": practitioner.id, "contact_method": "video"},
        format="json",
    )

    assert phone_response.status_code == 201
    assert phone_response.data["contact_method"] == "phone"
    assert video_response.status_code == 201
    assert video_response.data["contact_method"] == "video"


@pytest.mark.django_db
def test_unavailable_practitioner_cannot_be_selected_for_support():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="patient-unavailable@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    practitioner_user = user_model.objects.create_user(
        email="offline-practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Offline",
    )
    practitioner = PractitionerProfile.objects.create(
        user=practitioner_user,
        display_name="Dr. Offline",
        specialization="Stress",
        license_number="OFF-123",
        is_available=False,
    )
    client = APIClient()
    client.force_authenticate(user=patient)

    response = client.post(
        reverse("support-thread-list"),
        {"thread_type": "practitioner", "practitioner_id": practitioner.id, "contact_method": "text"},
        format="json",
    )

    assert response.status_code == 400
    assert "not online" in str(response.data).lower()


@pytest.mark.django_db
def test_phone_and_video_connections_require_configured_contact_options():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="patient-options@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    practitioner_user = user_model.objects.create_user(
        email="limited-practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Limited",
    )
    practitioner = PractitionerProfile.objects.create(
        user=practitioner_user,
        display_name="Dr. Limited",
        specialization="Stress",
        license_number="LIM-123",
        is_available=True,
    )
    client = APIClient()
    client.force_authenticate(user=patient)

    phone_response = client.post(
        reverse("support-thread-list"),
        {"thread_type": "practitioner", "practitioner_id": practitioner.id, "contact_method": "phone"},
        format="json",
    )
    video_response = client.post(
        reverse("support-thread-list"),
        {"thread_type": "practitioner", "practitioner_id": practitioner.id, "contact_method": "video"},
        format="json",
    )

    assert phone_response.status_code == 400
    assert "phone call option" in str(phone_response.data).lower()
    assert video_response.status_code == 400
    assert "video call option" in str(video_response.data).lower()


@pytest.mark.django_db
def test_practitioner_can_update_own_online_availability():
    user_model = get_user_model()
    practitioner_user = user_model.objects.create_user(
        email="availability-practitioner@example.com",
        password="MindRiseStrong123!",
        first_name="Aline",
        role=user_model.Role.PRACTITIONER,
    )
    profile = PractitionerProfile.objects.create(
        user=practitioner_user,
        display_name="Dr. Aline",
        specialization="Stress and anxiety",
        license_number="PSY-123",
        is_available=False,
    )
    client = APIClient()
    client.force_authenticate(user=practitioner_user)

    response = client.patch(reverse("practitioner-me-availability"), {"is_available": True}, format="json")

    assert response.status_code == 200
    profile.refresh_from_db()
    assert profile.is_available is True
    assert response.data["is_my_profile"] is True


@pytest.mark.django_db
def test_pending_practitioner_profile_is_not_listed_for_support():
    user_model = get_user_model()
    patient = user_model.objects.create_user(
        email="support-patient@example.com",
        password="MindRiseStrong123!",
        first_name="Patient",
    )
    approved_user = user_model.objects.create_user(
        email="approved-support@example.com",
        password="MindRiseStrong123!",
        first_name="Approved",
        role=user_model.Role.PRACTITIONER,
        is_approved=True,
    )
    pending_user = user_model.objects.create_user(
        email="pending-support@example.com",
        password="MindRiseStrong123!",
        first_name="Pending",
        role=user_model.Role.PRACTITIONER,
        is_approved=False,
    )
    PractitionerProfile.objects.create(
        user=approved_user,
        display_name="Dr. Approved",
        specialization="Stress",
        license_number="APR-123",
        is_available=True,
    )
    PractitionerProfile.objects.create(
        user=pending_user,
        display_name="Dr. Pending",
        specialization="Stress",
        license_number="PEN-123",
        is_available=True,
    )
    client = APIClient()
    client.force_authenticate(user=patient)

    response = client.get(reverse("practitioner-list"))

    assert response.status_code == 200
    names = {item["display_name"] for item in response.data["results"]}
    assert "Dr. Approved" in names
    assert "Dr. Pending" not in names