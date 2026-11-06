import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore(this._preferences);

  static const String _biometricKey = 'settings.biometric_enabled';
  static const String _notificationsKey = 'settings.notifications_enabled';
  static const String _lastSyncKey = 'settings.last_sync_at';
  static const String _themeKey = 'settings.theme_mode';

  final SharedPreferences _preferences;

  bool get biometricEnabled => _preferences.getBool(_biometricKey) ?? false;

  bool get notificationsEnabled =>
      _preferences.getBool(_notificationsKey) ?? true;

  String get themeMode => _preferences.getString(_themeKey) ?? 'system';

  DateTime? get lastSyncAt {
    final raw = _preferences.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setBiometricEnabled({required bool enabled}) =>
      _preferences.setBool(_biometricKey, enabled);

  Future<void> setNotificationsEnabled({required bool enabled}) =>
      _preferences.setBool(_notificationsKey, enabled);

  Future<void> setThemeMode(String mode) =>
      _preferences.setString(_themeKey, mode);

  Future<void> markSynced({DateTime? at}) => _preferences.setString(
    _lastSyncKey,
    (at ?? DateTime.now()).toIso8601String(),
  );
}
