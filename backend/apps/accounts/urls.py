from django.urls import path

from .views import (
    EmailVerificationView,
    LoginView,
    LogoutView,
    MeView,
    PasswordChangeView,
    RefreshView,
    RegisterView,
    ResendEmailVerificationView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("email/verify/", EmailVerificationView.as_view(), name="auth-email-verify"),
    path("email/resend/", ResendEmailVerificationView.as_view(), name="auth-email-resend"),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("token/refresh/", RefreshView.as_view(), name="token-refresh"),
    path("logout/", LogoutView.as_view(), name="auth-logout"),
    path("me/", MeView.as_view(), name="auth-me"),
    path("password/", PasswordChangeView.as_view(), name="auth-password"),
]
