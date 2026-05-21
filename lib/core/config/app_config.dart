class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mindrise-api.onrender.com/api/v1',
  );

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
