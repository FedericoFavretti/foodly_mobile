import 'dart:convert';

import '../../core/auth/jwt_decoder.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/session/session_manager.dart';
import '../models/auth_response.dart';
import 'cliente_profile_repository.dart';

class AuthRepository {
  AuthRepository({ApiClient? api, ClienteProfileRepository? profileRepository})
      : _api = api ?? ApiClient(),
        _profileRepository =
            profileRepository ?? ClienteProfileRepository(api: api);

  final ApiClient _api;
  final ClienteProfileRepository _profileRepository;

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
          'password': password,
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
        
        // Guardar info del usuario si viene en la respuesta (Fase 7+)
        if (authResponse.usuario != null) {
          await SessionManager.saveUsuarioInfoJson(
            jsonEncode(authResponse.usuario!.toJson()),
          );
        } else {
          // Fallback: intentar obtener perfil del endpoint (bloqueado en backend)
          try {
            await _profileRepository.fetchAndCache();
          } catch (_) {
            // El login es válido aunque el perfil falle; checkout reintenta.
          }
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

  Future<void> logout() => SessionManager.clearSession();
}
