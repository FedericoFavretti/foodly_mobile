/// Filtros server-side para `POST /clientes/busqueda` (equivalente web `buildSearchFilter`).
enum PlatoSearchSort { none, nombreAsc, nombreDesc, precioAsc, precioDesc }

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
      case PlatoSearchSort.nombreAsc:
        body['alfabetico'] = true;
      case PlatoSearchSort.nombreDesc:
        // El backend no tiene un flag para Z-A: se ordena client-side en
        // CatalogGlobalSearch.fromResponse.
        break;
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
  ///
  /// No se manda `nombre`: el backend matchea por palabra completa
  /// (case-sensitive) en vez de "contiene", lo que rompe la búsqueda en
  /// vivo mientras el usuario escribe. En su lugar se pide la página más
  /// grande posible (`tamanio` máximo permitido) y el texto se filtra
  /// client-side en [CatalogGlobalSearch], igual que ya se hace para el
  /// menú de un local.
  Map<String, String> toQueryParams({int? localId}) {
    final params = <String, String>{'tamanio': '100'};
    if (soloPromociones) {
      params['promocionActiva'] = 'true';
    }
    switch (sort) {
      case PlatoSearchSort.nombreAsc:
        params['alfabetico'] = 'true';
      case PlatoSearchSort.nombreDesc:
        break;
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
