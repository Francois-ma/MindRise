# MindRise Mobile

Production-ready Flutter mobile application for MindRise. The working application lives in `lib/`, with the Django REST backend in `backend/`.

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


## React Website

A multi-page React/Vite official website lives in `website/`. It presents MindRise as an organization and connects to the Django API for health checks, registration, email verification, public learning content, and crisis resources.

```bash
cd website
npm install
npm run dev
```

The local website runs at `http://localhost:5173`. Add this origin to the Render backend before testing API-backed flows in Chrome:

```env
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

For production, set `VITE_API_BASE_URL` to the deployed API URL and add the deployed website domain to `CORS_ALLOWED_ORIGINS`.

## Deploy Backend On Render

The repository has a Render Blueprint in `render.yaml`. In Render, create a new Blueprint from this repo root. It will provision:

- Free Django API web service running Gunicorn
- Free managed PostgreSQL database
- Pre-deploy migrations
- Static collection through WhiteNoise
- Health checks at `/api/v1/health/`

Render will prompt for `RESEND_API_KEY`. The blueprint already includes the MindRise Vercel and local Chrome origins for CORS/CSRF testing. Free Render services are good for testing, but the web service sleeps when idle and the free database is not a long-term production database.

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
