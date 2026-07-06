import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/mi_calificacion_local_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class LocalRatingCard extends StatelessWidget {
  const LocalRatingCard({
    super.key,
    required this.miCalificacion,
    required this.onCalificar,
    this.isLoading = false,
  });

  final MiCalificacionLocalModel? miCalificacion;
  final VoidCallback onCalificar;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tieneCalificacion = miCalificacion != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FoodlyColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FoodlyColors.grisClaro),
        boxShadow: [
          BoxShadow(
            color: FoodlyColors.grisOscuro.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_outline, color: FoodlyColors.amarillo),
              const SizedBox(width: 8),
              Text(
                'Tu calificación',
                style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (tieneCalificacion) ...[
            Row(
              children: [
                _StarRow(puntaje: miCalificacion!.puntaje),
                const SizedBox(width: 8),
                Text(
                  '${miCalificacion!.puntaje}/5',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: FoodlyColors.grisOscuro,
                  ),
                ),
              ],
            ),
            if (miCalificacion!.comentario?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                miCalificacion!.comentario!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: FoodlyColors.grisIntermedio,
                  height: 1.4,
                ),
              ),
            ],
          ] else
            Text(
              'Todavía no calificaste este local.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: FoodlyColors.grisIntermedio,
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isLoading ? null : onCalificar,
              icon: Icon(
                tieneCalificacion ? Icons.edit_outlined : Icons.star_rate_outlined,
                size: 18,
              ),
              label: Text(tieneCalificacion ? 'Editar' : 'Calificar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.puntaje});

  final int puntaje;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < puntaje;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: FoodlyColors.amarillo,
          size: 20,
        );
      }),
    );
  }
}
