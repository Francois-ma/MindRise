from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class TimestampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class MoodEntry(TimestampedModel):
    class Mood(models.TextChoices):
        HAPPY = "happy", "Happy"
        CALM = "calm", "Calm"
        NEUTRAL = "neutral", "Neutral"
        SAD = "sad", "Sad"
        STRESSED = "stressed", "Stressed"
        ANGRY = "angry", "Angry"
        ENERGETIC = "energetic", "Energetic"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="mood_entries")
    mood = models.CharField(max_length=24, choices=Mood.choices)
    score = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(10)])
    note = models.TextField(blank=True, max_length=2000)
    occurred_at = models.DateTimeField(db_index=True)

    class Meta:
        ordering = ("-occurred_at", "-created_at")
        indexes = [models.Index(fields=("user", "-occurred_at"))]

    def __str__(self) -> str:
        return f"{self.user_id}:{self.mood}:{self.occurred_at:%Y-%m-%d}"


class GratitudeEntry(TimestampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="gratitude_entries",
    )
    items = models.JSONField(default=list)
    note = models.TextField(blank=True, max_length=1000)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self) -> str:
        return f"{self.user_id}:gratitude:{self.created_at:%Y-%m-%d}"


class ThoughtReframe(TimestampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="thought_reframes",
    )
    negative_thought = models.TextField(max_length=1500)
    reframed_thought = models.TextField(max_length=1500)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self) -> str:
        return f"{self.user_id}:reframe:{self.created_at:%Y-%m-%d}"


class MeditationSession(TimestampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="meditation_sessions",
    )
    title = models.CharField(max_length=120)
    duration_seconds = models.PositiveIntegerField(
        validators=[MinValueValidator(30), MaxValueValidator(7200)]
    )
    completed = models.BooleanField(default=True)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self) -> str:
        return f"{self.user_id}:{self.title}:{self.duration_seconds}s"
