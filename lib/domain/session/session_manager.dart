import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyToken = 'auth_token';
  static const _keyProfile = 'cliente_profile';

  /// Fallback en memoria para tests unitarios (sin plugin nativo).
  static String? _memoryToken;
  static String? _memoryProfile;

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
      _memoryToken = null;
    } catch (error) {
      if (kDebugMode) {
        _memoryToken = token;
        return;
      }
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    try {
      final secure = await _storage.read(key: _keyToken);
      if (secure != null) return secure;
    } catch (_) {
      // Plugin no disponible (tests).
    }
    return _memoryToken;
  }

  static Future<void> saveProfileJson(String json) async {
    try {
      await _storage.write(key: _keyProfile, value: json);
      _memoryProfile = null;
    } catch (error) {
      if (kDebugMode) {
        _memoryProfile = json;
        return;
      }
      rethrow;
    }
  }

  static Future<String?> getProfileJson() async {
    try {
      final secure = await _storage.read(key: _keyProfile);
      if (secure != null) return secure;
    } catch (_) {}
    return _memoryProfile;
  }

  static Future<void> clearSession() async {
    _memoryToken = null;
    _memoryProfile = null;
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyProfile);
    } catch (_) {}
  }

  static Future<bool> hasSession() async => (await getToken()) != null;

  @visibleForTesting
  static void resetForTest() {
    _memoryToken = null;
    _memoryProfile = null;
  }
}
