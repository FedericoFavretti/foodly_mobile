import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/auth_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _fakeToken({String role = 'ROLE_USER'}) {
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'role': role, 'sub': 'cliente@foodly.com'})),
  );
  return 'header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  group('AuthRepository', () {
    test('login 200 guarda token, usuario y perfil mínimo', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/login');
        return http.Response(
          jsonEncode({
            'token': _fakeToken(),
            'id': 123,
            'email': 'cliente@foodly.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      final response = await repository.login(
        email: 'cliente@foodly.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(await SessionManager.getToken(), isNotEmpty);
      expect(await SessionManager.getUsuarioInfoJson(), isNotNull);
      expect(await SessionManager.getProfileJson(), contains('"id":123'));
      await SessionManager.clearSession();
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

    test('login 200 con estructura flat del backend incluye usuario', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': _fakeToken(),
            'id': 456,
            'email': 'test@foodly.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      final response = await repository.login(
        email: 'test@foodly.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(response.usuario, isNotNull);
      expect(response.usuario!.id, 456);
      expect(response.usuario!.email, 'test@foodly.com');
      expect(response.usuario!.tipo, 'CLIENTE');

      await SessionManager.clearSession();
    });
  });
}
