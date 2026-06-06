# MindRise Django Backend

Secure Django REST backend for the MindRise Flutter app.

## Features

- Email-based custom user model
- JWT login, email-verified registration, refresh, logout, and profile APIs
- Resend-powered email verification codes during signup
- OpenAI-backed MindRise chatbot API with rate limiting and safety guidance
- Access/refresh token rotation and refresh token blacklist
- Secure default settings for production: HTTPS redirect, HSTS, secure cookies, nosniff, deny framing
- DRF throttling, pagination, filtering, and consistent error shape
- CORS and CSRF configured by environment
- Private wellness APIs for mood entries, gratitude, thought reframing, and meditation sessions
- Learning APIs for categories, articles, admin-uploaded materials, and user bookmarks
- Support APIs for practitioners, support threads, messages, and crisis resources
- OpenAPI schema at `/api/schema/` and Swagger UI at `/api/docs/`

## Setup

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
cd ..
docker compose --env-file backend/.env up -d postgres
cd backend
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Use a strong `DJANGO_SECRET_KEY` and keep `DJANGO_DEBUG=false` outside local development.

## PostgreSQL

MindRise uses PostgreSQL through `DATABASE_URL`; SQLite remains only as a fallback when no database URL is configured. The committed `docker-compose.yml` runs a local Postgres 17 instance with a named Docker volume.

Local development:

```bash
copy backend\.env.example backend\.env
docker compose --env-file backend/.env up -d postgres
cd backend
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Default local connection:

```env
DATABASE_URL=postgresql://mindrise:change-this-local-password@localhost:5432/mindrise
```

For production, use a managed PostgreSQL database, rotate the local example password, and set:

```env
DATABASE_SSL_REQUIRE=true
DATABASE_CONN_HEALTH_CHECKS=true
DATABASE_CONN_MAX_AGE=600
```

Do not commit real database credentials. Put them only in environment variables or your deployment secret manager.

## Render Deployment

The repository includes a Render Blueprint at `render.yaml`. It creates:

- `mindrise-api`: free Python web service for Django/Gunicorn.
- `mindrise-postgres`: free managed Render PostgreSQL database.
- Ephemeral media storage at `/opt/render/project/src/backend/media` for testing uploads.
- Path-safe media serving for uploaded learning materials through `SERVE_MEDIA_FILES=true`.
- A pre-deploy migration command: `python manage.py migrate --noinput`.
- A health check at `/api/v1/health/`.

Deploy steps:

1. Push the repository to GitHub/GitLab/Bitbucket.
2. In Render, choose `New` -> `Blueprint`.
3. Select the repository and use the root `render.yaml`.
4. Fill the prompted `RESEND_API_KEY` secret if you want signup verification emails to work.
5. Deploy. Render runs the build script, collects static files, runs migrations, and starts Gunicorn.

For mobile-only API use, `CORS_ALLOWED_ORIGINS` can stay empty. If you use Django Admin or a web client from a browser, set:

```env
DJANGO_CSRF_TRUSTED_ORIGINS=https://your-api.onrender.com,https://your-custom-domain.com
CORS_ALLOWED_ORIGINS=https://your-web-client.com
```

For the MindRise production website, keep both the Vercel preview domain and the custom domains in the Render API environment:

```env
DJANGO_CSRF_TRUSTED_ORIGINS=https://mindrise-api.onrender.com,https://mind-rise-coral.vercel.app,https://mindrisewellness.org,https://www.mindrisewellness.org
CORS_ALLOWED_ORIGINS=https://mind-rise-coral.vercel.app,https://mindrisewellness.org,https://www.mindrisewellness.org
```

The Blueprint uses Render's private PostgreSQL connection string, so `DATABASE_SSL_REQUIRE=false` is intentional there. If you connect to an external PostgreSQL database over the public internet, set `DATABASE_SSL_REQUIRE=true`.

The free Render web service uses an ephemeral filesystem, so uploaded learning materials can disappear after redeploys, restarts, or idle spin-downs. For production, upgrade the web service and attach a persistent disk or move uploads to object storage such as S3/R2.

## Main Endpoints

- `POST /api/v1/auth/register/`
- `POST /api/v1/auth/email/verify/`
- `POST /api/v1/auth/email/resend/`
- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/token/refresh/`
- `POST /api/v1/auth/logout/`
- `POST /api/v1/chatbot/message/`
- `GET/PATCH /api/v1/auth/me/`
- `GET/POST /api/v1/wellness/moods/`
- `GET /api/v1/wellness/moods/summary/`
- `GET /api/v1/wellness/moods/ai-insights/`
- `GET /api/v1/wellness/moods/ai-insights/?mood=stressed`
- `GET/POST /api/v1/wellness/gratitude/`
- `GET/POST /api/v1/wellness/reframes/`
- `GET/POST /api/v1/wellness/meditations/`
- `GET /api/v1/learning/articles/`
- `GET /api/v1/learning/materials/`
- `GET/POST /api/v1/learning/bookmarks/`
- `GET /api/v1/support/practitioners/`
- `PATCH /api/v1/support/practitioners/me/availability/`
- `GET/POST /api/v1/support/threads/`
- `GET/POST /api/v1/support/threads/{id}/messages/`

## Creating the First Admin on Render Free

Render Free web services do not provide shell access, so the deployment runs a safe admin bootstrap command after migrations. It only creates or promotes an admin account when these environment variables are set on the `mindrise-api` service:

```env
DJANGO_SUPERUSER_EMAIL=your-admin-email@example.com
DJANGO_SUPERUSER_PASSWORD=use-a-long-random-password
DJANGO_SUPERUSER_FIRST_NAME=MindRise
DJANGO_SUPERUSER_LAST_NAME=Admin
```

Deploy or redeploy the API after setting them, then log in at `/admin/`. After the admin account works, remove `DJANGO_SUPERUSER_PASSWORD` from Render and redeploy. To intentionally reset the password later, temporarily set `DJANGO_SUPERUSER_RESET_PASSWORD=true` with a new password and redeploy once.

## Adding Practitioners

Admins can add practitioners in Django Admin:

1. Create a user account for the practitioner.
2. Open `Practitioner profiles`.
3. Add a profile with display name, specialization, license number, availability, phone/video connection options, and optional bio.

Saving a practitioner profile automatically marks the linked user as `practitioner`. Patients can then see online practitioners in the Support screen, start a private text thread, or use configured phone and video call options.

## Supabase Profile Picture Storage

Profile pictures use a dedicated Django storage alias. Local development stores them under `backend/media/accounts/profile-pictures`; production can send only profile pictures to a public Supabase Storage bucket while other MindRise uploads keep their existing storage configuration.

1. In Supabase Storage, create a **public** bucket named `mindrise-profile-images`.
2. In Supabase project settings, create S3 access keys for the backend only. Never expose the secret key to React or Flutter.
3. Set these values on the Render API service:

```env
SUPABASE_STORAGE_ENABLED=true
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_STORAGE_BUCKET=mindrise-profile-images
SUPABASE_STORAGE_PUBLIC_URL=https://your-project-ref.supabase.co/storage/v1/object/public/mindrise-profile-images
SUPABASE_S3_ACCESS_KEY_ID=your-s3-access-key
SUPABASE_S3_SECRET_ACCESS_KEY=your-s3-secret-key
SUPABASE_S3_REGION=your-project-region
```

Supabase Storage keeps object metadata in its `storage.objects` table. MindRise stores only the randomized object path in the user record. Images are limited to 5 MB, validated as images, and replaced/removed through the authenticated `/api/v1/auth/me/` endpoint.
## Uploading Learning Materials

Admins can upload patient education resources in Django Admin under `Learning materials`.

- Add or reuse a category.
- Create a material with a title, summary, type, estimated minutes, and publish date.
- Upload one file or provide one HTTPS external URL.
- Supported upload types: PDF, Word, PowerPoint, JPG, PNG, MP3, M4A, WAV, MP4, and MOV.
- Uploaded files are limited to 50 MB and are served from `DJANGO_MEDIA_URL`.

In production, place `DJANGO_MEDIA_ROOT` on durable private storage or connect Django storage to a trusted object-storage/CDN layer. Keep `DJANGO_DEBUG=false` so external material URLs must use HTTPS.

## Auth Response Contract

Registration creates an unverified account and sends a 6-digit code through Resend:

```json
{
  "email": "francois@example.com",
  "detail": "Account created. Check your email for the verification code."
}
```

Tokens are issued only after email verification succeeds.

```json
{
  "access": "jwt-access-token",
  "refresh": "jwt-refresh-token",
  "user": {
    "id": 1,
    "email": "francois@example.com",
    "name": "Francois",
    "first_name": "Francois",
    "last_name": "",
    "role": "patient"
  }
}
```

## Resend Email Verification

Configure these values in production:

```env
RESEND_API_URL=https://api.resend.com
RESEND_API_KEY=re_...
RESEND_FROM_EMAIL="MindRise <onboarding@your-verified-domain.com>"
EMAIL_VERIFICATION_CODE_TTL_MINUTES=15
EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS=60
```

Use a verified Resend domain for `RESEND_FROM_EMAIL`. The API key stays server-side in Django and is never exposed to Flutter. When `DJANGO_DEBUG=true` and Resend is not configured, the backend logs the verification code for local development only.


## AI Chatbot

The website chatbot posts to `/api/v1/chatbot/message/`. The browser never receives the OpenAI API key; React calls Django, and Django calls OpenAI through the Responses API.

Set these values in Render on the `mindrise-api` service:

```env
OPENAI_API_URL=https://api.openai.com/v1
OPENAI_API_KEY=your-openai-api-key
OPENAI_CHATBOT_MODEL=gpt-5.5
OPENAI_CHATBOT_TIMEOUT_SECONDS=20
OPENAI_CHATBOT_MAX_OUTPUT_TOKENS=500
OPENAI_CHATBOT_REASONING_EFFORT=low
OPENAI_CHATBOT_VERBOSITY=low
```

The chatbot endpoint is public for website visitors and rate-limited with the `chatbot` throttle scope. It does not store chat messages in the database. The service includes a deterministic crisis-safety response for urgent self-harm or harm-to-others wording before making an OpenAI request.
## Checks

```bash
ruff check .
pytest
python manage.py check --deploy
```

Initial migrations are committed. Use `python manage.py makemigrations --check --dry-run` in CI to catch model drift.

## AI Mood Insights

Mood insights are generated by `MoodAIInsightService`. By default `AI_INSIGHTS_PROVIDER=local`, which keeps all processing inside Django and creates safe, mood-specific guidance from the user's recent mood history.

To connect a hosted AI service, set:

```env
AI_INSIGHTS_PROVIDER=http
AI_INSIGHTS_ENDPOINT=https://your-ai-service.example.com/mood-insights
AI_INSIGHTS_API_KEY=...
AI_INSIGHTS_INCLUDE_NOTES=false
```

Keep `AI_INSIGHTS_INCLUDE_NOTES=false` unless you have explicit consent and a compliant data-processing agreement, because mood notes can contain sensitive health information.


## Contact Form Email Delivery

The website contact form posts to `/api/v1/contact/message/` and sends the message directly to `CONTACT_RECIPIENT_EMAIL` through Resend. The submitted email address is included inside the email body for manual replies; it is not used as a Resend `reply_to` header. A `503` response means Django reached Resend but email delivery failed or Resend is not configured.

For production, verify `mindrisewellness.org` in Resend first, then set these Render environment variables:

```env
RESEND_API_KEY=your-resend-api-key
RESEND_FROM_EMAIL="MindRise <no-reply@mindrisewellness.org>"
CONTACT_RECIPIENT_EMAIL=mindriserwanda@gmail.com
```

Do not use `onboarding@resend.dev` for production contact messages unless the recipient is the same email address as the Resend account. Resend restricts that testing sender.
