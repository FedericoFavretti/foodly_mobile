import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/reclamo_listado_model.dart';
import 'package:foodly_mobile/data/repositories/pedido_repository.dart';
import 'package:foodly_mobile/data/repositories/reclamo_repository.dart';
import 'package:foodly_mobile/domain/reclamo/reclamo_rules.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SessionManager.resetForTest();
    await SessionManager.saveToken('test.token');
  });

  group('ReclamoRules', () {
    test('permite reclamar pedidos confirmados y entregados sin reclamo previo', () {
      expect(
        ReclamoRules.puedeReclamar(estado: 'Confirmado', tieneReclamo: false),
        isTrue,
      );
      expect(
        ReclamoRules.puedeReclamar(estado: 'Entregado', tieneReclamo: false),
        isTrue,
      );
    });

    test('no permite reclamar si ya hay reclamo o estado inválido', () {
      expect(
        ReclamoRules.puedeReclamar(estado: 'Confirmado', tieneReclamo: true),
        isFalse,
      );
      expect(
        ReclamoRules.puedeReclamar(estado: 'Pendiente', tieneReclamo: false),
        isFalse,
      );
    });

    test('expone las etiquetas de tipo de compensación', () {
      expect(ReclamoRules.tipoReintegro, 'Reintegro');
      expect(ReclamoRules.tipoAlternativa, 'Otra');
    });
  });

  group('ReclamoListadoModel', () {
    test('fromJson parsea pedido anidado y compensación', () {
      final model = ReclamoListadoModel.fromJson({
        'id': 3,
        'motivo': 'Pedido incompleto',
        'estado': 'Pendiente',
        'tipoCompensacion': 'Reintegro',
        'montoReintegro': 400,
        'fecha': '2026-06-20T15:30:00',
        'dtPedido': {
          'id': 12,
          'estado': 'Entregado',
          'total': 400,
          'dtLocal': {'id': 5, 'nombre': 'Pizza House'},
        },
      });

      expect(model.id, 3);
      expect(model.pedidoId, 12);
      expect(model.localNombre, 'Pizza House');
      expect(model.esPendiente, isTrue);
      expect(model.compensacionLabel, 'Reintegro');
      expect(model.fechaLegible, isNotNull);
    });
  });

  group('ReclamoRepository', () {
    test('realizarReclamo envía body esperado al backend', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/reclamos/realizar_reclamo');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = ReclamoRepository(api: ApiClient(client: client));
      await repository.realizarReclamo(
        pedidoId: 12,
        motivo: 'Llegó frío',
        tipoCompensacion: ReclamoRules.tipoReintegro,
      );

      expect(capturedBody?['motivo'], 'Llegó frío');
      expect(capturedBody?['tipoCompensacion'], 'Reintegro');
      expect(capturedBody?.containsKey('montoReintegro'), isFalse);
      expect(capturedBody?['dtPedido'], {'id': 12});
    });

    test('400 del backend lanza ApiException con mensaje', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'mensaje': 'No pudimos registrar el reclamo.'}),
          400,
        );
      });

      final repository = ReclamoRepository(api: ApiClient(client: client));

      expect(
        () => repository.realizarReclamo(
          pedidoId: 12,
          motivo: 'Problema',
          tipoCompensacion: ReclamoRules.tipoReintegro,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('No pudimos registrar'),
          ),
        ),
      );
    });

    test('obtenerReclamoDePedido devuelve null en 404', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/reclamos/mi-reclamo/99');
        return http.Response('', 404);
      });

      final repository = ReclamoRepository(api: ApiClient(client: client));
      final reclamo = await repository.obtenerReclamoDePedido(99);
      expect(reclamo, isNull);
    });

    test('listarMisReclamos consulta historial y reclamos por pedido', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/pedidos/mi-historial') {
          return http.Response(
            jsonEncode([
              {
                'id': 10,
                'total': 500,
                'estado': 'Entregado',
                'local': {'id': 1, 'nombre': 'Sushi Bar'},
                'detalles': [],
              },
              {
                'id': 11,
                'total': 300,
                'estado': 'Pendiente',
                'local': {'id': 2, 'nombre': 'Otro'},
                'detalles': [],
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/reclamos/mi-reclamo/10') {
          return http.Response(
            jsonEncode({
              'id': 7,
              'motivo': 'Faltó un plato',
              'estado': 'Atendido',
              'tipoCompensacion': 'reintegro',
              'montoReintegro': 500,
              'fecha': '2026-06-21T10:00:00',
              'dtPedido': {
                'id': 10,
                'estado': 'Entregado',
                'total': 500,
                'dtLocal': {'id': 1, 'nombre': 'Sushi Bar'},
              },
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      final api = ApiClient(client: client);
      final repository = ReclamoRepository(
        api: api,
        pedidoRepository: PedidoRepository(api: api),
      );

      final reclamos = await repository.listarMisReclamos();
      expect(reclamos, hasLength(1));
      expect(reclamos.first.id, 7);
      expect(reclamos.first.esAtendido, isTrue);
      expect(reclamos.first.localNombre, 'Sushi Bar');
    });
  });
}
