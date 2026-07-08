import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/data/models/plato_model.dart';
import 'package:foodly_mobile/domain/cart/cart_item.dart';
import 'package:foodly_mobile/domain/cart/cart_snapshot.dart';
import 'package:foodly_mobile/domain/cart/cart_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('save y load restauran ítems del carrito', () async {
      final storage = CartStorage();
      final plato = PlatoModel(
        id: 1,
        nombre: 'Pizza',
        descripcion: 'Muzza',
        precio: 450,
        imagenes: const ['https://cdn.test/pizza.jpg'],
        disponible: true,
        localId: 10,
      );

      await storage.save(
        CartSnapshot(
          localId: 10,
          localNombre: 'Pizzería',
          localAbierto: true,
          items: [CartItem(plato: plato, cantidad: 2)],
        ),
      );

      final loaded = await storage.load();
      expect(loaded, isNotNull);
      expect(loaded!.localId, 10);
      expect(loaded.items.length, 1);
      expect(loaded.items.first.cantidad, 2);
      expect(loaded.items.first.plato.nombre, 'Pizza');
    });

    test('clear elimina snapshot persistido', () async {
      final storage = CartStorage();
      final plato = PlatoModel(
        id: 2,
        nombre: 'Burger',
        descripcion: 'Clásica',
        precio: 300,
        imagenes: const [],
        disponible: true,
        localId: 5,
      );
      await storage.save(
        CartSnapshot(
          localId: 5,
          localNombre: 'Burger',
          localAbierto: true,
          items: [CartItem(plato: plato, cantidad: 1)],
        ),
      );
      await storage.clear();
      expect(await storage.load(), isNull);
    });

    test('pending MP pedido id se guarda y limpia', () async {
      final storage = CartStorage();
      await storage.savePendingMpPedidoId(99);
      expect(await storage.loadPendingMpPedidoId(), 99);
      await storage.clearPendingMpPedidoId();
      expect(await storage.loadPendingMpPedidoId(), isNull);
    });
  });
}
