import '../../data/models/plato_model.dart';

class CartItem {
  const CartItem({required this.plato, required this.cantidad});

  final PlatoModel plato;
  final int cantidad;

  double get subtotal => plato.precio * cantidad;

  CartItem copyWith({int? cantidad}) {
    return CartItem(
      plato: plato,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
