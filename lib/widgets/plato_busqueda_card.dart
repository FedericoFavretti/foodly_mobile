import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/catalog/plato_busqueda_item.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class PlatoBusquedaCard extends StatelessWidget {
  const PlatoBusquedaCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final PlatoBusquedaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plato = item.plato;

    return Material(
      color: FoodlyColors.blanco,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: FoodlyColors.grisClaro),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  _PlatoImage(url: plato.imagenPrincipal),
                  if (plato.tienePromocion && plato.descuentoPercent != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FoodlyColors.amarillo,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${plato.descuentoPercent}%',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plato.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FoodlyTheme.sansBlack.copyWith(
                        fontSize: 15,
                        color: FoodlyColors.grisOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 14,
                          color: FoodlyColors.grisIntermedio,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.localNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: FoodlyColors.grisIntermedio,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (plato.tienePromocion &&
                            plato.precioOriginal != null) ...[
                          Text(
                            '\$${plato.precioOriginal!.toStringAsFixed(0)}',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: FoodlyColors.grisIntermedio,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '\$${plato.precioFinal.toStringAsFixed(0)}',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: plato.tienePromocion
                                ? const Color(0xFFE65100)
                                : FoodlyColors.celeste,
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
      ),
    );
  }
}

class _PlatoImage extends StatelessWidget {
  const _PlatoImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        height: 120,
        color: FoodlyColors.grisClaro,
        child: const Icon(
          Icons.restaurant_menu,
          color: FoodlyColors.grisIntermedio,
          size: 36,
        ),
      );
    }

    return Image.network(
      url!,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 120,
        color: FoodlyColors.grisClaro,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
