import '../../data/models/pedido_response_model.dart';
import 'pedido_sort.dart';

/// Filtra y ordena pedidos para la pantalla de historial.
class PedidoListFilter {
  static List<PedidoResponseModel> apply({
    required List<PedidoResponseModel> all,
    String? filtroEstado,
    required PedidoSortOption sort,
  }) {
    Iterable<PedidoResponseModel> result = all;

    if (filtroEstado == 'Activos') {
      result = result.where((p) => p.esActivo);
    } else if (filtroEstado != null) {
      final objetivo = filtroEstado.toLowerCase();
      result = result.where(
        (p) => p.estadoNormalizado.toLowerCase() == objetivo,
      );
    }

    return PedidoSort.apply(
      result.toList(),
      sort,
      activosPrimero: filtroEstado == null,
    );
  }
}
