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

        send_contact_message(message_data=serializer.validated_data)
        return Response({"detail": "Message sent to MindRise."}, status=status.HTTP_202_ACCEPTED)