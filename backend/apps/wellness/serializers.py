from django.utils import timezone
from rest_framework import serializers

from .models import GratitudeEntry, MeditationSession, MoodEntry, ThoughtReframe


class MoodEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = MoodEntry
        fields = ("id", "mood", "score", "note", "occurred_at", "created_at", "updated_at")
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_occurred_at(self, value):
        if value > timezone.now() + timezone.timedelta(minutes=5):
            raise serializers.ValidationError("Mood entries cannot be dated in the future.")
        return value

    def create(self, validated_data):
        return MoodEntry.objects.create(user=self.context["request"].user, **validated_data)


class GratitudeEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = GratitudeEntry
        fields = ("id", "items", "note", "created_at", "updated_at")
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_items(self, value):
        if not isinstance(value, list) or not 1 <= len(value) <= 5:
            raise serializers.ValidationError("Provide between 1 and 5 gratitude items.")
        cleaned = [str(item).strip() for item in value if str(item).strip()]
        if len(cleaned) != len(value):
            raise serializers.ValidationError("Gratitude items cannot be blank.")
        if any(len(item) > 240 for item in cleaned):
            raise serializers.ValidationError("Each gratitude item must be 240 characters or fewer.")
        return cleaned

    def create(self, validated_data):
        return GratitudeEntry.objects.create(user=self.context["request"].user, **validated_data)


class ThoughtReframeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ThoughtReframe
        fields = ("id", "negative_thought", "reframed_thought", "created_at", "updated_at")
        read_only_fields = ("id", "created_at", "updated_at")

    def create(self, validated_data):
        return ThoughtReframe.objects.create(user=self.context["request"].user, **validated_data)


class MeditationSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MeditationSession
        fields = ("id", "title", "duration_seconds", "completed", "created_at", "updated_at")
        read_only_fields = ("id", "created_at", "updated_at")

    def create(self, validated_data):
        return MeditationSession.objects.create(user=self.context["request"].user, **validated_data)


class InsightSummarySerializer(serializers.Serializer):
    average_score = serializers.FloatField()
    total_entries = serializers.IntegerField()
    most_frequent_mood = serializers.CharField(allow_null=True)
    weekly_scores = serializers.ListField()


class MoodAIInsightCardSerializer(serializers.Serializer):
    title = serializers.CharField()
    message = serializers.CharField()
    action = serializers.CharField()
    tone = serializers.ChoiceField(choices=("supportive", "celebratory", "grounding", "clinical"))
    priority = serializers.ChoiceField(choices=("low", "medium", "high"))


class MoodAIInsightResponseSerializer(serializers.Serializer):
    current_mood = serializers.CharField(allow_null=True)
    provider = serializers.CharField()
    generated_at = serializers.DateTimeField()
    cards = MoodAIInsightCardSerializer(many=True)
