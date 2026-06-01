from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import EmailVerificationChallenge, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ("email",)
    list_display = ("email", "name", "role", "is_active", "is_staff", "created_at")
    list_filter = ("role", "is_active", "is_staff", "is_email_verified")
    search_fields = ("email", "first_name", "last_name")
    readonly_fields = ("created_at", "updated_at", "last_login")

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        (
            "Personal info",
            {"fields": ("first_name", "last_name", "phone_number", "date_of_birth", "timezone")},
        ),
        ("Security", {"fields": ("role", "is_email_verified", "accepted_terms_at")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "first_name", "last_name", "password1", "password2", "role", "is_staff"),
            },
        ),
    )


@admin.register(EmailVerificationChallenge)
class EmailVerificationChallengeAdmin(admin.ModelAdmin):
    list_display = ("sent_to_email", "user", "sent_at", "expires_at", "used_at", "delivery_provider")
    list_filter = ("delivery_provider", "used_at", "expires_at")
    readonly_fields = (
        "user",
        "sent_to_email",
        "code_hash",
        "expires_at",
        "sent_at",
        "used_at",
        "delivery_provider",
        "provider_message_id",
        "request_ip",
    )
    search_fields = ("sent_to_email", "user__email", "provider_message_id")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False