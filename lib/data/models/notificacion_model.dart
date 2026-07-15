import 'package:intl/intl.dart';

class NotificacionModel {
  const NotificacionModel({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.canal,
    required this.leida,
    this.fecha,
    this.pedidoId,
    this.reclamoId,
  });

  final int id;
  final String tipo;
  final String mensaje;
  final String canal;
  final bool leida;
  final DateTime? fecha;
  final int? pedidoId;
  final int? reclamoId;

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as int,
      tipo: json['tipo'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      canal: json['canal'] as String? ?? '',
      leida: json['leida'] as bool? ?? false,
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'] as String)
          : null,
      pedidoId: (json['dtPedido'] as Map<String, dynamic>?)?['id'] as int?,
      reclamoId: (json['dtReclamo'] as Map<String, dynamic>?)?['id'] as int?,
    );
  }

  NotificacionModel copyWith({bool? leida}) {
    return NotificacionModel(
      id: id,
      tipo: tipo,
      mensaje: mensaje,
      canal: canal,
      leida: leida ?? this.leida,
      fecha: fecha,
      pedidoId: pedidoId,
      reclamoId: reclamoId,
    );
  }

  String get fechaFormateada {
    if (fecha == null) return '';
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha!);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return DateFormat('dd/MM HH:mm').format(fecha!);
  }
}
