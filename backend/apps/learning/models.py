from pathlib import PurePath
from uuid import uuid4

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import FileExtensionValidator
from django.db import models
from django.utils.text import slugify

LEARNING_MATERIAL_ALLOWED_EXTENSIONS = (
    "pdf",
    "doc",
    "docx",
    "ppt",
    "pptx",
    "jpg",
    "jpeg",
    "png",
    "mp3",
    "m4a",
    "wav",
    "mp4",
    "mov",
)
LEARNING_MATERIAL_MAX_UPLOAD_BYTES = 50 * 1024 * 1024


def learning_material_upload_path(instance, filename: str) -> str:
    extension = PurePath(filename).suffix.lower()
    return f"learning/materials/{uuid4().hex}{extension}"


def validate_learning_material_file(value) -> None:
    size = getattr(value, "size", 0)
    if size > LEARNING_MATERIAL_MAX_UPLOAD_BYTES:
        raise ValidationError("Learning materials must be 50 MB or smaller.")

    extension = PurePath(value.name).suffix.lower().lstrip(".")
    if extension not in LEARNING_MATERIAL_ALLOWED_EXTENSIONS:
        raise ValidationError("Unsupported learning material file type.")


class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=120, unique=True, blank=True)
    description = models.TextField(blank=True, max_length=500)

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)


class Article(models.Model):
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="articles")
    title = models.CharField(max_length=180)
    slug = models.SlugField(max_length=220, unique=True, blank=True)
    summary = models.TextField(max_length=600)
    body = models.TextField()
    read_time_minutes = models.PositiveSmallIntegerField(default=5)
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-published_at", "-created_at")
        indexes = [models.Index(fields=("is_published", "-published_at"))]

    def __str__(self) -> str:
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)


class ArticleBookmark(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="article_bookmarks",
    )
    article = models.ForeignKey(Article, on_delete=models.CASCADE, related_name="bookmarks")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "article")
        ordering = ("-created_at",)

    def __str__(self) -> str:
        return f"{self.user_id}:{self.article_id}"


class LearningMaterial(models.Model):
    class MaterialType(models.TextChoices):
        PDF = "pdf", "PDF"
        WORKSHEET = "worksheet", "Worksheet"
        AUDIO = "audio", "Audio"
        VIDEO = "video", "Video"
        SLIDES = "slides", "Slides"
        LINK = "link", "External link"

    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="materials")
    title = models.CharField(max_length=180)
    slug = models.SlugField(max_length=220, unique=True, blank=True)
    summary = models.TextField(max_length=600)
    material_type = models.CharField(
        max_length=20,
        choices=MaterialType.choices,
        default=MaterialType.PDF,
    )
    file = models.FileField(
        upload_to=learning_material_upload_path,
        blank=True,
        validators=[
            FileExtensionValidator(allowed_extensions=LEARNING_MATERIAL_ALLOWED_EXTENSIONS),
            validate_learning_material_file,
        ],
    )
    external_url = models.URLField(blank=True)
    estimated_minutes = models.PositiveSmallIntegerField(default=5)
    file_size_bytes = models.PositiveBigIntegerField(default=0, editable=False)
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-published_at", "-created_at")
        indexes = [models.Index(fields=("is_published", "-published_at"))]

    def __str__(self) -> str:
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        self.file_size_bytes = self.file.size if self.file else 0
        self.full_clean()
        super().save(*args, **kwargs)

    def clean(self):
        super().clean()
        if bool(self.file) == bool(self.external_url):
            raise ValidationError("Provide either an uploaded file or an external URL, not both.")
        if self.external_url and not settings.DEBUG and not self.external_url.startswith("https://"):
            raise ValidationError("External learning material URLs must use HTTPS in production.")
