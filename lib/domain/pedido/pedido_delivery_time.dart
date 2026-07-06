/// Parseo de `tiempoEstEntrega` del backend (equivalente web `parseDeliveryMinutes`).
abstract final class PedidoDeliveryTime {
  static int? parseMinutes(dynamic tiempoEstEntrega) {
    if (tiempoEstEntrega == null) return null;

    if (tiempoEstEntrega is num) {
      final value = tiempoEstEntrega.toDouble();
      return value >= 3600 ? (value / 60).round() : value.round();
    }

    if (tiempoEstEntrega is String) {
      final match = RegExp(
        r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?',
        caseSensitive: false,
      ).firstMatch(tiempoEstEntrega.trim());
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '') ?? 0;
        final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
        final seconds = double.tryParse(match.group(3) ?? '') ?? 0;
        return hours * 60 + minutes + (seconds / 60).round();
      }
    }

    if (tiempoEstEntrega is Map) {
      final seconds = tiempoEstEntrega['seconds'];
      if (seconds is num) return (seconds / 60).round();
    }

    return null;
  }
}
