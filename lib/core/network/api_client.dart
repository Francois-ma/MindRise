import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_session_events.dart';
import 'token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final sessionEvents = ref.watch(authSessionEventsProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.normalizedApiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-store',
        'X-Client': 'mindrise-mobile',
        'X-Client-Version': '1.0.0',
        'X-App-Environment': AppConfig.environmentName,
      },
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio: dio));
  dio.interceptors.add(
    AuthInterceptor(dio: dio, storage: storage, sessionEvents: sessionEvents),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  return dio;
});

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const _maxAttempts = 2;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['retryAttempt'] as int? ?? 0;
    if (attempt >= _maxAttempts || !_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(Duration(milliseconds: 280 * (attempt + 1)));
    final retryOptions = err.requestOptions;
    retryOptions.extra['retryAttempt'] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    } on Object {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException error) {
    if (!_isSafeMethod(error.requestOptions.method)) return false;

    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) return true;

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  bool _isSafeMethod(String method) {
    return const {'GET', 'HEAD', 'OPTIONS'}.contains(method.toUpperCase());
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage storage,
    required AuthSessionEvents sessionEvents,
  }) : _dio = dio,
       _storage = storage,
       _sessionEvents = sessionEvents;

  final Dio _dio;
  final TokenStorage _storage;
  final AuthSessionEvents _sessionEvents;
  Completer<AuthTokens?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    final isProtectedRequest = !skipAuth && !_isAuthEndpoint(options.path);
    final tokens = await _storage.read();
    if (!isProtectedRequest || tokens == null) {
      handler.next(options);
      return;
    }

    final activeTokens = isJwtExpiring(tokens.accessToken)
        ? await _refreshTokens(tokens)
        : tokens;
    if (activeTokens == null) {
      handler.reject(_sessionExpiredError(options));
      return;
    }

    options.headers['Authorization'] = 'Bearer ${activeTokens.accessToken}';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isProtectedUnauthorized =
        err.response?.statusCode == 401 &&
        !_isAuthEndpoint(err.requestOptions.path) &&
        err.requestOptions.extra['skipAuth'] != true;
    if (isProtectedUnauthorized &&
        err.requestOptions.extra['authRetry'] == true) {
      await _expireSession();
      handler.next(_sessionExpiredError(err.requestOptions));
      return;
    }

    final shouldRefresh = isProtectedUnauthorized;
    if (!shouldRefresh) {
      handler.next(_mapError(err));
      return;
    }

    final currentTokens = await _storage.read();
    if (currentTokens == null) {
      _sessionEvents.notifyExpired();
      handler.next(_sessionExpiredError(err.requestOptions));
      return;
    }

    final refreshedTokens = await _refreshTokens(currentTokens);
    if (refreshedTokens == null) {
      handler.next(_sessionExpiredError(err.requestOptions));
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] =
          'Bearer ${refreshedTokens.accessToken}';
      retryOptions.extra['skipAuth'] = false;
      retryOptions.extra['authRetry'] = true;
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(_mapError(error));
    } on Object {
      handler.next(_mapError(err));
    }
  }

  Future<AuthTokens?> _refreshTokens(AuthTokens tokens) async {
    final activeRefresh = _refreshCompleter;
    if (activeRefresh != null) return activeRefresh.future;

    final completer = Completer<AuthTokens?>();
    _refreshCompleter = completer;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/token/refresh/',
        data: {'refresh': tokens.refreshToken},
        options: Options(
          headers: {'Authorization': null},
          extra: {'skipAuth': true},
        ),
      );
      final access = response.data?['access']?.toString();
      final refresh = response.data?['refresh']?.toString();
      if (access == null || access.isEmpty) {
        await _expireSession();
        completer.complete(null);
        return null;
      }

      final nextTokens = AuthTokens(
        accessToken: access,
        refreshToken: refresh?.isNotEmpty == true
            ? refresh!
            : tokens.refreshToken,
      );
      await _storage.save(nextTokens);
      completer.complete(nextTokens);
      return nextTokens;
    } on Object {
      await _expireSession();
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _expireSession() async {
    try {
      await _storage.clear();
    } on Object {
      // The router must still leave protected screens if secure storage fails.
    } finally {
      _sessionEvents.notifyExpired();
    }
  }

  DioException _sessionExpiredError(RequestOptions options) {
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(requestOptions: options, statusCode: 401),
      type: DioExceptionType.badResponse,
      error: const ApiException(
        'Your MindRise session expired. Sign in again to continue.',
        statusCode: 401,
      ),
    );
  }

  DioException _mapError(DioException error) {
    final data = error.response?.data;
    final message = _extractMessage(data) ?? _fallbackMessage(error);

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: ApiException(message, statusCode: error.response?.statusCode),
      stackTrace: error.stackTrace,
    );
  }

  bool _isAuthEndpoint(String path) {
    final normalized = path.split('?').first;
    return normalized.endsWith('/auth/login/') ||
        normalized.endsWith('/auth/register/') ||
        normalized.endsWith('/auth/email/verify/') ||
        normalized.endsWith('/auth/email/resend/') ||
        normalized.endsWith('/auth/token/refresh/');
  }

  String? _extractMessage(Object? data) {
    if (data == null) return null;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is List) return _firstMessage(data);
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        final message = _extractMessage(error['message']);
        if (message != null) return message;
      }

      for (final key in const ['detail', 'message', 'non_field_errors']) {
        final message = _extractMessage(data[key]);
        if (message != null) return message;
      }

      for (final entry in data.entries) {
        final message = _extractMessage(entry.value);
        if (message != null) return message;
      }
    }
    return null;
  }

  String? _firstMessage(List<dynamic> values) {
    for (final value in values) {
      final message = _extractMessage(value);
      if (message != null) return message;
    }
    return null;
  }

  String _fallbackMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'The connection timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Cannot reach MindRise services. Check your connection.',
      DioExceptionType.badCertificate => 'Secure connection validation failed.',
      _ => error.message ?? 'Network request failed',
    };
  }
}

bool isJwtExpiring(
  String token, {
  DateTime? now,
  Duration threshold = const Duration(seconds: 30),
}) {
  try {
    final segments = token.split('.');
    if (segments.length != 3) return true;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
    );
    if (payload is! Map<String, dynamic>) return true;
    final expiresAt = payload['exp'];
    if (expiresAt is! num) return true;
    final currentSeconds =
        (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    return expiresAt.toInt() <= currentSeconds + threshold.inSeconds;
  } on Object {
    return true;
  }
}
