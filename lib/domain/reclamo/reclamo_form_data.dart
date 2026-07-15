/// Datos del formulario de reclamo (CU-CL09).
class ReclamoFormData {
  const ReclamoFormData({
    required this.motivo,
    required this.tipoCompensacion,
  });

  final String motivo;
  final String tipoCompensacion;
}

enum TipoCompensacionSolicitada { reintegro, alternativa }
