from django.contrib import admin

from .models import CrisisResource, PractitionerProfile, SupportMessage, SupportThread


@admin.register(PractitionerProfile)
class PractitionerProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "specialization", "is_available", "contact_phone", "next_available_at")
    list_filter = ("is_available", "specialization")
    search_fields = ("display_name", "license_number", "contact_phone", "user__email")
    autocomplete_fields = ("user",)
    fieldsets = (
        ("Practitioner account", {"fields": ("user", "display_name", "license_number")}),
        ("Consultation profile", {"fields": ("specialization", "bio", "is_available", "next_available_at")}),
        ("Connection options", {"fields": ("contact_phone", "video_call_url")}),
    )

    def save_model(self, request, obj, form, change):
        obj.user.role = obj.user.Role.PRACTITIONER
        obj.user.save(update_fields=["role"])
        super().save_model(request, obj, form, change)


class SupportMessageInline(admin.TabularInline):
    model = SupportMessage
    extra = 0
    readonly_fields = ("created_at",)


@admin.register(SupportThread)
class SupportThreadAdmin(admin.ModelAdmin):
    list_display = ("patient", "thread_type", "contact_method", "practitioner", "is_closed", "updated_at")
    list_filter = ("thread_type", "contact_method", "is_closed")
    search_fields = ("patient__email", "subject")
    autocomplete_fields = ("patient", "practitioner")
    inlines = [SupportMessageInline]


admin.site.register(CrisisResource)