import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/calificacion_detalle_model.dart';
import 'package:foodly_mobile/data/models/calificacion_global_model.dart';
import 'package:foodly_mobile/data/models/mi_calificacion_local_model.dart';
import 'package:foodly_mobile/data/models/pedido_response_model.dart';
import 'package:foodly_mobile/data/repositories/calificacion_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SessionManager.resetForTest();
    await SessionManager.saveToken('test.token');
  });

  group('PedidoResponseModel', () {
    test('parsea localId desde el objeto local del historial', () {
      final pedido = PedidoResponseModel.fromJson({
        'id': 5,
        'total': 100,
        'estado': 'Entregado',
        'local': {'id': 10, 'nombre': 'Burger World'},
      });

      expect(pedido.localId, 10);
      expect(pedido.localNombre, 'Burger World');
    });
  });

  group('MiCalificacionLocalModel', () {
    test('fromJson parsea puntaje y comentario', () {
      final model = MiCalificacionLocalModel.fromJson({
        'id': 3,
        'puntaje': 4,
        'comentario': 'Muy bueno',
        'fecha': '2026-06-01',
      });

      expect(model.id, 3);
      expect(model.puntaje, 4);
      expect(model.comentario, 'Muy bueno');
    });
  });

  group('CalificacionGlobalModel', () {
    test('fromJson parsea promedio y breakdown', () {
      final model = CalificacionGlobalModel.fromJson({
        'promedio': 4.2,
        'totalCalificaciones': 5,
        'detallePorPuntuacion': {'5': 2, '4': 2, '3': 1},
      });

      expect(model.promedio, 4.2);
      expect(model.totalCalificaciones, 5);
      expect(model.detallePorPuntuacion[5], 2);
      expect(model.detallePorPuntuacion[1], 0);
    });
  });

  group('CalificacionDetalleModel', () {
    test('fromJson parsea local y puntaje', () {
      final model = CalificacionDetalleModel.fromJson({
        'idLocal': 3,
        'nombreLocal': 'Pizza House',
        'puntaje': 5,
        'comentario': 'Cliente puntual',
        'fecha': '2026-06-01T12:00:00',
      });

      expect(model.idLocal, 3);
      expect(model.nombreLocal, 'Pizza House');
      expect(model.puntaje, 5);
    });
  });

  group('CalificacionRepository', () {
    test('calificarLocal envía POST con body esperado', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/calificaciones/calificar');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 204);
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));
      await repository.calificarLocal(
        localId: 10,
        puntaje: 5,
        comentario: 'Excelente',
      );

      expect(capturedBody?['puntaje'], 5);
      expect(capturedBody?['comentario'], 'Excelente');
      expect(capturedBody?['dtLocal'], {'id': 10});
    });

    test('calificarLocal rechaza puntaje fuera de rango', () async {
      final repository = CalificacionRepository(
        api: ApiClient(client: MockClient((_) async => http.Response('', 204))),
      );

      expect(
        () => repository.calificarLocal(localId: 1, puntaje: 0),
        throwsA(isA<ApiException>()),
      );
    });

    test('obtenerMiCalificacion devuelve null con 204', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/api/v1/calificaciones/locales/10/mi-calificacion',
        );
        return http.Response('', 204);
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));
      final result = await repository.obtenerMiCalificacion(10);
      expect(result, isNull);
    });

    test('obtenerMiCalificacion parsea respuesta 200', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 7,
            'puntaje': 3,
            'comentario': 'Regular',
          }),
          200,
        );
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));
      final result = await repository.obtenerMiCalificacion(10);

      expect(result?.id, 7);
      expect(result?.puntaje, 3);
      expect(result?.comentario, 'Regular');
    });

    test('calificarLocal propaga mensaje de error del backend', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'mensaje': 'Debe tener al menos un pedido con el local'}),
          400,
        );
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));

      expect(
        () => repository.calificarLocal(localId: 99, puntaje: 4),
        throwsA(
          isA<ApiException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('al menos un pedido'),
          ),
        ),
      );
    });

    test('obtenerCalificacionRecibida devuelve null si no hay calificaciones', () async {
      final client = MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/calificaciones/7/calificacion',
        );
        return http.Response(
          jsonEncode({
            'mensaje': 'Aún no ha recibido calificaciones de ningún local.',
          }),
          400,
        );
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));
      final result = await repository.obtenerCalificacionRecibida(7);
      expect(result, isNull);
    });

    test('obtenerCalificacionRecibida parsea respuesta 200', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'promedio': 4.5,
            'totalCalificaciones': 2,
            'detallePorPuntuacion': {'5': 1, '4': 1},
          }),
          200,
        );
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));
      final result = await repository.obtenerCalificacionRecibida(7);

      expect(result?.promedio, 4.5);
      expect(result?.totalCalificaciones, 2);
    });

    test('obtenerDetalleCalificacionRecibida parsea lista', () async {
      final client = MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/calificaciones/7/calificacion/detalle',
        );
        return http.Response(
          jsonEncode([
            {
              'idLocal': 1,
              'nombreLocal': 'Burger',
              'puntaje': 5,
              'comentario': 'Buen cliente',
            },
          ]),
          200,
        );
      });

      final repository = CalificacionRepository(api: ApiClient(client: client));
      final result = await repository.obtenerDetalleCalificacionRecibida(7);

      expect(result.length, 1);
      expect(result.first.nombreLocal, 'Burger');
    });
  });
}
