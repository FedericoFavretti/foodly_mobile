import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/notificacion_model.dart';
import '../../data/repositories/notificacion_repository.dart';

class NotificacionNotifier extends ChangeNotifier {
  NotificacionNotifier(this._repository);

  final NotificacionRepository _repository;

  List<NotificacionModel> _notificaciones = [];
  bool _cargando = false;
  bool _disposed = false;
  Timer? _timer;

  List<NotificacionModel> get notificaciones => _notificaciones;

  bool get cargando => _cargando;

  int get noLeidasCount =>
      _notificaciones.where((n) => !n.leida).length;

  static const _intervalo = Duration(seconds: 30);

  void startPolling() {
    if (_disposed) return;
    if (_timer?.isActive ?? false) return;
    _fetch();
    _timer = Timer.periodic(_intervalo, (_) => _fetch());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    if (_disposed) return;
    try {
      final lista = await _repository.listarMias();
      if (_disposed) return; // segunda verificación tras el await
      _notificaciones = lista;
      notifyListeners();
    } catch (_) {
      // Fallo silencioso: el polling reintentará en el próximo ciclo
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> marcarLeida(int id) async {
    if (_disposed) return;
    try {
      await _repository.marcarLeida(id);
      if (_disposed) return;
      _notificaciones = _notificaciones
          .map((n) => n.id == id ? n.copyWith(leida: true) : n)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marcarTodasLeidas() async {
    if (_disposed) return;
    final noLeidas =
        _notificaciones.where((n) => !n.leida).map((n) => n.id).toList();
    if (noLeidas.isEmpty) return;
    for (final id in noLeidas) {
      await _repository.marcarLeida(id);
    }
    if (_disposed) return;
    _notificaciones =
        _notificaciones.map((n) => n.copyWith(leida: true)).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}
