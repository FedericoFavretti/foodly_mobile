import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../constants/foodly_deep_link_constants.dart';
import '../../domain/cart/cart_storage.dart';
import '../../screens/main_screen.dart';

/// Escucha `foodly://payment/*` y navega al tab Pedidos (C3).
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
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUri(initial);
      });
    }

    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleUri(Uri uri) async {
    final action = FoodlyDeepLinkParser.parse(uri);
    if (action == null) return;

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

  @override
  Widget build(BuildContext context) => widget.child;
}
