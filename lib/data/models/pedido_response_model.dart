import '../../domain/pedido/pedido_delivery_time.dart';
import 'direccion_model.dart';

class PedidoResponseModel {
  const PedidoResponseModel({
    required this.id,
    required this.total,
    required this.estado,
    required this.localNombre,
    required this.detalles,
    this.localId,
    this.fecha,
    this.motivoRechazo,
    this.domicilioEntrega,
    this.tieneReclamo = false,
    this.medioDePago,
    this.mpInitPoint,
    this.tiempoEntregaMinutos,
    this.estadoVisible,
    this.pagoPendiente = false,
    this.permiteReintentarPago = false,
    this.cantidadItems,
  });

  final int id;
  final double total;
  final String estado;
  final String localNombre;
  final int? localId;
  final DateTime? fecha;
  final String? motivoRechazo;
  final DireccionModel? domicilioEntrega;
  final List<PedidoDetalleModel> detalles;
  final bool tieneReclamo;
  final String? medioDePago;
  final String? mpInitPoint;
  final int? tiempoEntregaMinutos;
  /// Estado legible para mostrar al usuario (e.g. "Pago pendiente").
  final String? estadoVisible;
  /// true cuando el pago MP fue iniciado pero aún no confirmado.
  final bool pagoPendiente;
  /// true cuando el usuario puede reintentar el pago MP.
  final bool permiteReintentarPago;
  /// Cantidad total de ítems del pedido (disponible en historial).
  final int? cantidadItems;

  bool get tieneTiempoEntrega =>
      tiempoEntregaMinutos != null && tiempoEntregaMinutos! > 0;

  /// Estado canónico del backend (`Pendiente`, `Confirmado`, etc.).
  String get estadoNormalizado => PedidoResponseModel.normalizarEstado(estado);

  bool get requierePagoMercadoPago =>
      medioDePago?.toLowerCase() == 'mercadopago';

  bool get puedeCompletarPagoMercadoPago {
    if (mpInitPoint == null || mpInitPoint!.trim().isEmpty) return false;
    // Campos explícitos del backend (historial paginado / reintentar-pago).
    if (permiteReintentarPago || pagoPendiente) return true;
    // Fallback para pedidos recién creados donde los flags aún no llegan.
    return estadoNormalizado.toLowerCase() == 'pendiente' &&
        requierePagoMercadoPago;
  }

  bool get esActivo {
    final normalized = estadoNormalizado.toLowerCase();
    return normalized == 'pendiente' || normalized == 'confirmado';
  }

  String? get medioPagoLabel {
    final medio = medioDePago?.toLowerCase();
    if (medio == null || medio.isEmpty) return null;
    if (medio == 'mercadopago') return 'Mercado Pago';
    if (medio == 'efectivo') return 'Efectivo';
    return medioDePago;
  }

  String? get fechaLegible {
    final value = fecha;
    if (value == null) return null;
    final local = value.toLocal();
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'set',
      'oct',
      'nov',
      'dic',
    ];
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${meses[local.month - 1]} ${local.year}, $hora:$minuto';
  }

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
    final motivo = json['motivoRechazo'] as String?;

    return PedidoResponseModel(
      id: (json['id'] as num).toInt(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      estado: normalizarEstado(json['estado']),
      localNombre: localJson is Map<String, dynamic>
          ? localJson['nombre'] as String? ?? ''
          : '',
      localId: localJson is Map<String, dynamic> && localJson['id'] != null
          ? (localJson['id'] as num).toInt()
          : null,
      fecha: _parseFecha(json['fecha']),
      motivoRechazo: motivo != null && motivo.trim().isNotEmpty ? motivo : null,
      domicilioEntrega: domicilioJson is Map<String, dynamic>
          ? DireccionModel.fromJson(domicilioJson)
          : null,
      detalles: detalles,
      tieneReclamo: json['tieneReclamo'] == true,
      medioDePago: json['medioDePago'] as String?,
      mpInitPoint: json['mpInitPoint'] as String?,
      tiempoEntregaMinutos:
          PedidoDeliveryTime.parseMinutes(json['tiempoEstEntrega']),
      estadoVisible: json['estadoVisible'] as String?,
      pagoPendiente: json['pagoPendiente'] == true,
      permiteReintentarPago: json['permiteReintentarPago'] == true,
      cantidadItems: (json['cantidadItems'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String normalizarEstado(dynamic value) {
    if (value == null) return 'Pendiente';
    final raw = value.toString().trim();
    if (raw.isEmpty) return 'Pendiente';

    const map = {
      'pendiente': 'Pendiente',
      'confirmado': 'Confirmado',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado',
      'rechazado': 'Rechazado',
    };

    return map[raw.toLowerCase()] ?? raw;
  }

  PedidoResponseModel copyWith({
    int? id,
    double? total,
    String? estado,
    String? localNombre,
    int? localId,
    DateTime? fecha,
    String? motivoRechazo,
    DireccionModel? domicilioEntrega,
    List<PedidoDetalleModel>? detalles,
    bool? tieneReclamo,
    String? medioDePago,
    String? mpInitPoint,
    int? tiempoEntregaMinutos,
    String? estadoVisible,
    bool? pagoPendiente,
    bool? permiteReintentarPago,
    int? cantidadItems,
  }) {
    return PedidoResponseModel(
      id: id ?? this.id,
      total: total ?? this.total,
      estado: estado ?? this.estado,
      localNombre: localNombre ?? this.localNombre,
      localId: localId ?? this.localId,
      fecha: fecha ?? this.fecha,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      domicilioEntrega: domicilioEntrega ?? this.domicilioEntrega,
      detalles: detalles ?? this.detalles,
      tieneReclamo: tieneReclamo ?? this.tieneReclamo,
      medioDePago: medioDePago ?? this.medioDePago,
      mpInitPoint: mpInitPoint ?? this.mpInitPoint,
      tiempoEntregaMinutos: tiempoEntregaMinutos ?? this.tiempoEntregaMinutos,
      estadoVisible: estadoVisible ?? this.estadoVisible,
      pagoPendiente: pagoPendiente ?? this.pagoPendiente,
      permiteReintentarPago:
          permiteReintentarPago ?? this.permiteReintentarPago,
      cantidadItems: cantidadItems ?? this.cantidadItems,
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
