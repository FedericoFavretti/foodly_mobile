/// Configuración OAuth de Google vía `--dart-define`.
abstract final class GoogleAuthConstants {
  /// Client ID web (server) usado por el backend y `google_sign_in`.
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Client ID de la app (Android/iOS) si difiere del web.
  static const clientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => serverClientId.trim().isNotEmpty;
}
