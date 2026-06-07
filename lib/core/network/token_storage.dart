import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: true,
        migrateOnAlgorithmChange: true,
        storageNamespace: 'mindrise_auth',
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
    ),
  );
});

class TokenStorage {
  TokenStorage(this._storage);

  static const _accessKey = 'mindrise.access_token';
  static const _refreshKey = 'mindrise.refresh_token';

  final FlutterSecureStorage _storage;
  AuthTokens? _cachedTokens;
  Future<AuthTokens?>? _pendingRead;
  bool _hasReadStorage = false;
  int _version = 0;

  Future<AuthTokens?> read() async {
    if (_hasReadStorage) return _cachedTokens;
    final pendingRead = _pendingRead;
    if (pendingRead != null) return pendingRead;

    final read = _readFromStorage(_version);
    _pendingRead = read;
    try {
      return await read;
    } finally {
      _pendingRead = null;
    }
  }

  Future<AuthTokens?> _readFromStorage(int version) async {
    final values = await Future.wait([
      _storage.read(key: _accessKey),
      _storage.read(key: _refreshKey),
    ]);
    if (version != _version) return _cachedTokens;
    final access = values[0];
    final refresh = values[1];
    _cachedTokens = access == null || refresh == null
        ? null
        : AuthTokens(accessToken: access, refreshToken: refresh);
    _hasReadStorage = true;
    return _cachedTokens;
  }

  Future<void> save(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: tokens.accessToken),
      _storage.write(key: _refreshKey, value: tokens.refreshToken),
    ]);
    _version++;
    _cachedTokens = tokens;
    _hasReadStorage = true;
  }

  Future<void> clear() async {
    _version++;
    _cachedTokens = null;
    _hasReadStorage = true;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
