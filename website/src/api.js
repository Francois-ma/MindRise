const configuredApiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'https://mindrise-api.onrender.com/api/v1';

export const API_BASE_URL = configuredApiBaseUrl
  .replace('https://mindrise.onrender.com', 'https://mindrise-api.onrender.com')
  .replace(/\/$/, '');

const serviceUnavailableHint = 'MindRise updates are temporarily unavailable. Please try again later.';
const authStorageKey = 'mindrise.web.auth';
let refreshPromise = null;

export function readStoredAuth() {
  try {
    if (typeof window === 'undefined') return null;
    const raw = window.localStorage.getItem(authStorageKey);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function saveStoredAuth(session) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(authStorageKey, JSON.stringify(session));
}

export function clearStoredAuth() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(authStorageKey);
}

export async function sendContactMessage(payload) {
  return request('/contact/message/', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function sendChatbotMessage(payload) {
  return request('/chatbot/message/', {
    method: 'POST',
    body: JSON.stringify({
      message: payload.message,
      history: payload.history || [],
    }),
  });
}
export async function fetchHealth() {
  return request('/health/');
}

export async function fetchLearningContent(token) {
  const [categories, articles, materials] = await Promise.allSettled([
    request('/learning/categories/'),
    request('/learning/articles/?limit=20&ordering=-published_at', { token }),
    request('/learning/materials/?limit=20&ordering=-published_at', { token }),
  ]);

  return {
    categories: unwrapList(categories),
    articles: unwrapList(articles),
    materials: unwrapList(materials),
    error: firstError([categories, articles, materials]),
  };
}

export async function loginAccount(payload) {
  return request('/auth/login/', {
    method: 'POST',
    body: JSON.stringify({
      email: payload.email,
      password: payload.password,
    }),
  });
}

export async function logoutAccount(refreshToken, accessToken) {
  if (!refreshToken) return null;
  return request('/auth/logout/', {
    token: accessToken,
    method: 'POST',
    body: JSON.stringify({ refresh: refreshToken }),
    skipAuthRefresh: true,
  });
}

export async function fetchCurrentUser(token) {
  return request('/auth/me/', { token });
}

export async function registerAccount(payload) {
  return request('/auth/register/', {
    method: 'POST',
    body: JSON.stringify({
      name: payload.name,
      email: payload.email,
      password: payload.password,
      accepted_terms: true,
    }),
  });
}

export async function verifyEmail(payload) {
  return request('/auth/email/verify/', {
    method: 'POST',
    body: JSON.stringify({
      email: payload.email,
      code: payload.code,
    }),
  });
}

export async function resendVerificationEmail(email) {
  return request('/auth/email/resend/', {
    method: 'POST',
    body: JSON.stringify({ email }),
  });
}

export async function fetchMoodSummary(token) {
  return request('/wellness/moods/summary/', { token });
}

export async function fetchMoodEntries(token) {
  return request('/wellness/moods/?limit=20&ordering=-occurred_at', { token });
}

export async function createMoodEntry(token, payload) {
  return request('/wellness/moods/', {
    token,
    method: 'POST',
    body: JSON.stringify({
      mood: payload.mood,
      score: payload.score,
      note: payload.note,
      occurred_at: new Date().toISOString(),
    }),
  });
}

export async function fetchPersonalizedInsights(token) {
  return request('/wellness/moods/ai-insights/', { token });
}

export async function fetchPractitioners(token) {
  return request('/support/practitioners/?limit=20&ordering=-is_available,next_available_at', { token });
}

export async function fetchCrisisResources() {
  return request('/support/crisis-resources/?country_code=RW');
}

export async function createGratitudeEntry(token, items, note = '') {
  return request('/wellness/gratitude/', {
    token,
    method: 'POST',
    body: JSON.stringify({ items, note }),
  });
}

export async function createThoughtReframe(token, payload) {
  return request('/wellness/reframes/', {
    token,
    method: 'POST',
    body: JSON.stringify({
      negative_thought: payload.negativeThought,
      reframed_thought: payload.reframedThought,
    }),
  });
}

async function request(path, options = {}) {
  const { token, headers, skipAuthRefresh = false, ...fetchOptions } = options;
  const shouldAuthorize = Boolean(token);
  const stored = shouldAuthorize ? readStoredAuth() : null;
  const authToken = shouldAuthorize ? stored?.access || token : '';

  try {
    let response = await sendRequest(path, fetchOptions, headers, authToken);

    if (response.status === 401 && shouldAuthorize && !skipAuthRefresh) {
      const refreshed = await refreshStoredSession();
      if (refreshed?.access) {
        response = await sendRequest(path, fetchOptions, headers, refreshed.access);
      }
    }

    return parseResponse(response);
  } catch (error) {
    if (error instanceof TypeError) {
      throw new Error(serviceUnavailableHint);
    }
    throw error;
  }
}

async function sendRequest(path, fetchOptions, headers, token) {
  const hasJsonBody = fetchOptions.body !== undefined && !(typeof FormData !== 'undefined' && fetchOptions.body instanceof FormData);

  return fetch(`${API_BASE_URL}${path}`, {
    cache: 'no-store',
    referrerPolicy: 'strict-origin-when-cross-origin',
    ...fetchOptions,
    headers: {
      Accept: 'application/json',
      ...(hasJsonBody ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(headers || {}),
    },
  });
}

async function refreshStoredSession() {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    const stored = readStoredAuth();
    if (!stored?.refresh) return null;

    try {
      const response = await sendRequest(
        '/auth/token/refresh/',
        {
          method: 'POST',
          body: JSON.stringify({ refresh: stored.refresh }),
        },
        null,
        '',
      );
      const payload = await parseResponse(response);
      const nextSession = {
        ...stored,
        access: payload?.access || stored.access,
        refresh: payload?.refresh || stored.refresh,
      };
      saveStoredAuth(nextSession);
      return nextSession;
    } catch {
      clearStoredAuth();
      return null;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

async function parseResponse(response) {
  const text = await response.text();
  const data = text ? safeJson(text) : null;

  if (!response.ok) {
    const message = extractErrorMessage(data) || `Request failed with status ${response.status}`;
    const error = new Error(message);
    error.status = response.status;
    error.details = data;
    throw error;
  }

  return data;
}

function extractErrorMessage(data) {
  const directMessage = data?.detail || data?.message;
  if (directMessage) return listOrString(directMessage);

  const apiError = data?.error;
  if (!apiError) return fieldErrors(data);

  const details = apiError.details;
  if (details && typeof details === 'object') {
    const formatted = fieldErrors(details);
    if (formatted) return formatted;
  }

  return apiError.message || '';
}

function fieldErrors(data) {
  if (!data || typeof data !== 'object') return '';
  const fieldMessages = Object.entries(data)
    .flatMap(([field, value]) => {
      const messages = Array.isArray(value) ? value : [value];
      return messages.filter(Boolean).map((message) => `${formatFieldName(field)}: ${listOrString(message)}`);
    });
  return fieldMessages.join(' ');
}

function listOrString(value) {
  if (Array.isArray(value)) return value.join(' ');
  return value?.toString?.() || '';
}

function formatFieldName(field) {
  return field.replaceAll('_', ' ').replace(/^\w/, (letter) => letter.toUpperCase());
}

function safeJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    return { detail: text };
  }
}

function readList(data) {
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.results)) return data.results;
  return [];
}

export function readListPayload(data) {
  return readList(data);
}

function unwrapList(result) {
  if (result.status !== 'fulfilled') return [];
  return readList(result.value);
}

function firstError(results) {
  const failed = results.find((result) => result.status === 'rejected');
  return failed?.reason?.message || '';
}
