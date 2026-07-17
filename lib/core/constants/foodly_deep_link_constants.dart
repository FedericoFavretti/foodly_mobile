/// Host del frontend web — Android intercepta estos links HTTPS y los
/// abre en la app en lugar del navegador (Android App Links).
/// Override: `--dart-define=WEB_LINK_HOST=...`
abstract final class FoodlyWebLinkConstants {
  static const host = String.fromEnvironment(
    'WEB_LINK_HOST',
    defaultValue: 'frontend-proyecto-foodly-test.up.railway.app',
  );

  static const pathConfirmarCambioCorreo = '/confirmar-cambio-correo';
  static const pathRestablecerContrasena = '/restablecer-contrasena';
  static const pathActivarCuenta = '/activar-cuenta';
}

sealed class FoodlyWebLinkAction {}

final class WebLinkConfirmarCambioCorreo extends FoodlyWebLinkAction {
  WebLinkConfirmarCambioCorreo(this.token);
  final String token;
}

final class WebLinkRestablecerContrasena extends FoodlyWebLinkAction {
  WebLinkRestablecerContrasena(this.token);
  final String token;
}

final class WebLinkActivarCuenta extends FoodlyWebLinkAction {
  WebLinkActivarCuenta(this.token);
  final String token;
}

abstract final class FoodlyWebLinkParser {
  static FoodlyWebLinkAction? parse(Uri uri) {
    if (uri.scheme != 'https') return null;
    if (uri.host != FoodlyWebLinkConstants.host) return null;

    final token = uri.queryParameters['token'] ?? '';

    switch (uri.path) {
      case FoodlyWebLinkConstants.pathConfirmarCambioCorreo:
        return WebLinkConfirmarCambioCorreo(token);
      case FoodlyWebLinkConstants.pathRestablecerContrasena:
        return WebLinkRestablecerContrasena(token);
      case FoodlyWebLinkConstants.pathActivarCuenta:
        return WebLinkActivarCuenta(token);
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
