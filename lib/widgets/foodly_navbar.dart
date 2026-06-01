import 'package:flutter/material.dart';

import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class FoodlyNavbar extends StatelessWidget {
  const FoodlyNavbar({super.key, this.onLoginTap});

  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FoodlyColors.celeste,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu, color: FoodlyColors.blanco),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                'Foodly',
                textAlign: TextAlign.center,
                style: FoodlyTheme.sansBlack.copyWith(
                  fontSize: 28,
                  color: FoodlyColors.blanco,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            TextButton(
              onPressed: onLoginTap,
              style: TextButton.styleFrom(
                backgroundColor: FoodlyColors.blanco,
                foregroundColor: FoodlyColors.celeste,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'INGRESAR',
                style: FoodlyTheme.sansBold.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: FoodlyColors.celeste,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
