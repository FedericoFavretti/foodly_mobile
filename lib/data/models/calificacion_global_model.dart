/// Resumen de calificaciones recibidas por un cliente (CU-CL11).
class CalificacionGlobalModel {
  const CalificacionGlobalModel({
    required this.promedio,
    required this.totalCalificaciones,
    required this.detallePorPuntuacion,
  });

  final double promedio;
  final int totalCalificaciones;
  final Map<int, int> detallePorPuntuacion;

  factory CalificacionGlobalModel.fromJson(Map<String, dynamic> json) {
    final detalleRaw = json['detallePorPuntuacion'];
    final detalle = <int, int>{for (var i = 1; i <= 5; i++) i: 0};

    if (detalleRaw is Map) {
      detalleRaw.forEach((key, value) {
        final star = int.tryParse(key.toString());
        if (star != null && star >= 1 && star <= 5 && value is num) {
          detalle[star] = value.toInt();
        }
      });
    }

    return CalificacionGlobalModel(
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0,
      totalCalificaciones: (json['totalCalificaciones'] as num?)?.toInt() ?? 0,
      detallePorPuntuacion: detalle,
    );
  }
}
