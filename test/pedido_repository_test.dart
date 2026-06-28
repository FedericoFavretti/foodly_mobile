import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/direccion_model.dart';
import 'package:foodly_mobile/data/models/plato_model.dart';
import 'package:foodly_mobile/data/repositories/pedido_repository.dart';
import 'package:foodly_mobile/domain/cart/cart_item.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  group('PedidoRepository', () {
    test('realizarPedido envía body esperado', () async {
      await SessionManager.saveToken('test.token.value');

      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/pedidos');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 99,
            'total': 840.0,
            'estado': 'Pendiente',
            'local': {'id': 1, 'nombre': 'Burger House'},
            'detalles': [
              {
                'cantidad': 2,
                'precioUnitario': 420.0,
                'subtotal': 840.0,
                'plato': {'nombre': 'Clásica'},
              },
            ],
          }),
          200,
        );
      });

      final repository = PedidoRepository(api: ApiClient(client: client));
      final response = await repository.realizarPedido(
        clienteId: 5,
        localId: 1,
        domicilio: const DireccionModel(
          calle: 'Av. 18 de Julio',
          numero: '1200',
          ciudad: 'Montevideo',
        ),
        items: [
          CartItem(
            plato: const PlatoModel(
              id: 101,
              nombre: 'Clásica',
              descripcion: '',
              precio: 420,
              imagenes: [],
              disponible: true,
              localId: 1,
            ),
            cantidad: 2,
          ),
        ],
      );

      expect(response.id, 99);
      expect(response.estado, 'Pendiente');
      final dtPedido = capturedBody?['dtPedido'] as Map<String, dynamic>?;
      expect(dtPedido?['dtCliente'], {'id': 5});
      expect(dtPedido?['medioDePago'], 'simulado');
      expect(dtPedido?['pagoSimulado'], true);
      expect(capturedBody?['detalles'], isList);
    });

    test('carrito vacío lanza ApiException', () async {
      final repository = PedidoRepository();

      expect(
        () => repository.realizarPedido(
          clienteId: 1,
          localId: 1,
          domicilio: const DireccionModel(
            calle: 'A',
            numero: '1',
            ciudad: 'MVD',
          ),
          items: [],
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
