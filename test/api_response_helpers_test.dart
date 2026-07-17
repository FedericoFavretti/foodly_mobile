import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/network/api_response_helpers.dart';

void main() {
  group('ApiResponseHelpers.isEmptyResultMessage', () {
    test('reconoce el mensaje real de "sin platos" del backend', () {
      expect(
        ApiResponseHelpers.isEmptyResultMessage(
          'No se encontraron platos o promociones que coincidan con su búsqueda.',
        ),
        isTrue,
      );
    });

    test('reconoce el mensaje real de "sin pedidos" del backend', () {
      expect(
        ApiResponseHelpers.isEmptyResultMessage(
          'No se encontraron pedidos que coincidan con los criterios seleccionados.',
        ),
        isTrue,
      );
    });

    test('reconoce el mensaje real de "cuenta sin pedidos nunca" del backend '
        '(distinto al de "filtro sin coincidencias")', () {
      expect(
        ApiResponseHelpers.isEmptyResultMessage(
          'Aún no ha realizado ningún pedido. ¡Explore los locales '
          'disponibles y realice su primer pedido!',
        ),
        isTrue,
      );
    });

    test('no confunde un error real con un "sin resultados"', () {
      expect(
        ApiResponseHelpers.isEmptyResultMessage('Token inválido.'),
        isFalse,
      );
      expect(
        ApiResponseHelpers.isEmptyResultMessage(
          'El monto de reintegro no puede superar el total del pedido.',
        ),
        isFalse,
      );
    });

    test('null devuelve false', () {
      expect(ApiResponseHelpers.isEmptyResultMessage(null), isFalse);
    });
  });
}
