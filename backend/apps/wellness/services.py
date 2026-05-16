import json
import logging
from dataclasses import dataclass
from typing import Any
from urllib import error, request
from urllib.parse import urlparse

from django.conf import settings
from django.db.models import Avg, Count
from django.utils import timezone

from .models import MoodEntry

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class MoodInsightCard:
    title: str
    message: str
    action: str
    tone: str = "supportive"
    priority: str = "medium"

    def as_dict(self) -> dict[str, str]:
        return {
            "title": self.title,
            "message": self.message,
            "action": self.action,
            "tone": self.tone,
            "priority": self.priority,
        }


class MoodAIInsightService:
    def generate(self, *, user, mood: str | None = None) -> dict[str, Any]:
        context = self._build_context(user=user, mood=mood)
        cards = self._generate_external(context) or self._generate_local(context)
        return {
            "current_mood": context["current_mood"],
            "provider": settings.AI_INSIGHTS_PROVIDER,
            "generated_at": timezone.now(),
            "cards": [card.as_dict() for card in cards[:4]],
        }

    def _build_context(self, *, user, mood: str | None) -> dict[str, Any]:
        since = timezone.now() - timezone.timedelta(days=30)
        queryset = MoodEntry.objects.filter(user=user, occurred_at__gte=since)
        if mood:
            queryset = queryset.filter(mood=mood)

        recent_entries = list(queryset.order_by("-occurred_at")[:12])
        latest = recent_entries[0] if recent_entries else None
        aggregates = queryset.aggregate(average_score=Avg("score"), total_entries=Count("id"))
        most_frequent = queryset.values("mood").annotate(total=Count("id")).order_by("-total", "mood").first()

        payload_entries = []
        for entry in recent_entries:
            item = {
                "mood": entry.mood,
                "score": entry.score,
                "occurred_at": entry.occurred_at.isoformat(),
            }
            if settings.AI_INSIGHTS_INCLUDE_NOTES and entry.note:
                item["note"] = entry.note[:240]
            payload_entries.append(item)

        return {
            "current_mood": mood or latest.mood if latest else mood,
            "average_score": round(aggregates["average_score"] or 0, 2),
            "total_entries": aggregates["total_entries"],
            "most_frequent_mood": most_frequent["mood"] if most_frequent else None,
            "recent_entries": payload_entries,
        }

    def _generate_external(self, context: dict[str, Any]) -> list[MoodInsightCard] | None:
        if settings.AI_INSIGHTS_PROVIDER != "http" or not settings.AI_INSIGHTS_ENDPOINT:
            return None

        body = json.dumps(
            {
                "task": "Generate safe, concise mental wellness insights based on mood data.",
                "constraints": [
                    "Do not diagnose.",
                    "Do not claim emergency assessment.",
                    "Return practical, supportive, non-judgmental guidance.",
                    "Return JSON with a cards array.",
                ],
                "context": context,
            }
        ).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        if settings.AI_INSIGHTS_API_KEY:
            headers["Authorization"] = f"Bearer {settings.AI_INSIGHTS_API_KEY}"

        parsed_url = urlparse(settings.AI_INSIGHTS_ENDPOINT)
        allowed_schemes = {"https"} if not settings.DEBUG else {"http", "https"}
        if parsed_url.scheme not in allowed_schemes:
            logger.warning("AI insights provider endpoint has an unsupported scheme.")
            return None

        try:
            req = request.Request(  # noqa: S310 - scheme is validated above.
                settings.AI_INSIGHTS_ENDPOINT,
                data=body,
                headers=headers,
                method="POST",
            )
            with request.urlopen(req, timeout=settings.AI_INSIGHTS_TIMEOUT_SECONDS) as res:  # noqa: S310
                raw = json.loads(res.read().decode("utf-8"))
        except (TimeoutError, OSError, error.URLError, json.JSONDecodeError) as exc:
            logger.warning("AI insights provider failed; using local fallback: %s", exc)
            return None

        cards = raw.get("cards") if isinstance(raw, dict) else None
        if not isinstance(cards, list):
            return None

        parsed: list[MoodInsightCard] = []
        for card in cards:
            if not isinstance(card, dict):
                continue
            title = str(card.get("title", "")).strip()
            message = str(card.get("message", "")).strip()
            action = str(card.get("action", "")).strip()
            if not title or not message or not action:
                continue
            parsed.append(
                MoodInsightCard(
                    title=title[:90],
                    message=message[:320],
                    action=action[:160],
                    tone=str(card.get("tone", "supportive")),
                    priority=str(card.get("priority", "medium")),
                )
            )
        return parsed or None

    def _generate_local(self, context: dict[str, Any]) -> list[MoodInsightCard]:
        mood = context["current_mood"]
        average = context["average_score"]
        total_entries = context["total_entries"]

        if total_entries == 0 and mood is None:
            return [
                MoodInsightCard(
                    title="Start with one check-in",
                    message=(
                        "Once you record a mood, MindRise will personalize patterns and suggested next steps."
                    ),
                    action="Log how you feel right now.",
                    tone="grounding",
                    priority="low",
                )
            ]

        mood_cards = {
            MoodEntry.Mood.STRESSED: MoodInsightCard(
                title="Your stress signal is asking for space",
                message=(
                    "Recent stressed check-ins suggest your nervous system may need a short reset "
                    "before the next task."
                ),
                action="Try a 3-minute breathing exercise, then write one sentence about the pressure point.",
                tone="grounding",
                priority="high",
            ),
            MoodEntry.Mood.SAD: MoodInsightCard(
                title="Low mood deserves gentle support",
                message=(
                    "Your recent mood pattern leans heavy. Small contact and simple routines can "
                    "help you avoid carrying it alone."
                ),
                action="Message support or write one thing you need from today.",
                tone="supportive",
                priority="high",
            ),
            MoodEntry.Mood.ANGRY: MoodInsightCard(
                title="Pause before responding",
                message=(
                    "Anger can carry useful information, but it is easier to use after your body "
                    "has cooled down."
                ),
                action="Do one grounding round, then name the boundary or need underneath the feeling.",
                tone="grounding",
                priority="medium",
            ),
            MoodEntry.Mood.HAPPY: MoodInsightCard(
                title="Protect what is working",
                message=(
                    "Your positive mood is useful data. Notice the habits, people, or moments "
                    "that helped create it."
                ),
                action="Save one note about what supported this mood.",
                tone="celebratory",
                priority="low",
            ),
            MoodEntry.Mood.CALM: MoodInsightCard(
                title="Calm is a pattern worth repeating",
                message=(
                    "Calm entries can reveal the routines that stabilize you. Keep tracking the "
                    "conditions around them."
                ),
                action="Record what happened before this calm moment.",
                tone="supportive",
                priority="low",
            ),
            MoodEntry.Mood.ENERGETIC: MoodInsightCard(
                title="Use your energy with intention",
                message=(
                    "Energetic moods are great for momentum, especially when paired with a clear "
                    "stopping point."
                ),
                action="Pick one important task and define when you will rest.",
                tone="celebratory",
                priority="low",
            ),
            MoodEntry.Mood.NEUTRAL: MoodInsightCard(
                title="Neutral still gives useful information",
                message=(
                    "Neutral days can be the baseline that helps MindRise detect what lifts or "
                    "drains you later."
                ),
                action="Add a short note about sleep, food, or workload today.",
                tone="clinical",
                priority="low",
            ),
        }

        primary = mood_cards.get(mood, mood_cards[MoodEntry.Mood.NEUTRAL])
        cards = [primary]

        if average and average <= 4:
            cards.append(
                MoodInsightCard(
                    title="Your recent average is low",
                    message=(
                        "Several lower scores close together can be a sign to reduce load and "
                        "increase support."
                    ),
                    action="Consider starting a support chat or planning a low-demand recovery block.",
                    tone="supportive",
                    priority="high",
                )
            )
        elif average >= 7:
            cards.append(
                MoodInsightCard(
                    title="Your trend is looking resilient",
                    message="Your recent average suggests your current routines may be helping.",
                    action="Keep tracking so the app can identify which routines matter most.",
                    tone="celebratory",
                    priority="low",
                )
            )
        else:
            cards.append(
                MoodInsightCard(
                    title="Look for the small lever",
                    message=(
                        "Your recent scores sit in the middle range, which often means one small "
                        "change can be visible."
                    ),
                    action="Choose one reset, one journal note, or one support message today.",
                    tone="clinical",
                    priority="medium",
                )
            )

        cards.append(
            MoodInsightCard(
                title="Privacy note",
                message="These insights are generated from your own mood history and are not a diagnosis.",
                action="Use them as guidance, and reach support if you feel unsafe or overwhelmed.",
                tone="clinical",
                priority="medium",
            )
        )
        return cards
