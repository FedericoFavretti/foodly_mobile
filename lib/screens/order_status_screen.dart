import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/pedido_response_model.dart';
import '../data/repositories/pedido_repository.dart';
import '../screens/main_screen.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import '../widgets/pedido_card.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.pedido});

  static const routeName = '/pedido-confirmado';

  final PedidoResponseModel pedido;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with WidgetsBindingObserver {
  late PedidoResponseModel _pedido;
  bool _abrioMercadoPago = false;
  bool _refrescando = false;
  final _repo = PedidoRepository();

  @override
  void initState() {
    super.initState();
    _pedido = widget.pedido;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando el usuario vuelve a la app después de haber abierto MP,
    // refrescamos el estado del pedido para ver si el pago fue aprobado.
    if (state == AppLifecycleState.resumed && _abrioMercadoPago) {
      _abrioMercadoPago = false;
      _refrescarPedido();
    }
  }

  Future<void> _refrescarPedido() async {
    if (_refrescando) return;
    setState(() => _refrescando = true);
    try {
      final actualizado = await _repo.obtenerPedido(_pedido.id);
      if (!mounted) return;
      setState(() => _pedido = actualizado);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo verificar el estado. Intentalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _refrescando = false);
    }
  }

  Future<void> _abrirMercadoPago() async {
    final uri = Uri.tryParse(_pedido.mpInitPoint!.trim());
    if (uri == null) return;
    _abrioMercadoPago = true;
    // inAppBrowserView (Custom Tabs / SFSafariViewController) mantiene el
    // checkout dentro de la tarea de la app: "salir" cierra la pestaña y
    // vuelve a Foodly. Con externalApplication se abría en el navegador
    // como una pestaña más, así que "salir" navegaba por su historial
    // (a veces cayendo en una pestaña vieja de login) en vez de volver acá.
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  bool get _pagado =>
      !_pedido.puedeCompletarPagoMercadoPago &&
      _pedido.requierePagoMercadoPago &&
      !_pedido.pagoPendiente;

  @override
  Widget build(BuildContext context) {
    final esMercadoPago = _pedido.requierePagoMercadoPago;
    final pagoCompletado = esMercadoPago && _pagado;

    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      (pagoCompletado
                              ? const Color(0xFF2E7D32)
                              : FoodlyColors.celeste)
                          .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pagoCompletado ? Icons.check_circle : Icons.receipt_long,
                  size: 44,
                  color: pagoCompletado
                      ? const Color(0xFF2E7D32)
                      : FoodlyColors.celeste,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                pagoCompletado ? '¡Pago confirmado!' : '¡Pedido registrado!',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 30,
                  color: FoodlyColors.grisOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pagoCompletado
                    ? 'Tu pago fue aprobado. El local ya recibió tu pedido.'
                    : esMercadoPago
                    ? 'Completá el pago en Mercado Pago para que el local reciba tu pedido.'
                    : 'Pagás en efectivo al recibir el pedido.',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  height: 1.4,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 24),
              PedidoCard(pedido: _pedido),
              if (_refrescando) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verificando pago…',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: FoodlyColors.grisIntermedio,
                      ),
                    ),
                  ],
                ),
              ],
              if (_pedido.puedeCompletarPagoMercadoPago && !_refrescando) ...[
                const SizedBox(height: 16),
                FoodlyButton(
                  label: 'ABRIR MERCADO PAGO',
                  onPressed: _abrirMercadoPago,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _refrescarPedido,
                  child: Text(
                    'Ya pagué — verificar estado',
                    style: FoodlyTheme.sansBold.copyWith(
                      color: FoodlyColors.celeste,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              // MP requerido pero sin init point disponible (ej: pago enviado, esperando confirmación)
              if (esMercadoPago &&
                  !_pedido.puedeCompletarPagoMercadoPago &&
                  !_pagado &&
                  !_refrescando) ...[
                const SizedBox(height: 16),
                Text(
                  'Tu pago está siendo procesado por Mercado Pago.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _refrescarPedido,
                  child: Text(
                    'Actualizar estado',
                    style: FoodlyTheme.sansBold.copyWith(
                      color: FoodlyColors.celeste,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FoodlyButton(
                label: 'VER MIS PEDIDOS',
                variant: FoodlyButtonVariant.outline,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    MainScreen.routeName,
                    (route) => route.isFirst,
                    arguments: 1,
                  );
                },
              ),
              const SizedBox(height: 12),
              FoodlyButton(
                label: 'SEGUIR COMPRANDO',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    MainScreen.routeName,
                    (route) => route.isFirst,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
