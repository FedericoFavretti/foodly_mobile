import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:foodly_mobile/core/constants/api_constants.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/auth_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';

void main() {
  setUp(() => SessionManager.resetForTest());

  group('Logout', () {
    test('logout limpia la sesión local incluso si backend falla', () async {
      // Simular token guardado
      await SessionManager.saveToken('fake.jwt.token');
      expect(await SessionManager.getToken(), isNotNull);

      // Backend responde con error
      final client = MockClient((request) async {
        if (request.url.path == ApiConstants.logoutEndpoint) {
          return http.Response('Internal Server Error', 500);
        }
        fail('Request inesperado: ${request.url}');
      });

      final apiClient = ApiClient(client: client);
      final repository = AuthRepository(api: apiClient);

      // Logout debe completar sin lanzar excepción
      await repository.logout();

      // Sesión debe estar limpia
      expect(await SessionManager.getToken(), isNull);
    });

    test('logout notifica al backend y limpia sesión local', () async {
      await SessionManager.saveToken('fake.jwt.token');
      expect(await SessionManager.getToken(), isNotNull);

      var backendNotified = false;

      final client = MockClient((request) async {
        if (request.url.path == ApiConstants.logoutEndpoint) {
          backendNotified = true;
          return http.Response(jsonEncode({'mensaje': 'Sesión cerrada'}), 200);
        }
        fail('Request inesperado: ${request.url}');
      });

      final apiClient = ApiClient(client: client);
      final repository = AuthRepository(api: apiClient);

      await repository.logout();

      expect(backendNotified, isTrue);
      expect(await SessionManager.getToken(), isNull);
    });

    test('logout limpia también el perfil y usuario info', () async {
      // Guardar token, perfil y usuario info
      await SessionManager.saveToken('fake.jwt.token');
      await SessionManager.saveProfileJson('{"nombre": "Test"}');
      await SessionManager.saveUsuarioInfoJson('{"id": 123}');

      expect(await SessionManager.getToken(), isNotNull);
      expect(await SessionManager.getProfileJson(), isNotNull);
      expect(await SessionManager.getUsuarioInfoJson(), isNotNull);

      final client = MockClient((request) async {
        return http.Response('', 200);
      });

      final apiClient = ApiClient(client: client);
      final repository = AuthRepository(api: apiClient);

      await repository.logout();

      // Todo debe estar limpio
      expect(await SessionManager.getToken(), isNull);
      expect(await SessionManager.getProfileJson(), isNull);
      expect(await SessionManager.getUsuarioInfoJson(), isNull);
    });
  });
}
