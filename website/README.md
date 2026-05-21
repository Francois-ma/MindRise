# MindRise Website

Official multi-page React/Vite website for MindRise Wellness Initiative: a youth-driven mental health organization in Rwanda with the slogan "Rise Above, Speak Out." It is intentionally not a single-page application; each primary section has its own HTML entry and page bundle.

## Pages

- `index.html` - initiative home and slogan
- `about.html` - mission, belief, and approach
- `programs.html` - awareness, school outreach, resources, dialogue spaces, early intervention, and media engagement
- `resources.html` - backend-connected mental health literacy resources
- `support.html` - safe spaces, community support, and crisis resources
- `start.html` - backend-connected digital platform registration and email verification
- `contact.html` - school, community, media, and institutional partnerships

## Local development

```bash
npm install
npm run dev
```

The local website runs at `http://localhost:5173`.

## Backend configuration

The default API is `https://mindrise.onrender.com/api/v1`. To override it, create `.env` from `.env.example` and set `VITE_API_BASE_URL`.

For browser testing, the backend must allow the website origin:

```env
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

For production, add the deployed website domain to `CORS_ALLOWED_ORIGINS` on the Render backend.