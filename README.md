# MindRise Mobile

Production-ready Flutter rebuild of the MindRise Figma mobile design. The original Figma-generated React/Vite files are kept under `src/` as reference only; the working application is the Flutter project in `lib/`.

## Stack

- Flutter 3.38.4 / Dart 3.10.3
- Material 3, light and dark themes
- Riverpod for app/auth state
- GoRouter with authenticated redirects and bottom-tab shell navigation
- Dio API layer with JWT access/refresh token support
- Flutter Secure Storage for tokens
- Firebase Cloud Messaging initialization hooks
- fl_chart for insights visualizations

## Project Structure

```text
backend/             Django REST API backend
lib/
  core/
    config/          Environment configuration
    network/         Dio client, interceptors, secure token storage
    notifications/   Firebase Cloud Messaging setup
    router/          GoRouter app routes
    theme/           Material 3 color, typography, spacing system
    widgets/         Reusable buttons, cards, headers, fields, states
  features/
    auth/
    dashboard/
    home/
    mood/
    insights/
    reset/
    learn/
    support/
    profile/
```

## Backend

A secure Django REST backend lives in `backend/`. It provides JWT auth, PostgreSQL persistence, wellness tracking, learning articles and uploaded materials, support messaging, throttling, CORS, OpenAPI docs, and production-focused security settings.

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
cd ..
docker compose --env-file backend/.env up -d postgres
cd backend
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

See `backend/README.md` for endpoint details.

## Deploy Backend On Render

The repository has a production Blueprint in `render.yaml`. In Render, create a new Blueprint from this repo. It will provision:

- Django API web service running Gunicorn
- Managed PostgreSQL
- Pre-deploy migrations
- Static collection through WhiteNoise
- Persistent media disk for uploaded learning materials
- Health checks at `/api/v1/health/`

Render will prompt for secrets such as `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, CORS/CSRF origins, and optional AI provider credentials.

## Setup

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://mindrise.onrender.com/api/v1
```

For local development, copy `.env.example` values into your run configuration as `--dart-define` entries. Flutter does not load `.env` files automatically.

## Backend Contract

The app is prepared for a Django REST API using email verification and JWT endpoints:

- `POST /auth/login/`
- `POST /auth/register/`
- `POST /auth/email/verify/`
- `POST /auth/email/resend/`
- `POST /auth/token/refresh/`
- `GET /auth/me/`

Registration sends a Resend verification code and does not return tokens until the code is verified. Expected verification/login response:

```json
{
  "access": "jwt-access-token",
  "refresh": "jwt-refresh-token",
  "user": {
    "name": "Francois",
    "email": "francois@mindrise.com"
  }
}
```

The app uses the configured Django API directly and stores JWT access/refresh tokens in secure storage.

## Firebase Messaging

Add platform configuration before release:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

`NotificationService` requests permission, enables FCM auto-init, obtains an FCM token, and registers a background handler. The app catches Firebase initialization errors so local builds still run before Firebase files are added.

## Quality Checks

```bash
dart format lib test
flutter analyze
flutter test
```

Current status:

- `flutter analyze`: no issues found
- `flutter test`: all tests passed
