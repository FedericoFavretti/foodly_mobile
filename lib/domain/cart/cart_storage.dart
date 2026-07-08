import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_snapshot.dart';

/// Persistencia local del carrito (C4).
class CartStorage {
  CartStorage({SharedPreferences? preferences}) : _preferences = preferences;

  static const cartKey = 'foodly_cart_v1';
  static const pendingMpPedidoKey = 'foodly_pending_mp_pedido_id';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? await SharedPreferences.getInstance();

  Future<void> save(CartSnapshot snapshot) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(cartKey, jsonEncode(snapshot.toJson()));
    } catch (_) {}
  }

  Future<CartSnapshot?> load() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(cartKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final snapshot = CartSnapshot.fromJson(json);
      if (snapshot.items.isEmpty) return null;
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(cartKey);
    } catch (_) {}
  }

  Future<void> savePendingMpPedidoId(int pedidoId) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(pendingMpPedidoKey, pedidoId);
    } catch (_) {}
  }

  Future<int?> loadPendingMpPedidoId() async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(pendingMpPedidoKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingMpPedidoId() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(pendingMpPedidoKey);
    } catch (_) {}
  }

  @visibleForTesting
  static void setMockPreferences(SharedPreferences preferences) {
    SharedPreferences.setMockInitialValues({});
  }
}
