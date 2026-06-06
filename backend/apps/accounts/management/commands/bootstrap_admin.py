import os

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.accounts.models import User


TRUTHY = {"1", "true", "yes", "on"}


class Command(BaseCommand):
    help = "Create or promote a Django admin account from DJANGO_SUPERUSER_* environment variables."

    def add_arguments(self, parser):
        parser.add_argument(
            "--noinput",
            "--no-input",
            action="store_true",
            dest="noinput",
            help="Accepted for deploy scripts; this command is always non-interactive.",
        )

    def handle(self, *args, **options):
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "").strip().lower()
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD", "")
        first_name = os.environ.get("DJANGO_SUPERUSER_FIRST_NAME", "MindRise").strip() or "MindRise"
        last_name = os.environ.get("DJANGO_SUPERUSER_LAST_NAME", "Admin").strip() or "Admin"
        reset_password = os.environ.get("DJANGO_SUPERUSER_RESET_PASSWORD", "").strip().lower() in TRUTHY

        if not email or not password:
            self.stdout.write("DJANGO_SUPERUSER_EMAIL/PASSWORD not set; skipping admin bootstrap.")
            return

        if len(password) < 12:
            raise CommandError("DJANGO_SUPERUSER_PASSWORD must be at least 12 characters long.")

        with transaction.atomic():
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    "username": email,
                    "first_name": first_name,
                    "last_name": last_name,
                    "role": User.Role.ADMIN,
                    "is_active": True,
                    "is_staff": True,
                    "is_superuser": True,
                    "is_email_verified": True,
                    "is_approved": True,
                },
            )

            changed_fields = []
            required_values = {
                "username": user.username or email,
                "role": User.Role.ADMIN,
                "is_active": True,
                "is_staff": True,
                "is_superuser": True,
                "is_email_verified": True,
                "is_approved": True,
            }

            if not user.first_name:
                required_values["first_name"] = first_name
            if not user.last_name:
                required_values["last_name"] = last_name

            for field, value in required_values.items():
                if getattr(user, field) != value:
                    setattr(user, field, value)
                    changed_fields.append(field)

            if created or reset_password:
                user.set_password(password)
                changed_fields.append("password")

            if changed_fields:
                user.save(update_fields=sorted(set(changed_fields)))

        if created:
            self.stdout.write(self.style.SUCCESS(f"Created Django admin account: {email}"))
        else:
            suffix = " Password reset from environment." if reset_password else " Password unchanged."
            self.stdout.write(self.style.SUCCESS(f"Django admin account ready: {email}.{suffix}"))