from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CallSessionViewSet,
    CrisisResourceViewSet,
    PractitionerProfileViewSet,
    SupportNotificationViewSet,
    SupportThreadViewSet,
)

router = DefaultRouter()
router.register("practitioners", PractitionerProfileViewSet, basename="practitioner")
router.register("sessions", SupportThreadViewSet, basename="support-session")
router.register("threads", SupportThreadViewSet, basename="support-thread")
router.register("calls", CallSessionViewSet, basename="support-call")
router.register("notifications", SupportNotificationViewSet, basename="support-notification")
router.register("crisis-resources", CrisisResourceViewSet, basename="crisis-resource")

urlpatterns = [path("", include(router.urls))]