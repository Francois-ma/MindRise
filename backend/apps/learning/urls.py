from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ArticleBookmarkViewSet, ArticleViewSet, CategoryViewSet, LearningMaterialViewSet

router = DefaultRouter()
router.register("categories", CategoryViewSet, basename="learning-category")
router.register("articles", ArticleViewSet, basename="learning-article")
router.register("materials", LearningMaterialViewSet, basename="learning-material")
router.register("bookmarks", ArticleBookmarkViewSet, basename="article-bookmark")

urlpatterns = [path("", include(router.urls))]
