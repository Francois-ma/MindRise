import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
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
  dio.interceptors.add(AuthInterceptor(dio: dio, storage: storage));
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
  AuthInterceptor({required Dio dio, required TokenStorage storage})
    : _dio = dio,
      _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;
  Completer<AuthTokens?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    final tokens = await _storage.read();
    if (!skipAuth && tokens != null && !_isAuthEndpoint(options.path)) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        !_isAuthEndpoint(err.requestOptions.path) &&
        err.requestOptions.extra['skipAuth'] != true;

    if (!shouldRefresh) {
      handler.next(_mapError(err));
      return;
    }

    final currentTokens = await _storage.read();
    if (currentTokens == null) {
      handler.next(_mapError(err));
      return;
    }

    final refreshedTokens = await _refreshTokens(currentTokens);
    if (refreshedTokens == null) {
      handler.next(_mapError(err));
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] =
          'Bearer ${refreshedTokens.accessToken}';
      retryOptions.extra['skipAuth'] = false;
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
        await _storage.clear();
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
      await _storage.clear();
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
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
