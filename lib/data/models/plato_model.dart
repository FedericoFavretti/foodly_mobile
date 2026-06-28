class PlatoModel {
  const PlatoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenes,
    required this.disponible,
    required this.localId,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final List<String> imagenes;
  final bool disponible;
  final int localId;

  String? get imagenPrincipal =>
      imagenes.isNotEmpty ? imagenes.first : null;

  factory PlatoModel.fromJson(Map<String, dynamic> json) {
    final imagenesRaw = json['imagenes'];
    final imagenes = imagenesRaw is List
        ? imagenesRaw.map((e) => e.toString()).toList()
        : <String>[];

    final localJson = json['local'] ?? json['dtLocal'];
    final localId = localJson is Map<String, dynamic>
        ? (localJson['id'] as num).toInt()
        : (json['localId'] as num?)?.toInt() ?? 0;

    return PlatoModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      imagenes: imagenes,
      disponible: json['disponible'] as bool? ?? true,
      localId: localId,
    );
  }
}
