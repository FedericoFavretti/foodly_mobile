import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/cliente_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClienteRepository.registrar()', () {
    test('manda celular dentro de "datos" solo si viene con contenido', () async {
      String? cuerpoCapturado;
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/clientes/registro');
        cuerpoCapturado = utf8.decode(request.bodyBytes, allowMalformed: true);
        return http.Response('', 200);
      });

      final repo = ClienteRepository(api: ApiClient(client: client));
      await repo.registrar(
        const RegistroClienteData(
          email: 'test@foodly.com',
          password: 'Clave1234',
          documento: '12345678',
          nombre: 'Juan',
          apellido: 'Pérez',
          calle: 'Calle',
          numero: '1',
          ciudad: 'Montevideo',
          codigoPostal: '11000',
          celular: '+598991234567',
        ),
      );

      expect(cuerpoCapturado, contains('"celular":"+598991234567"'));
    });

    test('no manda la clave celular si viene vacío o ausente', () async {
      String? cuerpoCapturado;
      final client = MockClient((request) async {
        cuerpoCapturado = utf8.decode(request.bodyBytes, allowMalformed: true);
        return http.Response('', 200);
      });

      final repo = ClienteRepository(api: ApiClient(client: client));
      await repo.registrar(
        const RegistroClienteData(
          email: 'test@foodly.com',
          password: 'Clave1234',
          documento: '12345678',
          nombre: 'Juan',
          apellido: 'Pérez',
          calle: 'Calle',
          numero: '1',
          ciudad: 'Montevideo',
          codigoPostal: '11000',
        ),
      );

      expect(cuerpoCapturado, isNot(contains('celular')));
    });
  });
}
