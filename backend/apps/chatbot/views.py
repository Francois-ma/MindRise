from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from .serializers import ChatbotMessageSerializer
from .services import OpenAIChatbotClient


class ChatbotMessageView(generics.GenericAPIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    serializer_class = ChatbotMessageSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "chatbot"

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = OpenAIChatbotClient().generate_reply(
            message=serializer.validated_data["message"],
            history=serializer.validated_data.get("history", []),
        )
        return Response({"reply": result.reply, "model": result.model}, status=status.HTTP_200_OK)
