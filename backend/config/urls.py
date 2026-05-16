import re

from django.conf import settings
from django.contrib import admin
from django.urls import include, path, re_path
from drf_spectacular.utils import extend_schema
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from .media import serve_media_file


class HealthCheckSerializer(serializers.Serializer):
    status = serializers.CharField()


class HealthCheckView(APIView):
    authentication_classes = []
    permission_classes = []

    @extend_schema(responses=HealthCheckSerializer)
    def get(self, request):
        return Response({"status": "ok"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", HealthCheckView.as_view(), name="health-check"),
    path("api/v1/auth/", include("apps.accounts.urls")),
    path("api/v1/wellness/", include("apps.wellness.urls")),
    path("api/v1/learning/", include("apps.learning.urls")),
    path("api/v1/support/", include("apps.support.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.SERVE_MEDIA_FILES:
    media_url_pattern = rf"^{re.escape(settings.MEDIA_URL.lstrip('/'))}(?P<path>.*)$"
    urlpatterns += [re_path(media_url_pattern, serve_media_file, name="media-file")]
