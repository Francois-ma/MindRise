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

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isEmailVerified,
  });

  final int id;
  final String name;
  final String email;
  final bool isEmailVerified;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['first_name'] ?? 'Francois').toString(),
      email: (json['email'] ?? 'francois@mindrise.com').toString(),
      isEmailVerified: json['is_email_verified'] != false,
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
      data: {'email': email, 'password': password},
    );
    return _persistAuthResponse(response.data, fallbackEmail: email);
  }

  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register/',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'accepted_terms': true,
      },
    );
    return RegistrationResult.fromJson(response.data, fallbackEmail: email);
  }

  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/email/verify/',
      data: {'email': email, 'code': code},
    );
    return _persistAuthResponse(response.data, fallbackEmail: email);
  }

  Future<void> resendVerificationCode({required String email}) async {
    await _dio.post<void>('/auth/email/resend/', data: {'email': email});
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

  Future<AppUser> _persistAuthResponse(
    Map<String, dynamic>? data, {
    String? fallbackName,
    required String fallbackEmail,
  }) async {
    final access =
        data?['access']?.toString() ?? data?['access_token']?.toString();
    final refresh =
        data?['refresh']?.toString() ?? data?['refresh_token']?.toString();
    if (access == null || refresh == null) {
      throw const ApiException(
        'Authentication response did not include JWT tokens.',
      );
    }

    await _tokenStorage.save(
      AuthTokens(accessToken: access, refreshToken: refresh),
    );
    final userJson = data?['user'];
    if (userJson is Map<String, dynamic>) return AppUser.fromJson(userJson);
    return AppUser(
      id: 0,
      name: fallbackName ?? 'Francois',
      email: fallbackEmail,
      isEmailVerified: true,
    );
  }
}
