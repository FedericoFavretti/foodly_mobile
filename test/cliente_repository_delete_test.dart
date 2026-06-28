import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/cliente_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SessionManager.resetForTest();
    await SessionManager.saveToken('test.token');
  });

  group('ClienteRepository.eliminarCuenta()', () {
    test('200 → no lanza excepción', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/mi-cuenta');
        expect(request.method, 'DELETE');
        return http.Response('', 200);
      });
      final repo = ClienteRepository(
        api: ApiClient(client: client),
      );
      await expectLater(repo.eliminarCuenta(), completes);
    });

    test('204 → no lanza excepción', () async {
      final client = MockClient(
        (_) async => http.Response('', 204),
      );
      final repo = ClienteRepository(
        api: ApiClient(client: client),
      );
      await expectLater(repo.eliminarCuenta(), completes);
    });

    test('404 → lanza ApiException', () async {
      final client = MockClient(
        (_) async => http.Response('Not Found', 404),
      );
      final repo = ClienteRepository(
        api: ApiClient(client: client),
      );
      await expectLater(
        repo.eliminarCuenta(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('500 → lanza ApiException genérica', () async {
      final client = MockClient(
        (_) async => http.Response('Internal Server Error', 500),
      );
      final repo = ClienteRepository(
        api: ApiClient(client: client),
      );
      await expectLater(
        repo.eliminarCuenta(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('sin sesión → lanza ApiException 401', () async {
      await SessionManager.clearSession();
      final client = MockClient(
        (_) async => http.Response('', 200),
      );
      final repo = ClienteRepository(
        api: ApiClient(client: client),
      );
      await expectLater(
        repo.eliminarCuenta(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });
}
