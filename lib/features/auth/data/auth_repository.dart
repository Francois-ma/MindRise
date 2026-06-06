import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

enum AppUserRole {
  patient,
  practitioner,
  admin,
  unknown;

  static AppUserRole fromApi(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'patient' => AppUserRole.patient,
      'practitioner' => AppUserRole.practitioner,
      'admin' => AppUserRole.admin,
      _ => AppUserRole.unknown,
    };
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isEmailVerified,
    required this.isApproved,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.timezone,
  });

  final int id;
  final String name;
  final String email;
  final AppUserRole role;
  final bool isEmailVerified;
  final bool isApproved;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String timezone;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString().trim() ?? '';
    final lastName = json['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final apiName = json['name']?.toString().trim() ?? '';
    final email = json['email']?.toString().trim() ?? '';
    final displayName = apiName.isNotEmpty
        ? apiName
        : fullName.isNotEmpty
        ? fullName
        : email.isNotEmpty
        ? email
        : 'MindRise member';

    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: displayName,
      email: email,
      role: AppUserRole.fromApi(json['role']),
      isEmailVerified: json['is_email_verified'] == true,
      isApproved: json['is_approved'] != false,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: json['phone_number']?.toString().trim() ?? '',
      timezone: json['timezone']?.toString().trim() ?? 'UTC',
    );
  }
}

class RegistrationResult {
  const RegistrationResult({required this.email});

  final String email;

  factory RegistrationResult.fromJson(
    Map<String, dynamic>? json, {
    required String fallbackEmail,
  }) {
    return RegistrationResult(
      email: json?['email']?.toString() ?? fallbackEmail,
    );
  }
}

class AuthRepository {
  const AuthRepository({required Dio dio, required TokenStorage tokenStorage})
    : _dio = dio,
      _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AppUser?> restoreSession() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me/');
      final data = response.data ?? <String, dynamic>{};
      return AppUser.fromJson(data);
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login/',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return _persistAuthResponse(response.data);
  }

  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register/',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'accepted_terms': true,
      },
    );
    return RegistrationResult.fromJson(
      response.data,
      fallbackEmail: email.trim().toLowerCase(),
    );
  }

  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/email/verify/',
      data: {'email': email.trim().toLowerCase(), 'code': code.trim()},
    );
    return _persistAuthResponse(response.data);
  }

  Future<void> resendVerificationCode({required String email}) async {
    await _dio.post<void>(
      '/auth/email/resend/',
      data: {'email': email.trim().toLowerCase()},
    );
  }

  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String timezone,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/me/',
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone_number': phoneNumber.trim(),
        'timezone': timezone.trim().isEmpty ? 'UTC' : timezone.trim(),
      },
    );
    return AppUser.fromJson(response.data ?? const {});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/auth/password/',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  Future<void> logout() async {
    final tokens = await _tokenStorage.read();
    if (tokens != null) {
      try {
        await _dio.post<void>(
          '/auth/logout/',
          data: {'refresh': tokens.refreshToken},
        );
      } on DioException {
        // Local logout must still complete if the token is already invalid.
      }
    }
    await _tokenStorage.clear();
  }

  Future<AppUser> _persistAuthResponse(Map<String, dynamic>? data) async {
    final access =
        data?['access']?.toString() ?? data?['access_token']?.toString();
    final refresh =
        data?['refresh']?.toString() ?? data?['refresh_token']?.toString();
    if (access == null || refresh == null) {
      throw const ApiException(
        'Authentication response did not include JWT tokens.',
      );
    }

    final userJson = data?['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiException(
        'Authentication response did not include the user profile.',
      );
    }

    await _tokenStorage.save(
      AuthTokens(accessToken: access, refreshToken: refresh),
    );
    return AppUser.fromJson(userJson);
  }
}
