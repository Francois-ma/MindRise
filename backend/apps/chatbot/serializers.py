from rest_framework import serializers


class ChatHistoryMessageSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=("user", "assistant"))
    content = serializers.CharField(max_length=1200, trim_whitespace=True)


class ChatbotMessageSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=1200, min_length=2, trim_whitespace=True)
    history = ChatHistoryMessageSerializer(many=True, required=False)

    def validate_message(self, value):
        cleaned = value.strip()
        if len(cleaned) < 2:
            raise serializers.ValidationError("Enter a message for the MindRise assistant.")
        return cleaned

    def validate_history(self, value):
        if not value:
            return []
        cleaned = []
        for item in value[-8:]:
            content = item["content"].strip()
            if content:
                cleaned.append({"role": item["role"], "content": content[:1200]})
        return cleaned
