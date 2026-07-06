import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/calificacion_detalle_model.dart';
import '../data/models/calificacion_global_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class ClientRatingSummaryCard extends StatelessWidget {
  const ClientRatingSummaryCard({
    super.key,
    required this.global,
    required this.detalle,
  });

  final CalificacionGlobalModel global;
  final List<CalificacionDetalleModel> detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(Icons.emoji_events_outlined, color: FoodlyColors.amarillo),
              const SizedBox(width: 8),
              Text(
                'Tu reputación',
                style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                global.promedio.toStringAsFixed(1),
                style: FoodlyTheme.serifSection.copyWith(
                  fontSize: 36,
                  color: FoodlyColors.celeste,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Icon(Icons.star, color: FoodlyColors.amarillo, size: 22),
              ),
              const Spacer(),
              Text(
                '${global.totalCalificaciones} '
                '${global.totalCalificaciones == 1 ? 'valoración' : 'valoraciones'}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final star = 5 - index;
            final count = global.detallePorPuntuacion[star] ?? 0;
            final fraction = global.totalCalificaciones == 0
                ? 0.0
                : count / global.totalCalificaciones;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    child: Text(
                      '$star',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.star, size: 14, color: FoodlyColors.amarillo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: FoodlyColors.grisClaro,
                        color: FoodlyColors.amarillo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.nunito(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (detalle.isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              'Comentarios de locales',
              style: FoodlyTheme.sansBlack.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            ...detalle.take(5).map(_DetalleTile.new),
            if (detalle.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${detalle.length - 5} más',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetalleTile extends StatelessWidget {
  const _DetalleTile(this.item);

  final CalificacionDetalleModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nombreLocal,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: FoodlyColors.amarillo),
                  const SizedBox(width: 2),
                  Text(
                    '${item.puntaje}',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.comentario?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.comentario!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: FoodlyColors.grisIntermedio,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder cuando el cliente aún no recibió calificaciones.
class ClientRatingEmptyCard extends StatelessWidget {
  const ClientRatingEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FoodlyColors.grisClaro.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FoodlyColors.grisClaro),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_outline,
            color: FoodlyColors.grisIntermedio.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aún no recibiste calificaciones de los locales.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: FoodlyColors.grisIntermedio,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
