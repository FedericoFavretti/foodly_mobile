import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/food_items.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              item.imagePath,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: FoodlyTheme.sansBlack.copyWith(
              fontSize: 14,
              color: FoodlyColors.grisOscuro,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: GoogleFonts.nunito(
              fontSize: 13,
              height: 1.4,
              color: FoodlyColors.grisIntermedio,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
