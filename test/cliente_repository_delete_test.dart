import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/cliente_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  group('ClienteRepository.eliminarCuenta()', () {
    test('200 → no lanza excepción', () async {
      final client = MockClient(
        (_) async => http.Response('', 200),
      );
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

    test('404 → lanza ApiException con mensaje de endpoint no disponible',
        () async {
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
            503,
          ),
        ),
      );
    });

    test('405 → lanza ApiException indicando pendiente de backend', () async {
      final client = MockClient(
        (_) async => http.Response('Method Not Allowed', 405),
      );
      final repo = ClienteRepository(
        api: ApiClient(client: client),
      );
      Object? caught;
      try {
        await repo.eliminarCuenta();
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<ApiException>());
      expect(
        (caught as ApiException).userMessage,
        contains('no está disponible'),
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
  });
}
