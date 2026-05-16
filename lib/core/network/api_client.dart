import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );

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

  @override
  String toString() => message;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio, required TokenStorage storage})
    : _dio = dio,
      _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _storage.read();
    if (tokens != null && !_isAuthEndpoint(options.path)) {
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
        !_isRefreshing &&
        !_isAuthEndpoint(err.requestOptions.path);

    if (!shouldRefresh) {
      handler.next(_mapError(err));
      return;
    }

    try {
      _isRefreshing = true;
      final tokens = await _storage.read();
      if (tokens == null) {
        handler.next(_mapError(err));
        return;
      }

      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/token/refresh/',
        data: {'refresh': tokens.refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final access = refreshResponse.data?['access'] as String?;
      final refresh = refreshResponse.data?['refresh'] as String?;
      if (access == null) {
        await _storage.clear();
        handler.next(_mapError(err));
        return;
      }

      final nextTokens = AuthTokens(
        accessToken: access,
        refreshToken: refresh ?? tokens.refreshToken,
      );
      await _storage.save(nextTokens);

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $access';
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await _storage.clear();
      handler.next(_mapError(err));
    } finally {
      _isRefreshing = false;
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
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/token/refresh');
  }

  String? _extractMessage(Object? data) {
    if (data is! Map<String, dynamic>) return null;

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message != null) return message.toString();
    }

    for (final key in const ['detail', 'message', 'non_field_errors']) {
      final value = data[key];
      if (value == null) continue;
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
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
