import 'package:flutter/material.dart';

import '../domain/cart/cart_notifier.dart';
import '../screens/cart_screen.dart';
import '../theme/foodly_colors.dart';

class CartFab extends StatelessWidget {
  const CartFab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartNotifier.instance,
      builder: (context, _) {
        final cart = CartNotifier.instance;
        if (cart.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, CartScreen.routeName);
          },
          backgroundColor: FoodlyColors.amarillo,
          foregroundColor: FoodlyColors.grisOscuro,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: Text('Carrito (${cart.totalItems})'),
        );
      },
    );
  }
}
