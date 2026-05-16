import mimetypes
from pathlib import Path

from django.conf import settings
from django.http import FileResponse, Http404
from django.views.decorators.cache import cache_control
from django.views.decorators.http import require_GET


@require_GET
@cache_control(public=True, max_age=3600)
def serve_media_file(request, path: str):
    media_root = Path(settings.MEDIA_ROOT).resolve()
    requested_path = (media_root / path).resolve()

    try:
        requested_path.relative_to(media_root)
    except ValueError as exc:
        raise Http404 from exc

    if not requested_path.is_file():
        raise Http404

    content_type, _ = mimetypes.guess_type(requested_path.name)
    return FileResponse(
        requested_path.open("rb"),
        content_type=content_type or "application/octet-stream",
    )
