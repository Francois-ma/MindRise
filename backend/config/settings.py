from datetime import timedelta
from pathlib import Path

from decouple import Csv, config
from dj_database_url import parse as parse_database_url


def optional_int(value):
    if value in (None, "", "none", "None", "null"):
        return None
    return int(value)


BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config("DJANGO_SECRET_KEY", default="")
DEBUG = config("DJANGO_DEBUG", default=False, cast=bool)
DJANGO_ENV = config("DJANGO_ENV", default="local")
RUNNING_ON_RENDER = config("RENDER", default=False, cast=bool)
DRF_NUM_PROXIES = config(
    "DRF_NUM_PROXIES",
    default="1" if RUNNING_ON_RENDER else "",
    cast=optional_int,
)

if not SECRET_KEY and not DEBUG:
    raise RuntimeError("DJANGO_SECRET_KEY is required when DJANGO_DEBUG=false.")

SECRET_KEY = SECRET_KEY or "local-only-insecure-dev-key-change-me"
ALLOWED_HOSTS = config("DJANGO_ALLOWED_HOSTS", default="localhost,127.0.0.1", cast=Csv())
ALLOWED_HOSTS = list(ALLOWED_HOSTS)
RENDER_EXTERNAL_HOSTNAME = config("RENDER_EXTERNAL_HOSTNAME", default="")
if RENDER_EXTERNAL_HOSTNAME and RENDER_EXTERNAL_HOSTNAME not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(RENDER_EXTERNAL_HOSTNAME)

CSRF_TRUSTED_ORIGINS = list(config("DJANGO_CSRF_TRUSTED_ORIGINS", default="", cast=Csv()))
RENDER_EXTERNAL_URL = config("RENDER_EXTERNAL_URL", default="")
if RENDER_EXTERNAL_URL and RENDER_EXTERNAL_URL not in CSRF_TRUSTED_ORIGINS:
    CSRF_TRUSTED_ORIGINS.append(RENDER_EXTERNAL_URL)

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "django_filters",
    "drf_spectacular",
    "rest_framework",
    "rest_framework_simplejwt.token_blacklist",
    "apps.accounts",
    "apps.contact",
    "apps.wellness",
    "apps.learning",
    "apps.support",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

DATABASE_URL = config("DATABASE_URL", default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}")
DATABASE_CONN_MAX_AGE = config("DATABASE_CONN_MAX_AGE", default=600, cast=int)
DATABASE_CONN_HEALTH_CHECKS = config("DATABASE_CONN_HEALTH_CHECKS", default=True, cast=bool)
DATABASE_DISABLE_SERVER_SIDE_CURSORS = config(
    "DATABASE_DISABLE_SERVER_SIDE_CURSORS",
    default=False,
    cast=bool,
)
DATABASE_SSL_REQUIRE = config("DATABASE_SSL_REQUIRE", default=not DEBUG, cast=bool)
DATABASE_IS_POSTGRES = DATABASE_URL.startswith(("postgres://", "postgresql://"))
DATABASES = {
    "default": parse_database_url(
        DATABASE_URL,
        conn_max_age=DATABASE_CONN_MAX_AGE,
        conn_health_checks=DATABASE_CONN_HEALTH_CHECKS,
        disable_server_side_cursors=DATABASE_DISABLE_SERVER_SIDE_CURSORS,
        ssl_require=DATABASE_IS_POSTGRES and DATABASE_SSL_REQUIRE,
    )
}

AUTH_USER_MODEL = "accounts.User"
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 10}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = config("DJANGO_MEDIA_URL", default="/media/")
MEDIA_ROOT = Path(config("DJANGO_MEDIA_ROOT", default=str(BASE_DIR / "media")))
if not MEDIA_ROOT.is_absolute():
    MEDIA_ROOT = BASE_DIR / MEDIA_ROOT
SERVE_MEDIA_FILES = config("SERVE_MEDIA_FILES", default=DEBUG, cast=bool)
PUBLIC_MEDIA_PREFIXES = tuple(config("PUBLIC_MEDIA_PREFIXES", default="learning/materials", cast=Csv()))
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
}
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

CORS_ALLOWED_ORIGINS = config("CORS_ALLOWED_ORIGINS", default="", cast=Csv())
CORS_ALLOW_CREDENTIALS = config("CORS_ALLOW_CREDENTIALS", default=False, cast=bool)

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ("rest_framework_simplejwt.authentication.JWTAuthentication",),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "NUM_PROXIES": DRF_NUM_PROXIES,
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.OrderingFilter",
        "rest_framework.filters.SearchFilter",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.LimitOffsetPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_THROTTLE_CLASSES": (
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ),
    "DEFAULT_THROTTLE_RATES": {
        "anon": "20/minute",
        "user": "120/minute",
        "auth": "8/minute",
        "contact": "5/minute",
    },
    "EXCEPTION_HANDLER": "config.exceptions.api_exception_handler",
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=config("ACCESS_TOKEN_LIFETIME_MINUTES", default=15, cast=int)),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=config("REFRESH_TOKEN_LIFETIME_DAYS", default=7, cast=int)),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}

SPECTACULAR_SETTINGS = {
    "TITLE": "MindRise API",
    "DESCRIPTION": "Secure REST API for MindRise mobile wellness workflows.",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}

SECURE_SSL_REDIRECT = config("SECURE_SSL_REDIRECT", default=not DEBUG, cast=bool)
TRUST_PROXY_SSL_HEADER = config(
    "TRUST_PROXY_SSL_HEADER",
    default=RUNNING_ON_RENDER,
    cast=bool,
)
if TRUST_PROXY_SSL_HEADER:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = config(
    "USE_X_FORWARDED_HOST",
    default=RUNNING_ON_RENDER,
    cast=bool,
)
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_HSTS_SECONDS = 31536000 if not DEBUG else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = not DEBUG
SECURE_HSTS_PRELOAD = not DEBUG
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "same-origin"
X_FRAME_OPTIONS = "DENY"
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"

EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = config("EMAIL_HOST", default="")
EMAIL_PORT = config("EMAIL_PORT", default=587, cast=int)
EMAIL_USE_TLS = True
EMAIL_HOST_USER = config("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = config("EMAIL_HOST_PASSWORD", default="")
DEFAULT_FROM_EMAIL = config("DEFAULT_FROM_EMAIL", default="no-reply@mindrise.local")

RESEND_API_URL = config("RESEND_API_URL", default="https://api.resend.com")
RESEND_API_KEY = config("RESEND_API_KEY", default="")
RESEND_FROM_EMAIL = config("RESEND_FROM_EMAIL", default="")
RESEND_REPLY_TO_EMAIL = config("RESEND_REPLY_TO_EMAIL", default="")
RESEND_TIMEOUT_SECONDS = config("RESEND_TIMEOUT_SECONDS", default=8, cast=int)
CONTACT_RECIPIENT_EMAIL = config("CONTACT_RECIPIENT_EMAIL", default="mindriserwanda@gmail.com")
CONTACT_EMAIL_SUBJECT_PREFIX = config("CONTACT_EMAIL_SUBJECT_PREFIX", default="[MindRise Contact]")
EMAIL_VERIFICATION_CODE_TTL_MINUTES = config("EMAIL_VERIFICATION_CODE_TTL_MINUTES", default=15, cast=int)
EMAIL_VERIFICATION_MAX_ATTEMPTS = config("EMAIL_VERIFICATION_MAX_ATTEMPTS", default=5, cast=int)
EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS = config(
    "EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS",
    default=60,
    cast=int,
)

AI_INSIGHTS_PROVIDER = config("AI_INSIGHTS_PROVIDER", default="local")
AI_INSIGHTS_ENDPOINT = config("AI_INSIGHTS_ENDPOINT", default="")
AI_INSIGHTS_API_KEY = config("AI_INSIGHTS_API_KEY", default="")
AI_INSIGHTS_TIMEOUT_SECONDS = config("AI_INSIGHTS_TIMEOUT_SECONDS", default=8, cast=int)
AI_INSIGHTS_INCLUDE_NOTES = config("AI_INSIGHTS_INCLUDE_NOTES", default=False, cast=bool)
