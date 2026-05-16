import 'package:dio/dio.dart';

import '../network/api_client.dart';

String userMessageFromError(Object error) {
  if (error is DioException) {
    final apiError = error.error;
    if (apiError is ApiException) return apiError.message;
    return error.message ?? 'Something went wrong. Please try again.';
  }
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}
