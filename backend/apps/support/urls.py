from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import CrisisResourceViewSet, PractitionerProfileViewSet, SupportThreadViewSet

router = DefaultRouter()
router.register("practitioners", PractitionerProfileViewSet, basename="practitioner")
router.register("threads", SupportThreadViewSet, basename="support-thread")
router.register("crisis-resources", CrisisResourceViewSet, basename="crisis-resource")

urlpatterns = [path("", include(router.urls))]
