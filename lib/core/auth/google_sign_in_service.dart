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
      final account = await _signIn.authenticate(scopeHint: _scopes);
      final authz = await account.authorizationClient.authorizeScopes(_scopes);

      // google_sign_in v7: `authorizeScopes` solo expone el OAuth access token.
      // El backend lo recibe en el campo `idToken` y lo valida llamando a
      // Google's UserInfo endpoint (oauth2/v3/userinfo).
      // Si en el futuro el backend cambia a validar JWT ID token, habrá que
      // migrar al flujo serverAuthCode.
      final accessToken = authz.accessToken.trim();
      if (accessToken.isEmpty) return null;
      return GoogleSignInTokens(accessToken: accessToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
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
