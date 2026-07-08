/// Esquema custom para retorno post-Mercado Pago (C3).
///
/// Configurar en Railway/backend:
/// `MP_SUCCESS_URL=foodly://payment/success`
/// `MP_FAILURE_URL=foodly://payment/failure`
/// `MP_PENDING_URL=foodly://payment/pending`
abstract final class FoodlyDeepLinkConstants {
  static const scheme = 'foodly';
  static const paymentHost = 'payment';

  static const successSegment = 'success';
  static const failureSegment = 'failure';
  static const pendingSegment = 'pending';

  static Uri successUri({int? pedidoId}) => _build(successSegment, pedidoId);
  static Uri failureUri({int? pedidoId}) => _build(failureSegment, pedidoId);
  static Uri pendingUri({int? pedidoId}) => _build(pendingSegment, pedidoId);

  static Uri _build(String status, int? pedidoId) {
    return Uri(
      scheme: scheme,
      host: paymentHost,
      path: '/$status',
      queryParameters:
          pedidoId != null ? {'pedidoId': '$pedidoId'} : null,
    );
  }
}

enum MercadoPagoReturnStatus { success, failure, pending }

class FoodlyDeepLinkAction {
  const FoodlyDeepLinkAction({
    required this.status,
    this.pedidoId,
  });

  final MercadoPagoReturnStatus status;
  final int? pedidoId;
}

/// Parser puro para tests y handler de deep links.
abstract final class FoodlyDeepLinkParser {
  static FoodlyDeepLinkAction? parse(Uri uri) {
    if (uri.scheme != FoodlyDeepLinkConstants.scheme) return null;
    if (uri.host != FoodlyDeepLinkConstants.paymentHost) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final MercadoPagoReturnStatus? status;
    switch (segments.first) {
      case FoodlyDeepLinkConstants.successSegment:
        status = MercadoPagoReturnStatus.success;
      case FoodlyDeepLinkConstants.failureSegment:
        status = MercadoPagoReturnStatus.failure;
      case FoodlyDeepLinkConstants.pendingSegment:
        status = MercadoPagoReturnStatus.pending;
      default:
        return null;
    }

    final pedidoRaw = uri.queryParameters['pedidoId'];
    final pedidoId = pedidoRaw != null ? int.tryParse(pedidoRaw) : null;

    return FoodlyDeepLinkAction(status: status, pedidoId: pedidoId);
  }
}
