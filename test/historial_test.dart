import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/pedido_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PedidoRepository.listarHistorial', () {
    test('parsea lista de pedidos', () async {
      final body = jsonEncode([
        {
          'id': 1,
          'total': 350.0,
          'estado': 'Pendiente',
          'local': {'nombre': 'Burger World'},
          'domicilioEntrega': {
            'calle': '18 de Julio',
            'numero': '1234',
            'ciudad': 'Montevideo',
          },
          'detalles': [
            {
              'cantidad': 2,
              'precioUnitario': 175.0,
              'subtotal': 350.0,
              'plato': {'nombre': 'Hamburguesa clásica'},
            },
          ],
        },
        {
          'id': 2,
          'total': 200.0,
          'estado': 'Cancelado',
          'local': {'nombre': 'Pizza House'},
          'domicilioEntrega': null,
          'detalles': [],
        },
      ]);

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/pedidos/cliente');
        return http.Response(body, 200);
      });

      final repo = PedidoRepository(api: ApiClient(client: client));
      final pedidos = await repo.listarHistorial();

      expect(pedidos.length, 2);
      expect(pedidos[0].id, 1);
      expect(pedidos[0].estado, 'Pendiente');
      expect(pedidos[0].localNombre, 'Burger World');
      expect(pedidos[0].detalles.length, 1);
      expect(pedidos[0].detalles.first.platoNombre, 'Hamburguesa clásica');
      expect(pedidos[1].estado, 'Cancelado');
    });

    test('lista vacía retorna empty list', () async {
      final client = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final repo = PedidoRepository(api: ApiClient(client: client));
      final pedidos = await repo.listarHistorial();
      expect(pedidos, isEmpty);
    });

    test('null body retorna empty list', () async {
      final client = MockClient((request) async {
        return http.Response('null', 200);
      });

      final repo = PedidoRepository(api: ApiClient(client: client));
      final pedidos = await repo.listarHistorial();
      expect(pedidos, isEmpty);
    });
  });

  group('PedidoRepository.cancelarPedido', () {
    test('200 completa sin error', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/pedidos/42/cancelar');
        expect(request.method, 'POST');
        return http.Response('', 200);
      });

      final repo = PedidoRepository(api: ApiClient(client: client));
      await repo.cancelarPedido(42);
    });

    test('400 lanza ApiException con mensaje', () async {
      final client = MockClient((request) async {
        return http.Response(
          'No es posible cancelar este pedido porque ya fue confirmado por el local.',
          400,
        );
      });

      final repo = PedidoRepository(api: ApiClient(client: client));

      expect(
        () => repo.cancelarPedido(42),
        throwsA(
          isA<ApiException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('No es posible cancelar'),
          ),
        ),
      );
    });
  });
}
