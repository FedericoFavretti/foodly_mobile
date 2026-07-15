/// Reglas de negocio para reclamos (CU-CL09).
abstract final class ReclamoRules {
  static const tipoReintegro = 'Reintegro';
  static const tipoAlternativa = 'Otra';

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
}
