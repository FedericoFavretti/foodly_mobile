class ReclamoListadoModel {
  const ReclamoListadoModel({
    required this.id,
    required this.motivo,
    required this.estado,
    required this.pedidoId,
    required this.localNombre,
    this.tipoCompensacion,
    this.montoReintegro,
    this.fecha,
    this.localId,
    this.pedidoEstado,
    this.pedidoTotal,
  });

  final int id;
  final String motivo;
  final String estado;
  final String? tipoCompensacion;
  final double? montoReintegro;
  final DateTime? fecha;
  final int pedidoId;
  final int? localId;
  final String localNombre;
  final String? pedidoEstado;
  final double? pedidoTotal;

  bool get esPendiente => estado.toLowerCase() == 'pendiente';

  bool get esAtendido => estado.toLowerCase() == 'atendido';

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

  String? get compensacionLabel {
    final tipo = tipoCompensacion?.trim();
    if (tipo == null || tipo.isEmpty) return null;
    final normalized = tipo.toLowerCase();
    if (normalized == 'reintegro') return 'Reintegro';
    if (normalized == 'compensacion' || normalized == 'compensación') {
      return 'Compensación alternativa';
    }
    return tipo;
  }

  factory ReclamoListadoModel.fromJson(Map<String, dynamic> json) {
    final pedidoJson = json['dtPedido'];
    final localJson = pedidoJson is Map<String, dynamic>
        ? pedidoJson['dtLocal']
        : null;

    return ReclamoListadoModel(
      id: (json['id'] as num).toInt(),
      motivo: json['motivo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'Pendiente',
      tipoCompensacion: json['tipoCompensacion']?.toString(),
      montoReintegro: (json['montoReintegro'] as num?)?.toDouble(),
      fecha: _parseFecha(json['fecha']),
      pedidoId: pedidoJson is Map<String, dynamic>
          ? (pedidoJson['id'] as num).toInt()
          : 0,
      localId: localJson is Map<String, dynamic> && localJson['id'] != null
          ? (localJson['id'] as num).toInt()
          : null,
      localNombre: localJson is Map<String, dynamic>
          ? localJson['nombre']?.toString() ?? 'Local'
          : 'Local',
      pedidoEstado: pedidoJson is Map<String, dynamic>
          ? pedidoJson['estado']?.toString()
          : null,
      pedidoTotal: pedidoJson is Map<String, dynamic>
          ? (pedidoJson['total'] as num?)?.toDouble()
          : null,
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
