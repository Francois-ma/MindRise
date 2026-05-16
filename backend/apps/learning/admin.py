from django.contrib import admin

from .models import Article, ArticleBookmark, Category, LearningMaterial


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    prepopulated_fields = {"slug": ("name",)}
    search_fields = ("name",)


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "is_published", "published_at")
    list_filter = ("category", "is_published")
    prepopulated_fields = {"slug": ("title",)}
    search_fields = ("title", "summary", "body")


@admin.register(LearningMaterial)
class LearningMaterialAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "category",
        "material_type",
        "is_published",
        "published_at",
        "file_size_bytes",
    )
    list_filter = ("category", "material_type", "is_published")
    prepopulated_fields = {"slug": ("title",)}
    readonly_fields = ("file_size_bytes", "created_at", "updated_at")
    search_fields = ("title", "summary")
    fieldsets = (
        (None, {"fields": ("category", "title", "slug", "summary", "material_type")}),
        ("Material", {"fields": ("file", "external_url", "estimated_minutes", "file_size_bytes")}),
        ("Publishing", {"fields": ("is_published", "published_at")}),
        ("Audit", {"classes": ("collapse",), "fields": ("created_at", "updated_at")}),
    )


admin.site.register(ArticleBookmark)
