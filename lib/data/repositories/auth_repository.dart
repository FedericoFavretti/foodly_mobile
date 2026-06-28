import 'dart:convert';

import '../../core/auth/jwt_decoder.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/session/session_manager.dart';
import '../models/auth_response.dart';

class AuthRepository {
  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const wrongCredentialsMessage =
      'El correo electrónico o la contraseña son incorrectos. Por favor, inténtelo nuevamente.';

  static const notClienteMessage =
      'Esta aplicación es exclusiva para clientes.';

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
          await SessionManager.saveProfileJson(
            jsonEncode({
              'id': usuario.id,
              'email': usuario.email,
              'nombre': '',
              'apellido': '',
            }),
          );
        }
        
        return authResponse;
      }

      if (response.statusCode == 401) {
        throw const ApiException(
          statusCode: 401,
          userMessage: wrongCredentialsMessage,
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

  /// Cierra la sesión del usuario.
  /// Intenta notificar al backend, pero siempre limpia la sesión local.
  Future<void> logout() async {
    try {
      // Intentar notificar al backend (best effort)
      await _api.post(
        ApiConstants.logoutEndpoint,
        {},
        requiresAuth: true,
      );
    } catch (_) {
      // Ignorar errores del backend - la limpieza local es lo crítico
    } finally {
      // Siempre limpiar la sesión local
      await SessionManager.clearSession();
    }
  }
}
