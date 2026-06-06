from django.contrib import admin

from .models import CallSession, CrisisResource, PractitionerProfile, SupportNotification, SupportThread


@admin.register(PractitionerProfile)
class PractitionerProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "specialization", "availability_status", "contact_phone", "next_available_at")
    list_filter = ("availability_status", "specialization")
    search_fields = ("display_name", "license_number", "contact_phone", "user__email")
    autocomplete_fields = ("user",)
    fieldsets = (
        ("Practitioner account", {"fields": ("user", "display_name", "license_number")}),
        ("Consultation profile", {"fields": ("specialization", "bio", "availability_status", "next_available_at")}),
        ("Connection options", {"fields": ("contact_phone", "video_call_url")}),
    )

    def save_model(self, request, obj, form, change):
        obj.user.role = obj.user.Role.PRACTITIONER
        obj.user.save(update_fields=["role"])
        super().save_model(request, obj, form, change)


@admin.register(SupportThread)
class SupportThreadAdmin(admin.ModelAdmin):
    list_display = ("patient", "thread_type", "status", "contact_method", "practitioner", "updated_at")
    list_filter = ("thread_type", "status", "contact_method", "is_closed")
    search_fields = ("patient__email", "practitioner__user__email", "subject")
    autocomplete_fields = ("patient", "practitioner")
    readonly_fields = ("requested_at", "accepted_at", "ended_at", "created_at", "updated_at")


@admin.register(CallSession)
class CallSessionAdmin(admin.ModelAdmin):
    list_display = ("session", "started_by", "call_type", "status", "started_at", "ended_at")
    list_filter = ("call_type", "status")
    readonly_fields = ("started_at", "ended_at")


@admin.register(SupportNotification)
class SupportNotificationAdmin(admin.ModelAdmin):
    list_display = ("recipient", "notification_type", "session", "read_at", "created_at")
    list_filter = ("notification_type", "read_at")
    readonly_fields = ("created_at",)


admin.site.register(CrisisResource)