import 'direccion_model.dart';

class LocalModel {
  const LocalModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.calificacionGlobal,
    required this.estaAbierto,
    required this.imagenes,
    this.foto,
    this.direccion,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final double calificacionGlobal;
  final bool estaAbierto;
  final List<String> imagenes;
  final String? foto;
  final DireccionModel? direccion;

  /// Misma prioridad que el frontend web: `foto` (logo) y luego `imagenes[0]`.
  String? get imagenPrincipal {
    if (foto != null && foto!.trim().isNotEmpty) return foto;
    return imagenes.isNotEmpty ? imagenes.first : null;
  }

  factory LocalModel.fromJson(Map<String, dynamic> json) {
    final imagenesRaw = json['imagenes'];
    final imagenes = imagenesRaw is List
        ? imagenesRaw.map((e) => e.toString()).toList()
        : <String>[];

    final direccionJson = json['direccion'];
    return LocalModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      calificacionGlobal: (json['calificacionGlobal'] as num?)?.toDouble() ?? 0,
      estaAbierto: json['estaAbierto'] as bool? ?? false,
      imagenes: imagenes,
      foto: json['foto'] as String?,
      direccion: direccionJson is Map<String, dynamic>
          ? DireccionModel.fromJson(direccionJson)
          : null,
    );
  }
}
