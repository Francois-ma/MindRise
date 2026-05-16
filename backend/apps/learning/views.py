from rest_framework import permissions, viewsets

from .models import Article, ArticleBookmark, Category, LearningMaterial
from .serializers import (
    ArticleBookmarkSerializer,
    ArticleSerializer,
    CategorySerializer,
    LearningMaterialSerializer,
)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = CategorySerializer
    queryset = Category.objects.all()
    lookup_field = "slug"
    search_fields = ("name", "description")


class ArticleViewSet(viewsets.ReadOnlyModelViewSet):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = ArticleSerializer
    queryset = Article.objects.filter(is_published=True).select_related("category")
    lookup_field = "slug"
    filterset_fields = ("category__slug",)
    search_fields = ("title", "summary", "body")
    ordering_fields = ("published_at", "read_time_minutes")


class LearningMaterialViewSet(viewsets.ReadOnlyModelViewSet):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = LearningMaterialSerializer
    queryset = LearningMaterial.objects.filter(is_published=True).select_related("category")
    lookup_field = "slug"
    filterset_fields = ("category__slug", "material_type")
    search_fields = ("title", "summary")
    ordering_fields = ("published_at", "estimated_minutes")


class ArticleBookmarkViewSet(viewsets.ModelViewSet):
    serializer_class = ArticleBookmarkSerializer
    queryset = ArticleBookmark.objects.none()
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False) or not self.request.user.is_authenticated:
            return self.queryset
        return ArticleBookmark.objects.filter(user=self.request.user).select_related(
            "article",
            "article__category",
        )
