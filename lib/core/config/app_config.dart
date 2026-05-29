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

  static String get normalizedApiBaseUrl {
    final trimmed = apiBaseUrl.trim();
    final canonical = trimmed.replaceFirst(
      'https://mindrise.onrender.com',
      'https://mindrise-api.onrender.com',
    );
    return canonical.endsWith('/')
        ? canonical.substring(0, canonical.length - 1)
        : canonical;
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
}
