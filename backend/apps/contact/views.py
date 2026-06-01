from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from .serializers import ContactMessageSerializer
from .services import send_contact_message


class ContactMessageView(generics.GenericAPIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = ContactMessageSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "contact"

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if serializer.validated_data.get("website"):
            return Response({"detail": "Message received."}, status=status.HTTP_202_ACCEPTED)

        message_data = {
            "name": serializer.validated_data["name"],
            "email": serializer.validated_data["email"],
            "organization": serializer.validated_data.get("organization", ""),
            "topic": serializer.validated_data.get("topic") or "general",
            "message": serializer.validated_data["message"],
        }
        send_contact_message(message_data=message_data)
        return Response({"detail": "Message sent to MindRise."}, status=status.HTTP_202_ACCEPTED)
