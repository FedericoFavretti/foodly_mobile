import '../../data/models/plato_model.dart';
import '../../data/models/promocion_model.dart';
import 'catalog_search_merge.dart';
import 'plato_busqueda_item.dart';

/// Parseo de respuesta global de `POST /clientes/busqueda`.
abstract final class CatalogGlobalSearch {
  static List<PlatoBusquedaItem> fromResponse(
    Map<String, dynamic> decoded, {
    String query = '',
    bool soloPromociones = false,
    double? precioMaximo,
  }) {
    final localNames = <int, String>{};
    final platos = _parsePlatosList(decoded['platos'], localNames);
    final promociones = _parsePromocionesList(decoded['promociones'], localNames);

    List<PlatoModel> merged;
    try {
      merged = promociones.isEmpty
          ? platos
          : CatalogSearchMerge.merge(platos: platos, promociones: promociones);
    } catch (_) {
      merged = platos;
    }

    var items = merged
        .map(
          (plato) => PlatoBusquedaItem(
            plato: plato,
            localNombre: localNames[plato.localId] ?? 'Local',
          ),
        )
        .toList();

    if (soloPromociones) {
      items = items.where((item) => item.plato.tienePromocion).toList();
    }

    if (precioMaximo != null) {
      items = items.where((item) => item.plato.precio <= precioMaximo).toList();
    }

    // El backend matchea `nombre` por palabra completa (case-sensitive), no
    // por substring, así que el texto se filtra acá para que la búsqueda en
    // vivo funcione con coincidencias parciales.
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.plato.nombre.toLowerCase().contains(normalizedQuery) ||
              item.plato.descripcion.toLowerCase().contains(normalizedQuery))
          .toList();
    }

    return items;
  }

  static List<PlatoModel> _parsePlatosList(
    dynamic platosRaw,
    Map<int, String> localNames,
  ) {
    if (platosRaw is! List) return [];
    final platos = <PlatoModel>[];
    for (final raw in platosRaw.whereType<Map<String, dynamic>>()) {
      _captureLocalName(raw, localNames);
      final plato = PlatoModel.tryFromJson(raw);
      if (plato != null) platos.add(plato);
    }
    return platos;
  }

  static List<PromocionModel> _parsePromocionesList(
    dynamic promocionesRaw,
    Map<int, String> localNames,
  ) {
    if (promocionesRaw is! List) return [];
    for (final raw in promocionesRaw.whereType<Map<String, dynamic>>()) {
      final platoJson = raw['dtPlato'] ?? raw['plato'];
      if (platoJson is Map<String, dynamic>) {
        _captureLocalName(platoJson, localNames);
      }
    }
    return promocionesRaw
        .whereType<Map<String, dynamic>>()
        .map(PromocionModel.tryFromJson)
        .whereType<PromocionModel>()
        .toList();
  }

  static void _captureLocalName(
    Map<String, dynamic> platoJson,
    Map<int, String> localNames,
  ) {
    final localJson = platoJson['local'] ?? platoJson['dtLocal'];
    if (localJson is! Map<String, dynamic>) return;
    final localId = PlatoModel.readInt(localJson['id']);
    final nombre = localJson['nombre'] as String?;
    if (localId != null && nombre != null && nombre.trim().isNotEmpty) {
      localNames[localId] = nombre.trim();
    }
  }
}
