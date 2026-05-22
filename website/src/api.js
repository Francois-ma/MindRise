const configuredApiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'https://mindrise-api.onrender.com/api/v1';

export const API_BASE_URL = configuredApiBaseUrl
  .replace('https://mindrise.onrender.com', 'https://mindrise-api.onrender.com')
  .replace(/\/$/, '');

const serviceUnavailableHint = 'MindRise digital services are temporarily unavailable. Please try again later.';

export async function fetchHealth() {
  return request('/health/');
}

export async function fetchLearningContent() {
  const [categories, articles, materials] = await Promise.allSettled([
    request('/learning/categories/'),
    request('/learning/articles/?limit=6&ordering=-published_at'),
    request('/learning/materials/?limit=4&ordering=-published_at'),
  ]);

  return {
    categories: unwrapList(categories),
    articles: unwrapList(articles),
    materials: unwrapList(materials),
    error: firstError([categories, articles, materials]),
  };
}

export async function fetchCrisisResources() {
  const data = await request('/support/crisis-resources/?country_code=RW');
  return readList(data);
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

async function request(path, options = {}) {
  try {
    const response = await fetch(`${API_BASE_URL}${path}`, {
      ...options,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
    });

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
  } catch (error) {
    if (error instanceof TypeError) {
      throw new Error(serviceUnavailableHint);
    }
    throw error;
  }
}

function extractErrorMessage(data) {
  const directMessage = data?.detail || data?.message;
  if (directMessage) return directMessage;

  const apiError = data?.error;
  if (!apiError) return '';

  const details = apiError.details;
  if (details && typeof details === 'object') {
    const fieldMessages = Object.entries(details)
      .flatMap(([field, value]) => {
        const messages = Array.isArray(value) ? value : [value];
        return messages.filter(Boolean).map((message) => `${formatFieldName(field)}: ${message}`);
      });
    if (fieldMessages.length) return fieldMessages.join(' ');
  }

  return apiError.message || '';
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

function unwrapList(result) {
  if (result.status !== 'fulfilled') return [];
  return readList(result.value);
}

function firstError(results) {
  const failed = results.find((result) => result.status === 'rejected');
  return failed?.reason?.message || '';
}
