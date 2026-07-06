import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/foodly_colors.dart';

/// Chip de filtro sin las restricciones de layout de [FilterChip].
class FoodlyFilterChip extends StatelessWidget {
  const FoodlyFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheckmark = true,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheckmark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? FoodlyColors.celeste : FoodlyColors.grisIntermedio;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? FoodlyColors.celeste.withValues(alpha: 0.14)
                  : FoodlyColors.blanco,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? FoodlyColors.celeste : FoodlyColors.grisClaro,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCheckmark && selected) ...[
                  const Icon(Icons.check, size: 16, color: FoodlyColors.celeste),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: foreground,
                    fontSize: 13,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 2),
                  IconTheme(
                    data: IconThemeData(color: foreground, size: 18),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
