import os

bind = f"0.0.0.0:{os.getenv('PORT', '10000')}"
workers = int(os.getenv("WEB_CONCURRENCY") or "2")
timeout = int(os.getenv("GUNICORN_TIMEOUT") or "120")
graceful_timeout = int(os.getenv("GUNICORN_GRACEFUL_TIMEOUT") or "30")
max_requests = int(os.getenv("GUNICORN_MAX_REQUESTS") or "1000")
max_requests_jitter = int(os.getenv("GUNICORN_MAX_REQUESTS_JITTER") or "100")
accesslog = "-"
errorlog = "-"
loglevel = os.getenv("GUNICORN_LOG_LEVEL", "info")
preload_app = os.getenv("GUNICORN_PRELOAD", "true").lower() == "true"
