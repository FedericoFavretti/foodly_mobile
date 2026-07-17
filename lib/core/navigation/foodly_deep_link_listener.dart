import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../constants/foodly_deep_link_constants.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/cart/cart_storage.dart';
import '../../screens/confirm_email_change_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/reset_password_screen.dart';

/// Escucha deep links:
/// - `foodly://payment/*`  → retorno de Mercado Pago (navega a tab Pedidos).
/// - `https://<frontend>/*` → links de email interceptados via Android App Links:
///     /confirmar-cambio-correo?token= → ConfirmEmailChangeScreen
///     /restablecer-contrasena?token=  → ResetPasswordScreen
///     /activar-cuenta?token=          → activa la cuenta directamente y va a Login
class FoodlyDeepLinkListener extends StatefulWidget {
  const FoodlyDeepLinkListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<FoodlyDeepLinkListener> createState() => _FoodlyDeepLinkListenerState();
}

class _FoodlyDeepLinkListenerState extends State<FoodlyDeepLinkListener> {
  final _appLinks = AppLinks();
  final _storage = CartStorage();
  final _accountRepository = AccountRepository();
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(initial));
    }
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleUri(Uri uri) async {
    // Deep link de Mercado Pago (foodly://payment/...)
    final mpAction = FoodlyDeepLinkParser.parse(uri);
    if (mpAction != null) {
      await _handleMercadoPago(mpAction);
      return;
    }

    // App Link del frontend (https://frontend/ruta?token=...)
    final webAction = FoodlyWebLinkParser.parse(uri);
    if (webAction != null) {
      await _handleWebLink(webAction);
    }
  }

  Future<void> _handleMercadoPago(FoodlyDeepLinkAction action) async {
    await _storage.clearPendingMpPedidoId();

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil(
      MainScreen.routeName,
      (route) => route.isFirst,
      arguments: 1,
    );

    final context = widget.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final message = switch (action.status) {
      MercadoPagoReturnStatus.success =>
        'Pago registrado. Revisá el estado de tu pedido.',
      MercadoPagoReturnStatus.failure =>
        'El pago no se completó. Podés reintentarlo desde tus pedidos.',
      MercadoPagoReturnStatus.pending =>
        'Tu pago está pendiente de confirmación.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleWebLink(FoodlyWebLinkAction action) async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;

    switch (action) {
      case WebLinkConfirmarCambioCorreo(:final token):
        navigator.pushNamed(
          ConfirmEmailChangeScreen.routeName,
          arguments: token,
        );

      case WebLinkRestablecerContrasena(:final token):
        navigator.pushNamed(
          ResetPasswordScreen.routeName,
          arguments: token,
        );

      case WebLinkActivarCuenta(:final token):
        await _activarCuenta(token);
    }
  }

  Future<void> _activarCuenta(String token) async {
    final navigator = widget.navigatorKey.currentState;
    final context = widget.navigatorKey.currentContext;
    if (navigator == null || context == null || !context.mounted) return;

    try {
      await _accountRepository.activarCuentaConToken(token);
      if (!context.mounted) return;
      navigator.pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (_) => false,
        arguments: '¡Cuenta activada! Ya podés iniciar sesión.',
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El enlace de activación no es válido o ya fue usado. '
            'Iniciá sesión o registrate de nuevo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
