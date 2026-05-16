from django.contrib.auth import authenticate, get_user_model, password_validation
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(read_only=True)

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "name",
            "first_name",
            "last_name",
            "role",
            "phone_number",
            "timezone",
            "is_email_verified",
            "created_at",
        )
        read_only_fields = ("id", "email", "role", "is_email_verified", "created_at")


class AuthTokenResponseMixin:
    def build_token_response(self, user):
        refresh = RefreshToken.for_user(user)
        return {
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": UserSerializer(user).data,
        }


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150, write_only=True)
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True, trim_whitespace=False, min_length=10)
    accepted_terms = serializers.BooleanField(write_only=True)

    def validate_email(self, value: str) -> str:
        email = value.lower()
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return email

    def validate_password(self, value: str) -> str:
        password_validation.validate_password(value)
        return value

    def validate_accepted_terms(self, value: bool) -> bool:
        if not value:
            raise serializers.ValidationError("You must accept the terms to create an account.")
        return value

    def create(self, validated_data):
        name = validated_data["name"].strip()
        first_name, _, last_name = name.partition(" ")
        user = User(
            email=validated_data["email"],
            username=validated_data["email"],
            first_name=first_name,
            last_name=last_name,
        )
        user.set_password(validated_data["password"])
        user.accept_terms()
        user.save()
        return user

    def to_representation(self, instance):
        return {
            "email": instance.email,
            "detail": "Account created. Check your email for the verification code.",
        }


class LoginSerializer(serializers.Serializer, AuthTokenResponseMixin):
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate(self, attrs):
        request = self.context.get("request")
        email = attrs["email"].lower()
        user = authenticate(request=request, username=email, password=attrs["password"])
        if user is None:
            raise serializers.ValidationError("Invalid email or password.")
        if not user.is_active:
            raise serializers.ValidationError("This account is disabled.")
        if not user.is_email_verified and not user.is_staff:
            raise serializers.ValidationError("Verify your email before signing in.")
        attrs["user"] = user
        return attrs

    def to_representation(self, instance):
        return self.build_token_response(instance["user"])


class ProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("first_name", "last_name", "phone_number", "timezone")


class PasswordChangeSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True, trim_whitespace=False)
    new_password = serializers.CharField(write_only=True, trim_whitespace=False, min_length=10)

    def validate_current_password(self, value):
        user = self.context["request"].user
        if not user.check_password(value):
            raise serializers.ValidationError("Current password is incorrect.")
        return value

    def validate_new_password(self, value):
        password_validation.validate_password(value, self.context["request"].user)
        return value

    def save(self, **kwargs):
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password"])
        return user


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField(write_only=True)


class EmailVerificationSerializer(serializers.Serializer, AuthTokenResponseMixin):
    email = serializers.EmailField(write_only=True)
    code = serializers.CharField(write_only=True, min_length=6, max_length=6)

    def validate_code(self, value: str) -> str:
        if not value.isdigit():
            raise serializers.ValidationError("Enter the 6-digit verification code.")
        return value

    def to_representation(self, instance):
        return self.build_token_response(instance)


class ResendEmailVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField(write_only=True)
