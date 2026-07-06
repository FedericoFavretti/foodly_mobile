class MiCalificacionLocalModel {
  const MiCalificacionLocalModel({
    required this.id,
    required this.puntaje,
    this.comentario,
    this.fecha,
  });

  final int id;
  final int puntaje;
  final String? comentario;
  final String? fecha;

  factory MiCalificacionLocalModel.fromJson(Map<String, dynamic> json) {
    return MiCalificacionLocalModel(
      id: (json['id'] as num).toInt(),
      puntaje: (json['puntaje'] as num).toInt(),
      comentario: json['comentario'] as String?,
      fecha: json['fecha']?.toString(),
    );
  }
}
