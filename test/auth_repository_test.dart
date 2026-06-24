import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/auth_repository.dart';
import 'package:foodly_mobile/data/repositories/cliente_profile_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _fakeToken({String role = 'ROLE_USER'}) {
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'role': role, 'sub': 'cliente@foodly.com'})),
  );
  return 'header.$payload.signature';
}

const _fakeProfileJson = '{"id":1,"email":"cliente@foodly.com",'
    '"nombre":"Test","apellido":"User","direccion":null}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  group('AuthRepository', () {
    test('login 200 guarda token y retorna AuthResponse', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/usuarios/login') {
          return http.Response(
            jsonEncode({'token': _fakeToken()}),
            200,
          );
        }
        if (request.url.path == '/api/v1/clientes/perfil') {
          return http.Response(_fakeProfileJson, 200);
        }
        fail('Request inesperado: ${request.url}');
      });

      final apiClient = ApiClient(client: client);
      final repository = AuthRepository(
        api: apiClient,
        profileRepository: ClienteProfileRepository(api: apiClient),
      );
      final response = await repository.login(
        email: 'cliente@foodly.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(await SessionManager.getToken(), isNotEmpty);
      expect(await SessionManager.getProfileJson(), isNotNull);
      await SessionManager.clearSession();
    });

    test('login 200 funciona aunque perfil falle', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/usuarios/login') {
          return http.Response(
            jsonEncode({'token': _fakeToken()}),
            200,
          );
        }
        if (request.url.path == '/api/v1/clientes/perfil') {
          return http.Response('', 500);
        }
        fail('Request inesperado: ${request.url}');
      });

      final apiClient = ApiClient(client: client);
      final repository = AuthRepository(
        api: apiClient,
        profileRepository: ClienteProfileRepository(api: apiClient),
      );
      final response = await repository.login(
        email: 'cliente@foodly.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(await SessionManager.getToken(), isNotEmpty);
    });

    test('login 401 lanza ApiException con mensaje de credenciales', () async {
      final client = MockClient((request) async {
        return http.Response('', 401);
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      expect(
        () => repository.login(
          email: 'cliente@foodly.com',
          password: 'wrong',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'status',
            401,
          ),
        ),
      );
    });
  });
}
