import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credencial guardada localmente para que la biometría pueda iniciar
/// sesión de verdad (no solo desbloquear un JWT que ya existe), ya que
/// este backend no tiene refresh token. Se guarda en el mismo storage
/// cifrado que el JWT (Android Keystore / iOS Keychain vía
/// FlutterSecureStorage).
class BiometricCredential {
  const BiometricCredential({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};

  static BiometricCredential? tryFromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final email = decoded['email'];
      final password = decoded['password'];
      if (email is! String || password is! String) return null;
      return BiometricCredential(email: email, password: password);
    } catch (_) {
      return null;
    }
  }
}

class SessionManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyToken = 'auth_token';
  static const _keyProfile = 'cliente_profile';
  static const _keyBiometric = 'biometric_enabled';
  static const _keyBiometricCredential = 'biometric_credential';
  static const _keyUsuarioInfo = 'usuario_info';

  /// Fallback en memoria para tests unitarios (sin plugin nativo).
  static String? _memoryToken;
  static String? _memoryProfile;
  static String? _memoryBiometric;
  static String? _memoryBiometricCredential;
  static String? _memoryUsuarioInfo;
  static bool _forceMemoryForTest = false;

  @visibleForTesting
  static void enableMemoryStorageForTest() {
    _forceMemoryForTest = true;
    resetForTest();
  }

  static Future<void> saveToken(String token) async {
    if (_forceMemoryForTest) {
      _memoryToken = token;
      return;
    }
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
    if (_forceMemoryForTest) return _memoryToken;
    try {
      final secure = await _storage.read(key: _keyToken);
      if (secure != null) return secure;
    } catch (_) {
      // Plugin no disponible (tests).
    }
    return _memoryToken;
  }

  static Future<void> saveProfileJson(String json) async {
    if (_forceMemoryForTest) {
      _memoryProfile = json;
      return;
    }
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
    if (_forceMemoryForTest) return _memoryProfile;
    try {
      final secure = await _storage.read(key: _keyProfile);
      if (secure != null) return secure;
    } catch (_) {}
    return _memoryProfile;
  }

  static Future<void> saveUsuarioInfoJson(String json) async {
    if (_forceMemoryForTest) {
      _memoryUsuarioInfo = json;
      return;
    }
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
    if (_forceMemoryForTest) return _memoryUsuarioInfo;
    try {
      final secure = await _storage.read(key: _keyUsuarioInfo);
      if (secure != null) return secure;
    } catch (_) {}
    return _memoryUsuarioInfo;
  }

  /// Limpia la sesión (token, perfil, usuario info) al cerrar sesión o
  /// cuando el token expira. La preferencia de biometría NO se toca acá:
  /// es una preferencia de este dispositivo ("¿querés desbloquear la app
  /// con huella?"), no algo atado a la sesión activa, así que debe
  /// sobrevivir a un logout/re-login.
  static Future<void> clearSession() async {
    _memoryToken = null;
    _memoryProfile = null;
    _memoryUsuarioInfo = null;
    if (_forceMemoryForTest) return;
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyProfile);
      await _storage.delete(key: _keyUsuarioInfo);
    } catch (_) {}
  }

  static Future<bool> hasSession() async => (await getToken()) != null;

  // ── Preferencia biométrica ──────────────────────────────────────────────

  /// Devuelve `true` si el usuario activó biometría, `false` si la rechazó,
  /// `null` si nunca se le preguntó.
  static Future<bool?> getBiometricEnabled() async {
    if (_forceMemoryForTest) {
      final raw = _memoryBiometric;
      if (raw == null) return null;
      return raw == 'true';
    }
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
    if (_forceMemoryForTest) {
      _memoryBiometric = value;
      return;
    }
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

  // ── Credencial para login biométrico ────────────────────────────────────

  static Future<void> saveBiometricCredential({
    required String email,
    required String password,
  }) async {
    final json = jsonEncode(
      BiometricCredential(email: email, password: password).toJson(),
    );
    if (_forceMemoryForTest) {
      _memoryBiometricCredential = json;
      return;
    }
    try {
      await _storage.write(key: _keyBiometricCredential, value: json);
      _memoryBiometricCredential = null;
    } catch (error) {
      if (kDebugMode) {
        _memoryBiometricCredential = json;
        return;
      }
      rethrow;
    }
  }

  static Future<BiometricCredential?> getBiometricCredential() async {
    if (_forceMemoryForTest) {
      final raw = _memoryBiometricCredential;
      return raw == null ? null : BiometricCredential.tryFromJson(raw);
    }
    String? raw;
    try {
      raw = await _storage.read(key: _keyBiometricCredential);
    } catch (_) {
      raw = _memoryBiometricCredential;
    }
    if (raw == null) return null;
    return BiometricCredential.tryFromJson(raw);
  }

  static Future<void> clearBiometricCredential() async {
    _memoryBiometricCredential = null;
    if (_forceMemoryForTest) return;
    try {
      await _storage.delete(key: _keyBiometricCredential);
    } catch (_) {}
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
    _memoryBiometricCredential = null;
    _memoryUsuarioInfo = null;
  }
}
