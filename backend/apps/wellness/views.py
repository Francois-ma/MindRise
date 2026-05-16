from django.db.models import Avg, Count
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework import decorators, response, viewsets

from .models import GratitudeEntry, MeditationSession, MoodEntry, ThoughtReframe
from .serializers import (
    GratitudeEntrySerializer,
    MeditationSessionSerializer,
    MoodAIInsightResponseSerializer,
    MoodEntrySerializer,
    ThoughtReframeSerializer,
)
from .services import MoodAIInsightService


class OwnedModelViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)


class MoodEntryViewSet(OwnedModelViewSet):
    serializer_class = MoodEntrySerializer
    queryset = MoodEntry.objects.all()
    filterset_fields = ("mood",)
    ordering_fields = ("occurred_at", "score", "created_at")
    search_fields = ("note",)

    @decorators.action(detail=False, methods=["get"])
    def summary(self, request):
        since = timezone.now() - timezone.timedelta(days=30)
        queryset = self.get_queryset().filter(occurred_at__gte=since)
        aggregates = queryset.aggregate(average_score=Avg("score"), total_entries=Count("id"))
        most_frequent = queryset.values("mood").annotate(total=Count("id")).order_by("-total", "mood").first()
        weekly_scores = list(
            queryset.annotate(day=TruncDate("occurred_at"))
            .values("day")
            .annotate(score=Avg("score"))
            .order_by("day")
        )
        return response.Response(
            {
                "average_score": round(aggregates["average_score"] or 0, 2),
                "total_entries": aggregates["total_entries"],
                "most_frequent_mood": most_frequent["mood"] if most_frequent else None,
                "weekly_scores": weekly_scores,
            }
        )

    @decorators.action(detail=False, methods=["get"], url_path="ai-insights")
    def ai_insights(self, request):
        mood = request.query_params.get("mood") or None
        if mood and mood not in MoodEntry.Mood.values:
            return response.Response({"detail": "Unsupported mood value."}, status=400)

        payload = MoodAIInsightService().generate(user=request.user, mood=mood)
        serializer = MoodAIInsightResponseSerializer(payload)
        return response.Response(serializer.data)


class GratitudeEntryViewSet(OwnedModelViewSet):
    serializer_class = GratitudeEntrySerializer
    queryset = GratitudeEntry.objects.all()
    ordering_fields = ("created_at",)


class ThoughtReframeViewSet(OwnedModelViewSet):
    serializer_class = ThoughtReframeSerializer
    queryset = ThoughtReframe.objects.all()
    ordering_fields = ("created_at",)


class MeditationSessionViewSet(OwnedModelViewSet):
    serializer_class = MeditationSessionSerializer
    queryset = MeditationSession.objects.all()
    ordering_fields = ("created_at", "duration_seconds")
