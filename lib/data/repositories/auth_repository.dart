import 'dart:convert';

import '../../core/auth/jwt_decoder.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/cart/cart_notifier.dart';
import '../../domain/session/session_manager.dart';
import '../models/auth_response.dart';
import '../models/cliente_profile_model.dart';
import '../models/direccion_model.dart';

class AuthRepository {
  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const wrongCredentialsMessage =
      'El correo electrónico o la contraseña son incorrectos. Por favor, inténtelo nuevamente.';

  static const accountNotActivatedMessage =
      'Usuario no activado o bloqueado.';

  static const notClienteMessage =
      'Esta aplicación es exclusiva para clientes.';

  static const googleAuthFailedMessage =
      'No fue posible autenticar con Google. Intentalo más tarde.';

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.loginEndpoint,
        {
          'email': email.trim(),
          'passwd': password,
        },
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _persistAuthResponse(data);
      }

      if (response.statusCode == 401 || response.statusCode == 404) {
        throw ApiException(
          statusCode: response.statusCode,
          userMessage: _mapLoginErrorMessage(response.body, response.statusCode),
        );
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: 'Ocurrió un error en el servidor. Intentalo más tarde.',
        debugInfo: response.body,
      );
    } on ApiException {
      rethrow;
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',
        debugInfo: error.toString(),
      );
    }
  }

  /// Login o registro con Google vía `POST /clientes/google`.
  ///
  /// [accessToken] se envía en el campo `idToken` (mismo contrato que el web).
  Future<AuthResponse> loginWithGoogle({
    required String accessToken,
    bool esRegistro = false,
    String? documento,
    DireccionModel? direccion,
  }) async {
    try {
      final body = <String, dynamic>{
        'idToken': accessToken.trim(),
        'esRegistro': esRegistro,
      };

      if (documento != null && documento.trim().isNotEmpty) {
        body['documento'] = documento.trim();
      }

      if (direccion != null) {
        body['direccion'] = direccion.toJson();
      }

      final response = await _api.post(
        ApiConstants.googleAuthEndpoint,
        body,
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _persistAuthResponse(data);
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage:
            _mapErrorMessage(response.body) ?? googleAuthFailedMessage,
        debugInfo: response.body,
      );
    } on ApiException {
      rethrow;
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',
        debugInfo: error.toString(),
      );
    }
  }

  Future<AuthResponse> _persistAuthResponse(Map<String, dynamic> data) async {
    final authResponse = AuthResponse.fromJson(data);
    final role = JwtDecoder.role(authResponse.token);
    if (!JwtDecoder.isClienteRole(role)) {
      await SessionManager.clearSession();
      throw const ApiException(
        statusCode: 403,
        userMessage: notClienteMessage,
      );
    }
    await SessionManager.saveToken(authResponse.token);

    if (authResponse.usuario != null) {
      final usuario = authResponse.usuario!;
      await SessionManager.saveUsuarioInfoJson(
        jsonEncode(usuario.toJson()),
      );
    }

    final profileFromLogin = ClienteProfileModel.tryFromLoginJson(data);
    if (profileFromLogin != null) {
      await SessionManager.saveProfileJson(
        jsonEncode(profileFromLogin.toJson()),
      );
    }

    return authResponse;
  }

  /// Cierra la sesión del usuario.
  /// Intenta notificar al backend, pero siempre limpia la sesión local.
  Future<void> logout() async {
    try {
      await _api.post(
        ApiConstants.logoutEndpoint,
        {},
        requiresAuth: true,
      );
    } catch (_) {
      // Ignorar errores del backend - la limpieza local es lo crítico
    } finally {
      await SessionManager.clearSession();
      CartNotifier.instance.clear();
    }
  }

  String _mapLoginErrorMessage(String body, int statusCode) {
    final backendMessage = _mapErrorMessage(body);
    if (backendMessage != null) return backendMessage;
    if (statusCode == 404) return accountNotActivatedMessage;
    return wrongCredentialsMessage;
  }

  String? _mapErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    if (body.length < 300 && !body.contains('<html')) return body;
    return null;
  }
}
