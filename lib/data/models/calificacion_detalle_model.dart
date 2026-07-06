/// Calificación individual que un local dejó sobre el cliente.
class CalificacionDetalleModel {
  const CalificacionDetalleModel({
    required this.idLocal,
    required this.nombreLocal,
    required this.puntaje,
    this.comentario,
    this.fecha,
  });

  final int idLocal;
  final String nombreLocal;
  final int puntaje;
  final String? comentario;
  final String? fecha;

  factory CalificacionDetalleModel.fromJson(Map<String, dynamic> json) {
    return CalificacionDetalleModel(
      idLocal: (json['idLocal'] as num).toInt(),
      nombreLocal: json['nombreLocal'] as String? ?? '',
      puntaje: (json['puntaje'] as num).toInt(),
      comentario: json['comentario'] as String?,
      fecha: json['fecha']?.toString(),
    );
  }
}
