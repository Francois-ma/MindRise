class AppConfig {
  const AppConfig._();

  static const environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mindrise-api.onrender.com/api/v1',
  );

  static bool get isProduction =>
      environmentName.trim().toLowerCase() == 'production';

  static String get normalizedApiBaseUrl {
    final trimmed = apiBaseUrl.trim();
    final canonical = trimmed.replaceFirst(
      'https://mindrise.onrender.com',
      'https://mindrise-api.onrender.com',
    );
    final withoutTrailingSlash = canonical.endsWith('/')
        ? canonical.substring(0, canonical.length - 1)
        : canonical;
    final uri = Uri.tryParse(withoutTrailingSlash);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }

    if (isProduction && uri.scheme != 'https') {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }

    if (!withoutTrailingSlash.endsWith('/api/v1')) {
      throw StateError('API_BASE_URL must point to the /api/v1 API root.');
    }

    return withoutTrailingSlash;
  }

  static const connectTimeout = Duration(
    milliseconds: int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 20000,
    ),
  );

  static const receiveTimeout = Duration(
    milliseconds: int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 20000,
    ),
  );

  static const sendTimeout = Duration(
    milliseconds: int.fromEnvironment(
      'API_SEND_TIMEOUT_MS',
      defaultValue: 20000,
    ),
  );
}
