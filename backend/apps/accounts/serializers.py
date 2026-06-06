from django.contrib.auth import authenticate, get_user_model, password_validation
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()
PRACTITIONER_APPROVAL_MESSAGE = "Your practitioner account is waiting for superuser approval."


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(read_only=True)
    profile_picture_url = serializers.SerializerMethodField()

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
            "date_of_birth",
            "profile_picture_url",
            "timezone",
            "is_email_verified",
            "is_approved",
            "is_staff",
            "is_superuser",
            "created_at",
        )
        read_only_fields = (
            "id",
            "email",
            "role",
            "is_email_verified",
            "is_approved",
            "is_staff",
            "is_superuser",
            "created_at",
        )

    def get_profile_picture_url(self, obj) -> str:
        if not obj.profile_picture:
            return ""
        request = self.context.get("request")
        return request.build_absolute_uri(obj.profile_picture.url) if request else obj.profile_picture.url


class AuthTokenResponseMixin:
    def build_token_response(self, user):
        refresh = RefreshToken.for_user(user)
        return {
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": UserSerializer(user, context=self.context).data,
        }


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150, write_only=True)
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True, trim_whitespace=False, min_length=10)
    accepted_terms = serializers.BooleanField(write_only=True)
    role = serializers.CharField(required=False, default=User.Role.PATIENT, write_only=True)

    role_aliases = {
        "user": User.Role.PATIENT,
        "patient": User.Role.PATIENT,
        "practitioner": User.Role.PRACTITIONER,
    }

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

    def validate_role(self, value: str) -> str:
        role = self.role_aliases.get(value.lower())
        if role is None:
            raise serializers.ValidationError("Choose either user or practitioner.")
        return role

    def create(self, validated_data):
        name = validated_data["name"].strip()
        first_name, _, last_name = name.partition(" ")
        role = validated_data.get("role", User.Role.PATIENT)
        user = User(
            email=validated_data["email"],
            username=validated_data["email"],
            first_name=first_name,
            last_name=last_name,
            role=role,
            is_approved=role != User.Role.PRACTITIONER,
        )
        user.set_password(validated_data["password"])
        user.accept_terms()
        user.save()
        return user

    def to_representation(self, instance):
        return {
            "email": instance.email,
            "detail": "Account created. Check your email for the verification code.",
            "role": instance.role,
            "is_approved": instance.is_approved,
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
        if user.role == User.Role.PRACTITIONER and not user.is_approved:
            raise serializers.ValidationError(PRACTITIONER_APPROVAL_MESSAGE)
        if not user.is_email_verified and not user.is_staff:
            raise serializers.ValidationError("Verify your email before signing in.")
        attrs["user"] = user
        return attrs

    def to_representation(self, instance):
        return self.build_token_response(instance["user"])


class ProfileUpdateSerializer(serializers.ModelSerializer):
    date_of_birth = serializers.DateField(required=False, allow_null=True)
    remove_profile_picture = serializers.BooleanField(default=False, write_only=True, required=False)

    class Meta:
        model = User
        fields = (
            "first_name",
            "last_name",
            "phone_number",
            "date_of_birth",
            "timezone",
            "profile_picture",
            "remove_profile_picture",
        )
        extra_kwargs = {"profile_picture": {"write_only": True, "required": False, "allow_null": True}}

    def to_internal_value(self, data):
        mutable_data = data.copy()
        if mutable_data.get("date_of_birth") == "":
            mutable_data["date_of_birth"] = None
        return super().to_internal_value(mutable_data)

    def validate_profile_picture(self, value):
        if value and value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError("Profile pictures must be 5 MB or smaller.")
        return value

    def update(self, instance, validated_data):
        remove_picture = validated_data.pop("remove_profile_picture", False)
        old_picture = instance.profile_picture if instance.profile_picture else None
        replacing_picture = "profile_picture" in validated_data
        if remove_picture:
            validated_data["profile_picture"] = None

        user = super().update(instance, validated_data)
        if old_picture and (remove_picture or replacing_picture):
            old_picture.storage.delete(old_picture.name)
        return user


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


class PendingPractitionerSerializer(serializers.ModelSerializer):
    name = serializers.CharField(read_only=True)
    specialization = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "name",
            "first_name",
            "last_name",
            "phone_number",
            "specialization",
            "role",
            "is_approved",
            "is_active",
            "created_at",
        )
        read_only_fields = fields

    def get_specialization(self, obj) -> str:
        profile = getattr(obj, "practitioner_profile", None)
        return profile.specialization if profile else ""