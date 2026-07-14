import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/notificacion_model.dart';
import '../../data/repositories/notificacion_repository.dart';

class NotificacionNotifier extends ChangeNotifier {
  NotificacionNotifier(this._repository);

  final NotificacionRepository _repository;

  List<NotificacionModel> _notificaciones = [];
  bool _cargando = false;
  Timer? _timer;

  List<NotificacionModel> get notificaciones => _notificaciones;

  bool get cargando => _cargando;

  int get noLeidasCount =>
      _notificaciones.where((n) => !n.leida).length;

  static const _intervalo = Duration(seconds: 30);

  void startPolling() {
    if (_timer?.isActive ?? false) return;
    _fetch();
    _timer = Timer.periodic(_intervalo, (_) => _fetch());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    try {
      final lista = await _repository.listarMias();
      _notificaciones = lista;
      notifyListeners();
    } catch (_) {
      // Fallo silencioso: el polling reintentará en el próximo ciclo
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> marcarLeida(int id) async {
    try {
      await _repository.marcarLeida(id);
      _notificaciones = _notificaciones
          .map((n) => n.id == id ? n.copyWith(leida: true) : n)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marcarTodasLeidas() async {
    final noLeidas =
        _notificaciones.where((n) => !n.leida).map((n) => n.id).toList();
    if (noLeidas.isEmpty) return;
    for (final id in noLeidas) {
      await _repository.marcarLeida(id);
    }
    _notificaciones =
        _notificaciones.map((n) => n.copyWith(leida: true)).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
