from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import GratitudeEntryViewSet, MeditationSessionViewSet, MoodEntryViewSet, ThoughtReframeViewSet

router = DefaultRouter()
router.register("moods", MoodEntryViewSet, basename="mood-entry")
router.register("gratitude", GratitudeEntryViewSet, basename="gratitude-entry")
router.register("reframes", ThoughtReframeViewSet, basename="thought-reframe")
router.register("meditations", MeditationSessionViewSet, basename="meditation-session")

urlpatterns = [path("", include(router.urls))]
