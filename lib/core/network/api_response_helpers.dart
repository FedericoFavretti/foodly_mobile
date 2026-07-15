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
  /// (búsqueda de platos, historial de pedidos) cuando ningún resultado
  /// coincide con el filtro pedido. El mensaje siempre sigue el patrón
  /// "No se encontraron [algo] que coincidan/coincida con...", así que se
  /// detecta genéricamente en vez de por texto exacto de un solo endpoint.
  static bool isEmptyResultMessage(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('no se encontraron') &&
        (normalized.contains('coincid') || normalized.contains('búsqueda'));
  }
}
