import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/pedido_response_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import 'main_screen.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key, required this.pedido});

  static const routeName = '/pedido-confirmado';

  final PedidoResponseModel pedido;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pedido confirmado',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 22),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: FoodlyColors.blanco,
        foregroundColor: FoodlyColors.grisOscuro,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FoodlyColors.grisClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Pedido registrado!',
                    style: FoodlyTheme.serifTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nº ${pedido.id} · ${pedido.localNombre}',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: FoodlyColors.grisIntermedio,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${pedido.estado}',
                    style: FoodlyTheme.sansBold.copyWith(
                      fontSize: 15,
                      color: FoodlyColors.celeste,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: \$${pedido.total.toStringAsFixed(0)}',
                    style: FoodlyTheme.sansBlack.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Detalle',
              style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...pedido.detalles.map(
              (detalle) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${detalle.cantidad}x ${detalle.platoNombre}',
                        style: GoogleFonts.nunito(fontSize: 14),
                      ),
                    ),
                    Text(
                      '\$${detalle.subtotal.toStringAsFixed(0)}',
                      style: FoodlyTheme.sansBold.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FoodlyButton(
              label: 'VOLVER A LOCALES',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  MainScreen.routeName,
                  (route) => route.isFirst,
                );
              },
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}
