from drf_spectacular.utils import OpenApiTypes, extend_schema_field
from rest_framework import serializers

from .models import Article, ArticleBookmark, Category, LearningMaterial


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "slug", "description")


class ArticleSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    is_bookmarked = serializers.SerializerMethodField()

    class Meta:
        model = Article
        fields = (
            "id",
            "category",
            "title",
            "slug",
            "summary",
            "body",
            "read_time_minutes",
            "published_at",
            "is_bookmarked",
        )

    @extend_schema_field(OpenApiTypes.BOOL)
    def get_is_bookmarked(self, obj) -> bool:
        request = self.context.get("request")
        if request is None or not request.user.is_authenticated:
            return False
        return ArticleBookmark.objects.filter(user=request.user, article=obj).exists()


class ArticleBookmarkSerializer(serializers.ModelSerializer):
    article = ArticleSerializer(read_only=True)
    article_id = serializers.PrimaryKeyRelatedField(
        queryset=Article.objects.filter(is_published=True),
        source="article",
        write_only=True,
    )

    class Meta:
        model = ArticleBookmark
        fields = ("id", "article", "article_id", "created_at")
        read_only_fields = ("id", "created_at")

    def create(self, validated_data):
        bookmark, _ = ArticleBookmark.objects.get_or_create(
            user=self.context["request"].user,
            article=validated_data["article"],
        )
        return bookmark


class LearningMaterialSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    material_url = serializers.SerializerMethodField()

    class Meta:
        model = LearningMaterial
        fields = (
            "id",
            "category",
            "title",
            "slug",
            "summary",
            "material_type",
            "material_url",
            "estimated_minutes",
            "file_size_bytes",
            "published_at",
        )

    @extend_schema_field(OpenApiTypes.URI)
    def get_material_url(self, obj) -> str:
        if obj.external_url:
            return obj.external_url
        if not obj.file:
            return ""
        request = self.context.get("request")
        file_url = obj.file.url
        return request.build_absolute_uri(file_url) if request is not None else file_url
