import '../../data/models/local_model.dart';
import '../../data/models/plato_model.dart';

enum LocalSortOption { nombre, calificacion }

enum PlatoSortOption { nombre, precio }

class CatalogFilter {
  static List<LocalModel> filterLocales({
    required List<LocalModel> locales,
    String query = '',
    bool soloAbiertos = false,
    LocalSortOption sort = LocalSortOption.nombre,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    var result = locales.where((local) {
      if (soloAbiertos && !local.estaAbierto) return false;
      if (normalizedQuery.isEmpty) return true;
      return local.nombre.toLowerCase().contains(normalizedQuery) ||
          local.descripcion.toLowerCase().contains(normalizedQuery);
    }).toList();

    switch (sort) {
      case LocalSortOption.nombre:
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
      case LocalSortOption.calificacion:
        result.sort((a, b) => b.calificacionGlobal.compareTo(a.calificacionGlobal));
    }
    return result;
  }

  static List<PlatoModel> filterPlatos({
    required List<PlatoModel> platos,
    required int localId,
    String query = '',
    PlatoSortOption sort = PlatoSortOption.nombre,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    var result = platos.where((plato) {
      if (plato.localId != localId) return false;
      if (normalizedQuery.isEmpty) return true;
      return plato.nombre.toLowerCase().contains(normalizedQuery) ||
          plato.descripcion.toLowerCase().contains(normalizedQuery);
    }).toList();

    switch (sort) {
      case PlatoSortOption.nombre:
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
      case PlatoSortOption.precio:
        result.sort((a, b) => a.precio.compareTo(b.precio));
    }
    return result;
  }
}
