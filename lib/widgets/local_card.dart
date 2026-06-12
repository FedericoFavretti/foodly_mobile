import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/local_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class LocalCard extends StatelessWidget {
  const LocalCard({
    super.key,
    required this.local,
    required this.onTap,
  });

  final LocalModel local;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FoodlyColors.blanco,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LocalImage(url: local.imagenPrincipal),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          local.nombre,
                          style: FoodlyTheme.sansBlack.copyWith(
                            fontSize: 14,
                            color: FoodlyColors.grisOscuro,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _EstadoChip(abierto: local.estaAbierto),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    local.descripcion,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      height: 1.35,
                      color: FoodlyColors.grisIntermedio,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: FoodlyColors.amarillo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        local.calificacionGlobal.toStringAsFixed(1),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FoodlyColors.grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalImage extends StatelessWidget {
  const _LocalImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        color: FoodlyColors.grisClaro,
        child: const Icon(
          Icons.storefront_outlined,
          size: 40,
          color: FoodlyColors.celeste,
        ),
      );
    }

    return Image.network(
      url!,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 120,
        color: FoodlyColors.grisClaro,
        child: const Icon(Icons.broken_image_outlined),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 120,
          color: FoodlyColors.grisClaro,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.abierto});

  final bool abierto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: abierto
            ? FoodlyColors.grisClaro
            : FoodlyColors.grisIntermedio.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        abierto ? 'Abierto' : 'Cerrado',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: abierto ? FoodlyColors.celeste : FoodlyColors.grisIntermedio,
        ),
      ),
    );
  }
}
