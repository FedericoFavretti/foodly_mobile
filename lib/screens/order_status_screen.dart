import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/pedido_response_model.dart';
import '../screens/main_screen.dart';
import '../theme/foodly_colors.dart';
import '../widgets/foodly_button.dart';
import '../widgets/pedido_card.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key, required this.pedido});

  static const routeName = '/pedido-confirmado';

  final PedidoResponseModel pedido;

  @override
  Widget build(BuildContext context) {
    final esMercadoPago = pedido.requierePagoMercadoPago;

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
                  color: FoodlyColors.celeste.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 44,
                  color: FoodlyColors.celeste,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Pedido registrado!',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 30,
                  color: FoodlyColors.grisOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                esMercadoPago
                    ? 'Completá el pago en Mercado Pago para que el local reciba tu pedido.'
                    : 'Pagás en efectivo al recibir el pedido.',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  height: 1.4,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 24),
              PedidoCard(pedido: pedido),
              if (pedido.puedeCompletarPagoMercadoPago) ...[
                const SizedBox(height: 16),
                FoodlyButton(
                  label: 'ABRIR MERCADO PAGO',
                  onPressed: () async {
                    final uri = Uri.tryParse(pedido.mpInitPoint!.trim());
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
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
