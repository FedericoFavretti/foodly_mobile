import 'direccion_model.dart';

class PedidoResponseModel {
  const PedidoResponseModel({
    required this.id,
    required this.total,
    required this.estado,
    required this.localNombre,
    required this.detalles,
    this.domicilioEntrega,
  });

  final int id;
  final double total;
  final String estado;
  final String localNombre;
  final DireccionModel? domicilioEntrega;
  final List<PedidoDetalleModel> detalles;

  factory PedidoResponseModel.fromJson(Map<String, dynamic> json) {
    final localJson = json['local'];
    final detallesRaw = json['detalles'];
    final detalles = detallesRaw is List
        ? detallesRaw
            .whereType<Map<String, dynamic>>()
            .map(PedidoDetalleModel.fromJson)
            .toList()
        : <PedidoDetalleModel>[];

    final domicilioJson = json['domicilioEntrega'];

    return PedidoResponseModel(
      id: (json['id'] as num).toInt(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      estado: json['estado']?.toString() ?? 'Pendiente',
      localNombre: localJson is Map<String, dynamic>
          ? localJson['nombre'] as String? ?? ''
          : '',
      domicilioEntrega: domicilioJson is Map<String, dynamic>
          ? DireccionModel.fromJson(domicilioJson)
          : null,
      detalles: detalles,
    );
  }
}

class PedidoDetalleModel {
  const PedidoDetalleModel({
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.platoNombre,
  });

  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String platoNombre;

  factory PedidoDetalleModel.fromJson(Map<String, dynamic> json) {
    final platoJson = json['plato'];
    return PedidoDetalleModel(
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      platoNombre: platoJson is Map<String, dynamic>
          ? platoJson['nombre'] as String? ?? ''
          : '',
    );
  }
}
