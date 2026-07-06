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

  bool get _canAddItem => canAdd && plato.disponible && onAdd != null;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: plato.disponible ? 1 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: FoodlyColors.blanco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: FoodlyColors.grisOscuro.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _PlatoImage(url: plato.imagenPrincipal),
                if (plato.tienePromocion && plato.descuentoPercent != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _StatusBadge(
                      label: '-${plato.descuentoPercent}%',
                      background: FoodlyColors.amarillo,
                      foreground: FoodlyColors.grisOscuro,
                    ),
                  ),
                if (!plato.disponible)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StatusBadge(
                      label: 'No disponible',
                      background: FoodlyColors.grisOscuro.withValues(alpha: 0.8),
                      foreground: FoodlyColors.blanco,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plato.nombre,
                    style: FoodlyTheme.sansBlack.copyWith(
                      fontSize: 17,
                      color: FoodlyColors.grisOscuro,
                    ),
                  ),
                  if (plato.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      plato.descripcion,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        height: 1.4,
                        color: FoodlyColors.grisIntermedio,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (plato.tienePromocion &&
                          plato.precioOriginal != null) ...[
                        Text(
                          '\$${plato.precioOriginal!.toStringAsFixed(0)}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FoodlyColors.grisIntermedio,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: FoodlyColors.grisIntermedio,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '\$${plato.precioFinal.toStringAsFixed(0)}',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: plato.tienePromocion
                              ? const Color(0xFFE65100)
                              : FoodlyColors.celeste,
                        ),
                      ),
                      const Spacer(),
                      if (_canAddItem)
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: FoodlyColors.celeste,
                            foregroundColor: FoodlyColors.blanco,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                        )
                      else if (canAdd && !plato.disponible)
                        Text(
                          'Sin stock',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FoodlyColors.grisIntermedio,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _PlatoImage extends StatelessWidget {
  const _PlatoImage({this.url});

  final String? url;

  static const _height = 148.0;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _PlaceholderImage(height: _height);
    }

    return Image.network(
      url!,
      height: _height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _PlaceholderImage(height: _height),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _PlaceholderImage(
          height: _height,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: FoodlyColors.blanco,
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.height, this.child});

  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FoodlyColors.celesteOscuro, FoodlyColors.amarillo],
        ),
      ),
      child: Center(
        child: child ??
            Icon(
              Icons.restaurant_menu,
              size: height * 0.28,
              color: FoodlyColors.blanco.withValues(alpha: 0.9),
            ),
      ),
    );
  }
}
