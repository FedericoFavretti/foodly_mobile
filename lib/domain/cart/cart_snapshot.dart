import '../../data/models/plato_model.dart';
import 'cart_item.dart';

/// Estado serializable del carrito para SharedPreferences.
class CartSnapshot {
  const CartSnapshot({
    required this.localId,
    required this.localNombre,
    required this.localAbierto,
    required this.items,
  });

  final int localId;
  final String localNombre;
  final bool localAbierto;
  final List<CartItem> items;

  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'localNombre': localNombre,
      'localAbierto': localAbierto,
      'items': items
          .map(
            (item) => {
              'cantidad': item.cantidad,
              'plato': _platoToJson(item.plato),
            },
          )
          .toList(),
    };
  }

  factory CartSnapshot.fromJson(Map<String, dynamic> json) {
    final localId = json['localId'];
    if (localId is! num) {
      throw FormatException('Carrito sin localId válido');
    }

    final itemsRaw = json['items'];
    final items = <CartItem>[];
    if (itemsRaw is List) {
      for (final raw in itemsRaw) {
        if (raw is! Map<String, dynamic>) continue;
        final platoJson = raw['plato'];
        final cantidad = raw['cantidad'];
        if (platoJson is! Map<String, dynamic> || cantidad is! num) continue;
        final plato = PlatoModel.fromJson(platoJson);
        if (cantidad.toInt() <= 0) continue;
        items.add(CartItem(plato: plato, cantidad: cantidad.toInt()));
      }
    }

    return CartSnapshot(
      localId: localId.toInt(),
      localNombre: json['localNombre'] as String? ?? '',
      localAbierto: json['localAbierto'] as bool? ?? true,
      items: items,
    );
  }

  static Map<String, dynamic> _platoToJson(PlatoModel plato) {
    return {
      'id': plato.id,
      'nombre': plato.nombre,
      'descripcion': plato.descripcion,
      'precio': plato.precio,
      'imagenes': plato.imagenes,
      'disponible': plato.disponible,
      'localId': plato.localId,
      if (plato.precioOriginal != null) 'precioOriginal': plato.precioOriginal,
      if (plato.tienePromocion) 'tienePromocion': true,
      if (plato.descuentoPercent != null)
        'descuentoPercent': plato.descuentoPercent,
      if (plato.promocionId != null) 'promocionId': plato.promocionId,
      if (plato.promocionTitulo != null)
        'promocionTitulo': plato.promocionTitulo,
    };
  }
}
