import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/plato_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class PlatoCard extends StatelessWidget {
  const PlatoCard({
    super.key,
    required this.plato,
    this.onAdd,
    this.canAdd = false,
  });

  final PlatoModel plato;
  final VoidCallback? onAdd;
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    final opacity = plato.disponible ? 1.0 : 0.55;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FoodlyColors.blanco,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FoodlyColors.negro.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlatoImage(url: plato.imagenPrincipal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plato.nombre,
                    style: FoodlyTheme.sansBlack.copyWith(
                      fontSize: 15,
                      color: FoodlyColors.grisOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plato.descripcion,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      height: 1.35,
                      color: FoodlyColors.grisIntermedio,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${plato.precio.toStringAsFixed(0)}',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FoodlyColors.celeste,
                        ),
                      ),
                      if (!plato.disponible) ...[
                        const SizedBox(width: 8),
                        Text(
                          'No disponible',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FoodlyColors.grisIntermedio,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (canAdd && plato.disponible)
                        IconButton.filled(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: FoodlyColors.celeste,
                            foregroundColor: FoodlyColors.blanco,
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
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

class _PlatoImage extends StatelessWidget {
  const _PlatoImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;

    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          color: FoodlyColors.grisClaro,
          child: const Icon(
            Icons.restaurant_menu,
            color: FoodlyColors.amarillo,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: FoodlyColors.grisClaro,
          child: const Icon(Icons.broken_image_outlined),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: FoodlyColors.grisClaro,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
