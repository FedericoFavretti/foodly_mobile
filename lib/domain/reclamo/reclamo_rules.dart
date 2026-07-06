/// Reglas de negocio para reclamos (CU-CL09).
abstract final class ReclamoRules {
  static const tipoReintegro = 'Reintegro';

  static bool estadoPermiteReclamo(String estado) {
    final normalized = estado.toLowerCase();
    return normalized == 'confirmado' || normalized == 'entregado';
  }

  static bool puedeReclamar({
    required String estado,
    required bool tieneReclamo,
  }) {
    return estadoPermiteReclamo(estado) && !tieneReclamo;
  }

  static String? validarMontoReintegro({
    required String rawMonto,
    required double totalPedido,
  }) {
    final normalized = rawMonto.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return 'Debe indicar un monto de reintegro válido.';
    }
    final monto = double.tryParse(normalized);
    if (monto == null || monto <= 0) {
      return 'Debe indicar un monto de reintegro válido.';
    }
    if (monto > totalPedido) {
      return 'El monto de reintegro no puede superar el total del pedido.';
    }
    return null;
  }

  static String? validarCompensacionAlternativa(String descripcion) {
    if (descripcion.trim().length < 3) {
      return 'Debe describir la compensación alternativa solicitada.';
    }
    return null;
  }
}
