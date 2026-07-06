import '../../core/catalog/catalog_filter.dart';

/// Filtros server-side para `POST /clientes/listar_locales`.
/// Equivalente a `buildLocalListBody` en frontend-foodly.
class LocalListFilter {
  const LocalListFilter({
    this.nombre,
    this.soloAbiertos = false,
    this.calificacionMinima,
    this.ordenarPor,
    this.direccion,
  });

  final String? nombre;
  final bool soloAbiertos;
  final double? calificacionMinima;
  final String? ordenarPor;
  final String? direccion;

  /// Construye el body JSON enviado al backend.
  Map<String, dynamic> toRequestBody() {
    final body = <String, dynamic>{};
    final search = nombre?.trim();
    if (search != null && search.isNotEmpty) {
      body['nombre'] = search;
    }
    if (soloAbiertos) {
      body['estaAbierto'] = true;
    }
    if (calificacionMinima != null) {
      body['calificacionMinima'] = calificacionMinima;
    }
    if (ordenarPor != null && ordenarPor!.isNotEmpty) {
      body['ordenarPor'] = ordenarPor;
      body['direccion'] = direccion ?? 'desc';
    }
    return body;
  }

  /// Mapea el estado de la UI de [MainScreen] al filtro del API.
  factory LocalListFilter.fromUi({
    required String query,
    required bool soloAbiertos,
    required LocalSortOption sort,
  }) {
    String? ordenarPor;
    String? direccion;
    switch (sort) {
      case LocalSortOption.nombre:
        ordenarPor = 'nombre';
        direccion = 'asc';
      case LocalSortOption.calificacion:
        ordenarPor = 'calificacion';
        direccion = 'desc';
    }

    return LocalListFilter(
      nombre: query.trim().isEmpty ? null : query.trim(),
      soloAbiertos: soloAbiertos,
      ordenarPor: ordenarPor,
      direccion: direccion,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LocalListFilter &&
        other.nombre == nombre &&
        other.soloAbiertos == soloAbiertos &&
        other.calificacionMinima == calificacionMinima &&
        other.ordenarPor == ordenarPor &&
        other.direccion == direccion;
  }

  @override
  int get hashCode => Object.hash(
        nombre,
        soloAbiertos,
        calificacionMinima,
        ordenarPor,
        direccion,
      );
}
