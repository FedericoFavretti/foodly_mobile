/// Filtros server-side para `POST /clientes/busqueda` (equivalente web `buildSearchFilter`).
enum PlatoSearchSort { none, nombre, precioAsc, precioDesc }

class BusquedaPlatosFilter {
  const BusquedaPlatosFilter({
    this.query = '',
    this.soloPromociones = false,
    this.sort = PlatoSearchSort.none,
    this.precioMaximo,
  });

  final String query;
  final bool soloPromociones;
  final PlatoSearchSort sort;
  final double? precioMaximo;

  Map<String, dynamic> toRequestBody() {
    final body = <String, dynamic>{};
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      body['nombre'] = normalizedQuery;
    }
    if (soloPromociones) {
      body['promocionActiva'] = true;
    }
    switch (sort) {
      case PlatoSearchSort.nombre:
        body['alfabetico'] = true;
      case PlatoSearchSort.precioAsc:
        body['precioMasBajo'] = true;
      case PlatoSearchSort.precioDesc:
        body['precioMasAlto'] = true;
      case PlatoSearchSort.none:
        break;
    }
    return body;
  }

  /// Construye los query params para `GET /clientes/busqueda`.
  Map<String, String> toQueryParams({int? localId}) {
    final params = <String, String>{};
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      params['nombre'] = normalizedQuery;
    }
    if (soloPromociones) {
      params['promocionActiva'] = 'true';
    }
    switch (sort) {
      case PlatoSearchSort.nombre:
        params['alfabetico'] = 'true';
      case PlatoSearchSort.precioAsc:
        params['precioMasBajo'] = 'true';
      case PlatoSearchSort.precioDesc:
        params['precioMasAlto'] = 'true';
      case PlatoSearchSort.none:
        break;
    }
    if (localId != null) {
      params['localId'] = localId.toString();
    }
    return params;
  }
}
