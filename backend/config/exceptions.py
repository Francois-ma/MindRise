from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return response

    detail = response.data
    if isinstance(detail, dict) and "detail" in detail and len(detail) == 1:
        message = str(detail["detail"])
    else:
        message = "Validation failed" if response.status_code == 400 else "Request failed"

    response.data = {
        "error": {
            "code": response.status_code,
            "message": message,
            "details": detail,
        }
    }
    return response
