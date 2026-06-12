import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/data/mock_catalog_data.dart';
import 'package:foodly_mobile/domain/cart/cart_notifier.dart';

void main() {
  setUp(() => CartNotifier.instance.resetForTest());

  group('CartNotifier', () {
    test('agrega plato y calcula total', () {
      final local = mockLocales.first;
      final plato = mockPlatos.firstWhere((p) => p.localId == local.id);

      CartNotifier.instance.addPlato(plato: plato, local: local);
      CartNotifier.instance.addPlato(plato: plato, local: local);

      expect(CartNotifier.instance.totalItems, 2);
      expect(CartNotifier.instance.estimatedTotal, plato.precio * 2);
    });

    test('rechaza plato de otro local sin reemplazar', () {
      final local1 = mockLocales[0];
      final local2 = mockLocales[1];
      final plato1 = mockPlatos.firstWhere((p) => p.localId == local1.id);
      final plato2 = mockPlatos.firstWhere((p) => p.localId == local2.id);

      CartNotifier.instance.addPlato(plato: plato1, local: local1);

      expect(
        () => CartNotifier.instance.addPlato(plato: plato2, local: local2),
        throwsA(isA<CartConflictException>()),
      );
    });

    test('rechaza local cerrado', () {
      final local = mockLocales.firstWhere((l) => !l.estaAbierto);
      final plato = mockPlatos.firstWhere((p) => p.localId == local.id);

      expect(
        () => CartNotifier.instance.addPlato(plato: plato, local: local),
        throwsA(isA<CartConflictException>()),
      );
    });
  });
}
