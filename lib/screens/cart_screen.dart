import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/cart/cart_notifier.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tu pedido',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 22),
        ),
        backgroundColor: FoodlyColors.blanco,
        foregroundColor: FoodlyColors.grisOscuro,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: CartNotifier.instance,
        builder: (context, _) {
          final cart = CartNotifier.instance;

          if (cart.isEmpty) {
            return Center(
              child: Text(
                'Debe agregar al menos un plato para realizar el pedido.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      cart.localNombre ?? 'Local',
                      style: FoodlyTheme.sansBlack.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ...cart.items.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.plato.nombre,
                                      style: FoodlyTheme.sansBlack.copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${item.plato.precio.toStringAsFixed(0)} c/u',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: FoodlyColors.grisIntermedio,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => cart.updateQuantity(
                                  item.plato.id,
                                  item.cantidad - 1,
                                ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${item.cantidad}',
                                style: FoodlyTheme.sansBold.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                onPressed: () => cart.updateQuantity(
                                  item.plato.id,
                                  item.cantidad + 1,
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FoodlyColors.blanco,
                  boxShadow: [
                    BoxShadow(
                      color: FoodlyColors.negro.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total estimado',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            color: FoodlyColors.grisIntermedio,
                          ),
                        ),
                        Text(
                          '\$${cart.estimatedTotal.toStringAsFixed(0)}',
                          style: FoodlyTheme.sansBlack.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FoodlyButton(
                      label: 'CONTINUAR',
                      onPressed: () {
                        Navigator.pushNamed(context, CheckoutScreen.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
