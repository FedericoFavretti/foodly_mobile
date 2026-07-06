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

  static bool isEmptySearchResult(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('no se encontraron platos') ||
        normalized.contains('no se encontraron') && normalized.contains('búsqueda');
  }
}
