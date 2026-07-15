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

  static String? validarCompensacionAlternativa(String descripcion) {
    if (descripcion.trim().length < 3) {
      return 'Debe describir la compensación alternativa solicitada.';
    }
    return null;
  }
}
