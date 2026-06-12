import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../data/models/local_model.dart';
import '../../data/models/plato_model.dart';
import 'cart_item.dart';

class CartConflictException implements Exception {
  const CartConflictException(this.message);

  final String message;
}

class CartNotifier extends ChangeNotifier {
  CartNotifier._();

  static final CartNotifier instance = CartNotifier._();

  int? _localId;
  String? _localNombre;
  bool _localAbierto = true;
  final List<CartItem> _items = [];

  int? get localId => _localId;
  String? get localNombre => _localNombre;
  bool get localAbierto => _localAbierto;
  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalItems =>
      _items.fold<int>(0, (sum, item) => sum + item.cantidad);

  double get estimatedTotal =>
      _items.fold<double>(0, (sum, item) => sum + item.subtotal);

  void addPlato({required PlatoModel plato, required LocalModel local}) {
    if (!local.estaAbierto) {
      throw const CartConflictException(
        'Este local está cerrado y no acepta pedidos por el momento.',
      );
    }
    if (!plato.disponible) {
      throw const CartConflictException('Este plato no está disponible.');
    }
    if (_localId != null && _localId != local.id) {
      throw CartConflictException(
        'Tu carrito tiene platos de $_localNombre. Vacíalo para pedir en ${local.nombre}.',
      );
    }

    _localId = local.id;
    _localNombre = local.nombre;
    _localAbierto = local.estaAbierto;

    final index = _items.indexWhere((item) => item.plato.id == plato.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        cantidad: _items[index].cantidad + 1,
      );
    } else {
      _items.add(CartItem(plato: plato, cantidad: 1));
    }
    notifyListeners();
  }

  void updateQuantity(int platoId, int cantidad) {
    if (cantidad <= 0) {
      removePlato(platoId);
      return;
    }
    final index = _items.indexWhere((item) => item.plato.id == platoId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(cantidad: cantidad);
    notifyListeners();
  }

  void removePlato(int platoId) {
    _items.removeWhere((item) => item.plato.id == platoId);
    if (_items.isEmpty) {
      _localId = null;
      _localNombre = null;
      _localAbierto = true;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _localId = null;
    _localNombre = null;
    _localAbierto = true;
    notifyListeners();
  }

  void replaceLocalAndAdd({
    required PlatoModel plato,
    required LocalModel local,
  }) {
    clear();
    addPlato(plato: plato, local: local);
  }

  @visibleForTesting
  void resetForTest() {
    clear();
  }
}
