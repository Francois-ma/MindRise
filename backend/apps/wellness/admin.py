from django.contrib import admin

from .models import GratitudeEntry, MeditationSession, MoodEntry, ThoughtReframe


@admin.register(MoodEntry)
class MoodEntryAdmin(admin.ModelAdmin):
    list_display = ("user", "mood", "score", "occurred_at")
    list_filter = ("mood", "score")
    search_fields = ("user__email", "note")
    date_hierarchy = "occurred_at"


admin.site.register(GratitudeEntry)
admin.site.register(ThoughtReframe)
admin.site.register(MeditationSession)
