import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_auth_constants.dart';

class GoogleSignInTokens {
  const GoogleSignInTokens({required this.accessToken});

  /// OAuth access token enviado al backend en el campo `idToken`
  /// (mismo contrato que el frontend web).
  final String accessToken;
}

/// Abstracción de Google Sign-In para tests y pantallas de auth.
abstract class GoogleSignInService {
  bool get isConfigured;

  Future<GoogleSignInTokens?> signIn();
}

class PlatformGoogleSignInService implements GoogleSignInService {
  PlatformGoogleSignInService({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static const _scopes = ['email', 'profile', 'openid'];

  @override
  bool get isConfigured => GoogleAuthConstants.isConfigured;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _signIn.initialize(
      serverClientId: GoogleAuthConstants.serverClientId,
      clientId: GoogleAuthConstants.clientId.isNotEmpty
          ? GoogleAuthConstants.clientId
          : null,
    );
    await _initFuture;
    _initialized = true;
  }

  @override
  Future<GoogleSignInTokens?> signIn() async {
    if (!isConfigured) return null;

    await _ensureInitialized();

    try {
      debugPrint('[GoogleSignIn] Iniciando authenticate()...');
      final account = await _signIn.authenticate(scopeHint: _scopes);
      debugPrint('[GoogleSignIn] authenticate() OK — email: ${account.email}');

      // El ID token JWT viene directamente con authenticate() en v7.
      // No es necesario llamar a authorizeScopes() (que puede quedar bloqueado
      // en dispositivos físicos con Credential Manager).
      final idToken = account.authentication.idToken;
      debugPrint('[GoogleSignIn] idToken presente: ${idToken != null && idToken.isNotEmpty}');

      if (idToken == null || idToken.isEmpty) {
        debugPrint('[GoogleSignIn] idToken vacío, abortando.');
        return null;
      }
      return GoogleSignInTokens(accessToken: idToken);
    } on GoogleSignInException catch (error) {
      debugPrint('[GoogleSignIn] GoogleSignInException: ${error.code}');
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('[GoogleSignIn] Error inesperado: $e');
      rethrow;
    }
  }
}

/// Stub para tests unitarios sin plugin nativo.
class FakeGoogleSignInService implements GoogleSignInService {
  const FakeGoogleSignInService({
    this.accessToken = 'fake-google-access-token',
    this.isConfigured = true,
    this.shouldCancel = false,
  });

  final String? accessToken;
  @override
  final bool isConfigured;
  final bool shouldCancel;

  @override
  Future<GoogleSignInTokens?> signIn() async {
    if (shouldCancel || accessToken == null) return null;
    return GoogleSignInTokens(accessToken: accessToken!);
  }
}
