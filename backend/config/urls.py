import re

from django.conf import settings
from django.contrib import admin
from django.urls import include, path, re_path
from drf_spectacular.utils import extend_schema
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework import permissions, serializers
from rest_framework.authentication import SessionAuthentication
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


class DebugCorsView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        return Response(
            {
                "CORS_ALLOWED_ORIGINS": settings.CORS_ALLOWED_ORIGINS,
                "CORS_ALLOW_CREDENTIALS": settings.CORS_ALLOW_CREDENTIALS,
                "DEBUG": settings.DEBUG,
                "DJANGO_ENV": settings.DJANGO_ENV,
            }
        )


class AdminSchemaView(SpectacularAPIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [permissions.IsAdminUser]


class AdminSwaggerView(SpectacularSwaggerView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [permissions.IsAdminUser]


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", HealthCheckView.as_view(), name="health-check"),
    path("api/v1/auth/", include("apps.accounts.urls")),
    path("api/v1/admin/", include("apps.accounts.admin_urls")),
    path("api/v1/contact/", include("apps.contact.urls")),
    path("api/v1/chatbot/", include("apps.chatbot.urls")),
    path("api/v1/wellness/", include("apps.wellness.urls")),
    path("api/v1/learning/", include("apps.learning.urls")),
    path("api/v1/support/", include("apps.support.urls")),
    path("api/schema/", AdminSchemaView.as_view(), name="schema"),
    path("api/docs/", AdminSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.DEBUG:
    urlpatterns += [path("api/v1/debug/cors/", DebugCorsView.as_view(), name="debug-cors")]

if settings.SERVE_MEDIA_FILES:
    media_url_pattern = rf"^{re.escape(settings.MEDIA_URL.lstrip('/'))}(?P<path>.*)$"
    urlpatterns += [re_path(media_url_pattern, serve_media_file, name="media-file")]
