/// Datos del formulario de reclamo (CU-CL09).
class ReclamoFormData {
  const ReclamoFormData({
    required this.motivo,
    required this.tipoCompensacion,
    this.montoReintegro,
  });

  final String motivo;
  final String tipoCompensacion;
  final double? montoReintegro;
}

enum TipoCompensacionSolicitada { reintegro, alternativa }
