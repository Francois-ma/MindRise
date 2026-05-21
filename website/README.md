# MindRise Website

Official React/Vite website for MindRise Wellness Initiative: a youth-driven mental health organization in Rwanda with the slogan "Rise Above, Speak Out."

The frontend is now a React app with one `index.html` mount file and React Router routes. The visible website still has organization pages, but they are implemented as React components instead of separate HTML files.

## React Routes

- `/` - initiative home and slogan
- `/about` - mission, belief, and approach
- `/programs` - awareness, school outreach, resources, dialogue spaces, early intervention, and media engagement
- `/resources` - backend-connected mental health literacy resources
- `/support` - safe spaces, community support, and crisis resources
- `/start` - backend-connected digital platform registration and email verification
- `/contact` - school, community, media, and institutional partnerships

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