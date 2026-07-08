import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/constants/api_constants.dart';
import 'package:foodly_mobile/core/constants/foodly_deep_link_constants.dart';

void main() {
  group('FoodlyDeepLinkParser', () {
    test('parsea retorno exitoso de Mercado Pago', () {
      final action = FoodlyDeepLinkParser.parse(
        Uri.parse('foodly://payment/success?pedidoId=42'),
      );

      expect(action, isNotNull);
      expect(action!.status, MercadoPagoReturnStatus.success);
      expect(action.pedidoId, 42);
    });

    test('parsea failure y pending', () {
      expect(
        FoodlyDeepLinkParser.parse(
          Uri.parse('foodly://payment/failure'),
        )?.status,
        MercadoPagoReturnStatus.failure,
      );
      expect(
        FoodlyDeepLinkParser.parse(
          Uri.parse('foodly://payment/pending'),
        )?.status,
        MercadoPagoReturnStatus.pending,
      );
    });

    test('ignora esquemas ajenos', () {
      expect(
        FoodlyDeepLinkParser.parse(Uri.parse('https://foodly.com/payment/success')),
        isNull,
      );
    });
  });

  group('ApiConstants', () {
    test('cancelarPedidoEndpoint construye ruta esperada', () {
      expect(
        ApiConstants.cancelarPedidoEndpoint(42),
        '/api/v1/pedidos/42/cancelar',
      );
    });

    test('miReclamoPedidoEndpoint construye ruta esperada', () {
      expect(
        ApiConstants.miReclamoPedidoEndpoint(7),
        '/api/v1/reclamos/mi-reclamo/7',
      );
    });
  });
}
