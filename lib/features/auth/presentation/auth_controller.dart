import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth_session_events.dart';
import '../data/auth_repository.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.pendingVerificationEmail,
  });

  const AuthState.initial() : this(status: AuthStatus.loading);

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final String? pendingVerificationEmail;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthorized => isAuthenticated && (user?.isEmailVerified ?? false);

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    String? pendingVerificationEmail,
    bool clearUser = false,
    bool clearErrorMessage = false,
    bool clearPendingVerificationEmail = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      pendingVerificationEmail: clearPendingVerificationEmail
          ? null
          : pendingVerificationEmail ?? this.pendingVerificationEmail,
    );
  }
}

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    final sessionEvents = ref.watch(authSessionEventsProvider);
    final subscription = sessionEvents.expired.listen((_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'Your MindRise session expired. Sign in again to continue.',
      );
    });
    ref.onDispose(() {
      subscription.cancel();
    });
    _restore();
    return const AuthState.initial();
  }

  Future<void> _restore() async {
    final user = await _repository.restoreSession();
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        pendingVerificationEmail: user.isEmailVerified ? null : user.email,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.error?.toString() ?? error.message,
      );
      return false;
    } on Object catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingVerificationEmail: result.email,
      );
      return result.email;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.error?.toString() ?? error.message,
      );
      return null;
    } on Object catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = AuthState(
      status: AuthStatus.loading,
      pendingVerificationEmail: email,
    );
    try {
      final user = await _repository.verifyEmail(email: email, code: code);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingVerificationEmail: email,
        errorMessage: error.error?.toString() ?? error.message,
      );
      return false;
    } on Object catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingVerificationEmail: email,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> resendVerificationCode(String email) async {
    state = AuthState(
      status: AuthStatus.loading,
      pendingVerificationEmail: email,
    );
    try {
      await _repository.resendVerificationCode(email: email);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingVerificationEmail: email,
      );
      return true;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingVerificationEmail: email,
        errorMessage: error.error?.toString() ?? error.message,
      );
      return false;
    } on Object catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingVerificationEmail: email,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String dateOfBirth,
    required String timezone,
    String? profilePicturePath,
    bool removeProfilePicture = false,
  }) async {
    final previous = state;
    state = previous.copyWith(clearErrorMessage: true);
    try {
      final user = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        timezone: timezone,
        profilePicturePath: profilePicturePath,
        removeProfilePicture: removeProfilePicture,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (error) {
      state = previous.copyWith(
        errorMessage: error.error?.toString() ?? error.message,
      );
      return false;
    } on Object catch (error) {
      state = previous.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final previous = state;
    state = previous.copyWith(clearErrorMessage: true);
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = previous.copyWith(clearErrorMessage: true);
      return true;
    } on DioException catch (error) {
      state = previous.copyWith(
        errorMessage: error.error?.toString() ?? error.message,
      );
      return false;
    } on Object catch (error) {
      state = previous.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
