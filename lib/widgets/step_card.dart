import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/how_it_works_steps.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.step});

  final HowItWorksStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FoodlyColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: FoodlyColors.amarillo,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${step.step}',
              style: FoodlyTheme.sansBlack.copyWith(
                color: FoodlyColors.grisOscuro,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              step.imagePath,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.title,
            style: FoodlyTheme.sansBlack.copyWith(
              fontSize: 16,
              color: FoodlyColors.grisOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: GoogleFonts.nunito(
              fontSize: 13,
              height: 1.45,
              color: FoodlyColors.grisIntermedio,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
