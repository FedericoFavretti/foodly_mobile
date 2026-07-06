import '../../data/models/pedido_response_model.dart';

enum PedidoSortOption { fechaReciente, precioMayor, localAz }

class PedidoSort {
  static List<PedidoResponseModel> apply(
    List<PedidoResponseModel> pedidos,
    PedidoSortOption sort, {
    bool activosPrimero = false,
  }) {
    final result = List<PedidoResponseModel>.from(pedidos);

    if (sort == PedidoSortOption.fechaReciente) {
      result.sort(
        (a, b) => _compareFechaReciente(a, b, activosPrimero: activosPrimero),
      );
    } else if (sort == PedidoSortOption.precioMayor) {
      result.sort(
        (a, b) => _compareActivosPrimero(a, b, activosPrimero) ??
            _comparePrecioMayor(a, b),
      );
    } else if (sort == PedidoSortOption.localAz) {
      result.sort(
        (a, b) => _compareActivosPrimero(a, b, activosPrimero) ??
            _compareLocalAz(a, b),
      );
    }

    return result;
  }

  static int _compareFechaReciente(
    PedidoResponseModel a,
    PedidoResponseModel b, {
    required bool activosPrimero,
  }) {
    final activos = _compareActivosPrimero(a, b, activosPrimero);
    if (activos != null) return activos;

    final fa = a.fecha;
    final fb = b.fecha;
    if (fa == null && fb == null) return b.id.compareTo(a.id);
    if (fa == null) return -1;
    if (fb == null) return 1;
    final cmp = fb.compareTo(fa);
    return cmp != 0 ? cmp : b.id.compareTo(a.id);
  }

  static int _comparePrecioMayor(PedidoResponseModel a, PedidoResponseModel b) {
    final cmp = b.total.compareTo(a.total);
    return cmp != 0 ? cmp : b.id.compareTo(a.id);
  }

  static int _compareLocalAz(PedidoResponseModel a, PedidoResponseModel b) {
    final cmp = a.localNombre.toLowerCase().compareTo(
          b.localNombre.toLowerCase(),
        );
    return cmp != 0 ? cmp : b.id.compareTo(a.id);
  }

  static int? _compareActivosPrimero(
    PedidoResponseModel a,
    PedidoResponseModel b,
    bool activosPrimero,
  ) {
    if (!activosPrimero || a.esActivo == b.esActivo) return null;
    return a.esActivo ? -1 : 1;
  }
}
