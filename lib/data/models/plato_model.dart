class PlatoModel {
  const PlatoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenes,
    required this.disponible,
    required this.localId,
    this.precioOriginal,
    this.tienePromocion = false,
    this.descuentoPercent,
    this.promocionId,
    this.promocionTitulo,
    this.categoriaId,
    this.categoriaNombre,
  });

  final int id;
  final String nombre;
  final String descripcion;

  /// Precio efectivo que paga el cliente (con descuento si hay promo).
  final double precio;
  final List<String> imagenes;
  final bool disponible;
  final int localId;
  final double? precioOriginal;
  final bool tienePromocion;
  final int? descuentoPercent;
  final int? promocionId;
  final String? promocionTitulo;
  final int? categoriaId;
  final String? categoriaNombre;

  /// Alias explícito para UI y carrito.
  double get precioFinal => precio;

  String? get imagenPrincipal =>
      imagenes.isNotEmpty ? imagenes.first : null;

  PlatoModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precio,
    List<String>? imagenes,
    bool? disponible,
    int? localId,
    double? precioOriginal,
    bool? tienePromocion,
    int? descuentoPercent,
    int? promocionId,
    String? promocionTitulo,
    int? categoriaId,
    String? categoriaNombre,
  }) {
    return PlatoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      imagenes: imagenes ?? this.imagenes,
      disponible: disponible ?? this.disponible,
      localId: localId ?? this.localId,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      tienePromocion: tienePromocion ?? this.tienePromocion,
      descuentoPercent: descuentoPercent ?? this.descuentoPercent,
      promocionId: promocionId ?? this.promocionId,
      promocionTitulo: promocionTitulo ?? this.promocionTitulo,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
    );
  }

  factory PlatoModel.fromJson(Map<String, dynamic> json) {
    final id = readInt(json['id']);
    if (id == null) {
      throw FormatException('Plato sin id válido: $json');
    }

    // El backend manda `imagen` (singular) para platos; `imagenes` (plural)
    // es exclusivo de Local. Se tolera `imagenes` como fallback legado.
    final imagenSingular = (json['imagen'] as String?)?.trim();
    final imagenesRaw = json['imagenes'];
    final imagenesFallback = imagenesRaw is List
        ? imagenesRaw.map((e) => e.toString()).toList()
        : <String>[];
    final imagenes = imagenSingular != null && imagenSingular.isNotEmpty
        ? [imagenSingular]
        : imagenesFallback;

    final categoriaJson = json['dtCategoria'] ?? json['categoria'];
    int? categoriaId;
    String? categoriaNombre;
    if (categoriaJson is Map<String, dynamic>) {
      categoriaId = readInt(categoriaJson['id']);
      categoriaNombre = categoriaJson['nombre'] as String?;
    }

    final localJson = json['local'] ?? json['dtLocal'];
    var localId = readInt(json['localId']) ?? 0;
    if (localJson is Map<String, dynamic>) {
      localId = readInt(localJson['id']) ?? localId;
    }

    final precioBase = readDouble(json['precio']) ?? 0;
    final precioFinalJson = readDouble(json['precioFinal']);
    final tienePromo = json['tienePromocion'] == true;
    final precioEfectivo = precioFinalJson ?? precioBase;

    var descuentoPercent = readInt(json['descuentoPercent']);
    if (descuentoPercent == null &&
        tienePromo &&
        precioBase > 0 &&
        precioEfectivo < precioBase) {
      descuentoPercent =
          ((1 - precioEfectivo / precioBase) * 100).round();
    }

    return PlatoModel(
      id: id,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precio: precioEfectivo,
      imagenes: imagenes,
      disponible: _parseDisponible(json['disponible']),
      localId: localId,
      precioOriginal: tienePromo ? precioBase : null,
      tienePromocion: tienePromo,
      descuentoPercent: descuentoPercent,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
    );
  }

  /// Parseo tolerante para listas del backend; retorna null si el ítem es inválido.
  static PlatoModel? tryFromJson(
    Map<String, dynamic> json, {
    int? fallbackLocalId,
  }) {
    try {
      final plato = PlatoModel.fromJson(json);
      if (plato.localId == 0 && fallbackLocalId != null) {
        return plato.copyWith(localId: fallbackLocalId);
      }
      return plato;
    } catch (_) {
      return null;
    }
  }

  static int? readInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// Backend envía boolean; tolera null, 0/1 o strings por compatibilidad.
  static bool _parseDisponible(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return true;
  }
}
