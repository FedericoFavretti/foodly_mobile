import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/direccion_model.dart';
import 'package:foodly_mobile/data/models/plato_model.dart';
import 'package:foodly_mobile/data/repositories/pedido_repository.dart';
import 'package:foodly_mobile/domain/cart/cart_item.dart';
import 'package:foodly_mobile/domain/pedido/medio_pago.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  final items = [
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
  ];

  const domicilio = DireccionModel(
    calle: 'Av. 18 de Julio',
    numero: '1200',
    ciudad: 'Montevideo',
  );

  group('PedidoRepository', () {
    test('realizarPedido envía mercadopago en el body', () async {
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
            'medioDePago': 'mercadopago',
            'mpInitPoint': 'https://mp.test/checkout',
            'local': {'id': 1, 'nombre': 'Burger House'},
            'detalles': [],
          }),
          200,
        );
      });

      final repository = PedidoRepository(api: ApiClient(client: client));
      final response = await repository.realizarPedido(
        clienteId: 5,
        localId: 1,
        domicilio: domicilio,
        items: items,
        medioPago: MedioPago.mercadoPago,
      );

      expect(response.id, 99);
      expect(response.mpInitPoint, 'https://mp.test/checkout');
      final dtPedido = capturedBody?['dtPedido'] as Map<String, dynamic>?;
      expect(dtPedido?['medioDePago'], 'mercadopago');
      expect(dtPedido?['pagoSimulado'], false);
    });

    test('realizarPedido envía efectivo en el body', () async {
      await SessionManager.saveToken('test.token.value');

      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 100,
            'total': 840.0,
            'estado': 'Pendiente',
            'medioDePago': 'efectivo',
            'local': {'id': 1, 'nombre': 'Burger House'},
            'detalles': [],
          }),
          200,
        );
      });

      final repository = PedidoRepository(api: ApiClient(client: client));
      await repository.realizarPedido(
        clienteId: 5,
        localId: 1,
        domicilio: domicilio,
        items: items,
        medioPago: MedioPago.efectivo,
      );

      final dtPedido = capturedBody?['dtPedido'] as Map<String, dynamic>?;
      expect(dtPedido?['medioDePago'], 'efectivo');
      expect(dtPedido?['pagoSimulado'], false);
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
          medioPago: MedioPago.efectivo,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
