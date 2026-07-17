import 'dart:convert';

/// Utilidades compartidas para interpretar respuestas del backend.
abstract final class ApiResponseHelpers {
  static String? mapErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    if (body.length < 300 && !body.contains('<html')) return body;
    return null;
  }

  /// El backend usa 400 en vez de 200-con-lista-vacía para varios listados
  /// (búsqueda de platos, historial de pedidos) cuando no hay resultados.
  /// Pero el mensaje exacto varía según el motivo:
  /// - Filtro sin coincidencias: "No se encontraron [algo] que
  ///   coincidan/coincida con...".
  /// - Cuenta que nunca hizo un pedido: "Aún no ha realizado ningún
  ///   pedido...".
  /// Se detectan ambos patrones genéricamente en vez de por texto exacto de
  /// un solo endpoint.
  static bool isEmptyResultMessage(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    final sinCoincidencias =
        normalized.contains('no se encontraron') &&
        (normalized.contains('coincid') || normalized.contains('búsqueda'));
    final sinPedidosAun = normalized.contains('no ha realizado ningún');
    return sinCoincidencias || sinPedidosAun;
  }
}
