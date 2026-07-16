import '../../data/models/local_model.dart';
import '../../data/models/plato_model.dart';

enum LocalSortOption {
  nombreAsc,
  nombreDesc,
  calificacionDesc,
  calificacionAsc,
}

enum PlatoSortOption { nombreAsc, nombreDesc, precioAsc, precioDesc }

/// Categoría de plato derivada del menú de un local, para armar chips de filtro.
class PlatoCategoriaOption {
  const PlatoCategoriaOption({required this.id, required this.nombre});

  final int id;
  final String nombre;
}

class CatalogFilter {
  static List<LocalModel> filterLocales({
    required List<LocalModel> locales,
    String query = '',
    bool soloAbiertos = false,
    LocalSortOption sort = LocalSortOption.nombreAsc,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    var result = locales.where((local) {
      if (soloAbiertos && !local.estaAbierto) return false;
      if (normalizedQuery.isEmpty) return true;
      return local.nombre.toLowerCase().contains(normalizedQuery) ||
          local.descripcion.toLowerCase().contains(normalizedQuery);
    }).toList();

    switch (sort) {
      case LocalSortOption.nombreAsc:
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
      case LocalSortOption.nombreDesc:
        result.sort((a, b) => b.nombre.compareTo(a.nombre));
      case LocalSortOption.calificacionDesc:
        result.sort(
          (a, b) => b.calificacionGlobal.compareTo(a.calificacionGlobal),
        );
      case LocalSortOption.calificacionAsc:
        result.sort(
          (a, b) => a.calificacionGlobal.compareTo(b.calificacionGlobal),
        );
    }
    return result;
  }

  /// Locales abiertos mejor calificados para el carrusel de destacados.
  static List<LocalModel> destacados({
    required List<LocalModel> locales,
    int limit = 5,
  }) {
    final abiertos = locales.where((local) => local.estaAbierto).toList()
      ..sort((a, b) => b.calificacionGlobal.compareTo(a.calificacionGlobal));
    if (abiertos.length <= limit) return abiertos;
    return abiertos.sublist(0, limit);
  }

  static List<PlatoModel> filterPlatos({
    required List<PlatoModel> platos,
    required int localId,
    String query = '',
    PlatoSortOption sort = PlatoSortOption.nombreAsc,
    int? categoriaId,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    var result = platos.where((plato) {
      if (plato.localId != localId) return false;
      if (categoriaId != null && plato.categoriaId != categoriaId) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;
      return plato.nombre.toLowerCase().contains(normalizedQuery) ||
          plato.descripcion.toLowerCase().contains(normalizedQuery);
    }).toList();

    switch (sort) {
      case PlatoSortOption.nombreAsc:
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
      case PlatoSortOption.nombreDesc:
        result.sort((a, b) => b.nombre.compareTo(a.nombre));
      case PlatoSortOption.precioAsc:
        result.sort((a, b) => a.precio.compareTo(b.precio));
      case PlatoSortOption.precioDesc:
        result.sort((a, b) => b.precio.compareTo(a.precio));
    }
    return result;
  }

  /// Categorías presentes en una lista de platos, ordenadas alfabéticamente.
  static List<PlatoCategoriaOption> categoriasDe(List<PlatoModel> platos) {
    final porId = <int, String>{};
    for (final plato in platos) {
      final id = plato.categoriaId;
      final nombre = plato.categoriaNombre?.trim();
      if (id == null || nombre == null || nombre.isEmpty) continue;
      porId[id] = nombre;
    }
    final categorias =
        porId.entries
            .map(
              (entry) =>
                  PlatoCategoriaOption(id: entry.key, nombre: entry.value),
            )
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return categorias;
  }

  /// Categorías presentes en el menú de un local, ordenadas alfabéticamente.
  static List<PlatoCategoriaOption> categoriasDeLocal({
    required List<PlatoModel> platos,
    required int localId,
  }) {
    return categoriasDe(
      platos.where((plato) => plato.localId == localId).toList(),
    );
  }
}
