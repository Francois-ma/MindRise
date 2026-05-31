from rest_framework import serializers


class ContactMessageSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=120, trim_whitespace=True)
    email = serializers.EmailField(max_length=254)
    organization = serializers.CharField(max_length=160, allow_blank=True, required=False, trim_whitespace=True)
    topic = serializers.CharField(max_length=80, allow_blank=True, required=False, trim_whitespace=True)
    message = serializers.CharField(max_length=2500, min_length=20, trim_whitespace=True)
    website = serializers.CharField(max_length=200, allow_blank=True, required=False, write_only=True)

    def validate_name(self, value):
        if len(value.strip()) < 2:
            raise serializers.ValidationError("Enter your name.")
        return value.strip()

    def validate_message(self, value):
        cleaned = value.strip()
        if len(cleaned) < 20:
            raise serializers.ValidationError("Message must be at least 20 characters.")
        return cleaned