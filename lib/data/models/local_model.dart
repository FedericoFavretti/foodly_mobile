import 'direccion_model.dart';

class LocalModel {
  const LocalModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.calificacionGlobal,
    required this.estaAbierto,
    required this.imagenes,
    this.direccion,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final double calificacionGlobal;
  final bool estaAbierto;
  final List<String> imagenes;
  final DireccionModel? direccion;

  String? get imagenPrincipal =>
      imagenes.isNotEmpty ? imagenes.first : null;

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
      direccion: direccionJson is Map<String, dynamic>
          ? DireccionModel.fromJson(direccionJson)
          : null,
    );
  }
}
