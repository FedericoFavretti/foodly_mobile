import 'package:flutter/material.dart';

import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

enum FoodlyButtonVariant { primary, outline }

class FoodlyButton extends StatelessWidget {
  const FoodlyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FoodlyButtonVariant.primary,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final FoodlyButtonVariant variant;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == FoodlyButtonVariant.primary;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary ? FoodlyColors.celeste : FoodlyColors.blanco,
          foregroundColor: isPrimary ? FoodlyColors.blanco : FoodlyColors.celeste,
          side: isPrimary
              ? null
              : const BorderSide(color: FoodlyColors.celeste, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: FoodlyTheme.sansBold.copyWith(
                letterSpacing: 0.8,
                fontSize: 14,
                color: isPrimary ? FoodlyColors.blanco : FoodlyColors.celeste,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
