import '../../data/models/plato_model.dart';

/// Plato en resultados de búsqueda global con contexto del local.
class PlatoBusquedaItem {
  const PlatoBusquedaItem({
    required this.plato,
    required this.localNombre,
  });

  final PlatoModel plato;
  final String localNombre;

  int get localId => plato.localId;
}
