import pytest
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from apps.learning.models import Category, LearningMaterial


@pytest.mark.django_db
def test_published_learning_materials_include_secure_file_url(settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path
    category = Category.objects.create(name="Stress care")
    uploaded_file = SimpleUploadedFile(
        "grounding.pdf",
        b"%PDF-1.4\n",
        content_type="application/pdf",
    )
    LearningMaterial.objects.create(
        category=category,
        title="Grounding worksheet",
        summary="A short worksheet for calming the nervous system.",
        material_type=LearningMaterial.MaterialType.PDF,
        file=uploaded_file,
        estimated_minutes=7,
        is_published=True,
        published_at=timezone.now(),
    )
    client = APIClient()

    response = client.get(reverse("learning-material-list"))

    assert response.status_code == 200
    payload = response.data["results"]
    assert payload[0]["title"] == "Grounding worksheet"
    assert payload[0]["category"]["name"] == "Stress care"
    assert payload[0]["material_type"] == "pdf"
    assert "/media/learning/materials/" in payload[0]["material_url"]

    media_path = payload[0]["material_url"].removeprefix("http://testserver")
    media_response = client.get(media_path)

    assert media_response.status_code == 200
    assert b"%PDF-1.4" in b"".join(media_response.streaming_content)


@pytest.mark.django_db
def test_learning_material_rejects_unsafe_file_type(settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path
    category = Category.objects.create(name="Safety")
    uploaded_file = SimpleUploadedFile(
        "malicious.html",
        b"<script>alert('xss')</script>",
        content_type="text/html",
    )
    material = LearningMaterial(
        category=category,
        title="Unsafe upload",
        summary="Should be rejected.",
        material_type=LearningMaterial.MaterialType.PDF,
        file=uploaded_file,
        is_published=True,
    )

    with pytest.raises(ValidationError):
        material.full_clean()
