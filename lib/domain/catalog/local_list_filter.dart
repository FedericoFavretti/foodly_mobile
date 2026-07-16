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

  /// Construye el body JSON enviado al backend (legado, no usar con GET).
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

  /// Construye los query params para `GET /clientes/listar_locales`.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    final search = nombre?.trim();
    if (search != null && search.isNotEmpty) {
      params['nombre'] = search;
    }
    if (soloAbiertos) {
      params['estaAbierto'] = 'true';
    }
    if (calificacionMinima != null) {
      params['calificacionMinima'] = calificacionMinima.toString();
    }
    if (ordenarPor != null && ordenarPor!.isNotEmpty) {
      params['ordenarPor'] = ordenarPor!;
      params['direccion'] = direccion ?? 'desc';
    }
    return params;
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
      case LocalSortOption.nombreAsc:
        ordenarPor = 'nombre';
        direccion = 'asc';
      case LocalSortOption.nombreDesc:
        ordenarPor = 'nombre';
        direccion = 'desc';
      case LocalSortOption.calificacionDesc:
        ordenarPor = 'calificacion';
        direccion = 'desc';
      case LocalSortOption.calificacionAsc:
        ordenarPor = 'calificacion';
        direccion = 'asc';
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
