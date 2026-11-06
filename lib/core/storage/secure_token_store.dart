import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore(this._storage);

  static const String _accessKey = 'fp.access_token';
  static const String _refreshKey = 'fp.refresh_token';
  static const String _biometricKey = 'fp.biometric_enabled';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricKey) == 'true';

  Future<void> setBiometricEnabled({required bool enabled}) =>
      _storage.write(key: _biometricKey, value: enabled.toString());

  Future<void> wipe() => _storage.deleteAll();
}
