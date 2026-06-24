import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyToken = 'auth_token';
  static const _keyProfile = 'cliente_profile';
  static const _keyBiometric = 'biometric_enabled';
  static const _keyUsuarioInfo = 'usuario_info';

  /// Fallback en memoria para tests unitarios (sin plugin nativo).
  static String? _memoryToken;
  static String? _memoryProfile;
  static String? _memoryBiometric;
  static String? _memoryUsuarioInfo;

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

  static Future<void> saveUsuarioInfoJson(String json) async {
    try {
      await _storage.write(key: _keyUsuarioInfo, value: json);
      _memoryUsuarioInfo = null;
    } catch (error) {
      if (kDebugMode) {
        _memoryUsuarioInfo = json;
        return;
      }
      rethrow;
    }
  }

  static Future<String?> getUsuarioInfoJson() async {
    try {
      final secure = await _storage.read(key: _keyUsuarioInfo);
      if (secure != null) return secure;
    } catch (_) {}
    return _memoryUsuarioInfo;
  }

  static Future<void> clearSession() async {
    _memoryToken = null;
    _memoryProfile = null;
    _memoryBiometric = null;
    _memoryUsuarioInfo = null;
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyProfile);
      await _storage.delete(key: _keyBiometric);
      await _storage.delete(key: _keyUsuarioInfo);
    } catch (_) {}
  }

  static Future<bool> hasSession() async => (await getToken()) != null;

  // ── Preferencia biométrica ──────────────────────────────────────────────

  /// Devuelve `true` si el usuario activó biometría, `false` si la rechazó,
  /// `null` si nunca se le preguntó.
  static Future<bool?> getBiometricEnabled() async {
    String? raw;
    try {
      raw = await _storage.read(key: _keyBiometric);
    } catch (_) {
      raw = _memoryBiometric;
    }
    if (raw == null) return null;
    return raw == 'true';
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final value = enabled ? 'true' : 'false';
    try {
      await _storage.write(key: _keyBiometric, value: value);
      _memoryBiometric = null;
    } catch (error) {
      if (kDebugMode) {
        _memoryBiometric = value;
        return;
      }
      rethrow;
    }
  }

  /// Obtiene el clienteId del usuario autenticado.
  /// Retorna null si no está disponible.
  static Future<int?> getClienteId() async {
    final usuarioJson = await getUsuarioInfoJson();
    if (usuarioJson == null) return null;
    
    try {
      final data = jsonDecode(usuarioJson) as Map<String, dynamic>;
      return (data['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _memoryToken = null;
    _memoryProfile = null;
    _memoryBiometric = null;
    _memoryUsuarioInfo = null;
  }
}
