import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/local_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

enum LocalCardVariant { list, featured }

class LocalCard extends StatelessWidget {
  const LocalCard({
    super.key,
    required this.local,
    required this.onTap,
    this.variant = LocalCardVariant.list,
  });

  final LocalModel local;
  final VoidCallback? onTap;
  final LocalCardVariant variant;

  bool get _isFeatured => variant == LocalCardVariant.featured;

  @override
  Widget build(BuildContext context) {
    final enabled = local.estaAbierto && onTap != null;
    final imageHeight = _isFeatured ? 120.0 : 168.0;

    final card = Container(
      width: _isFeatured ? 260 : null,
      decoration: BoxDecoration(
        color: FoodlyColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FoodlyColors.grisOscuro.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  _LocalImage(url: local.imagenPrincipal, height: imageHeight),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _EstadoBadge(abierto: local.estaAbierto),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _RatingBadge(rating: local.calificacionGlobal),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  _isFeatured ? 14 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.nombre,
                      style: FoodlyTheme.sansBlack.copyWith(
                        fontSize: _isFeatured ? 15 : 17,
                        color: FoodlyColors.grisOscuro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (local.direccion?.ciudad.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: FoodlyColors.grisIntermedio.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              local.direccion!.ciudad,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: FoodlyColors.grisIntermedio,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!_isFeatured) ...[
                      const SizedBox(height: 6),
                      Text(
                        local.descripcion,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          height: 1.35,
                          color: FoodlyColors.grisIntermedio,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isFeatured)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: enabled ? onTap : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: FoodlyColors.celeste,
                        disabledBackgroundColor:
                            FoodlyColors.grisClaro,
                        disabledForegroundColor: FoodlyColors.grisIntermedio,
                        foregroundColor: FoodlyColors.blanco,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Ver menú',
                        style: FoodlyTheme.sansBold.copyWith(
                          fontSize: 13,
                          color: enabled
                              ? FoodlyColors.blanco
                              : FoodlyColors.grisIntermedio,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: local.estaAbierto ? 1 : 0.55,
      child: card,
    );
  }
}

class _LocalImage extends StatelessWidget {
  const _LocalImage({this.url, required this.height});

  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _PlaceholderImage(height: height);
    }

    return Image.network(
      url!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _PlaceholderImage(height: height),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _PlaceholderImage(
          height: height,
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
          colors: [FoodlyColors.celeste, FoodlyColors.amarillo],
        ),
      ),
      child: Center(
        child: child ??
            Icon(
              Icons.storefront_outlined,
              size: height * 0.28,
              color: FoodlyColors.blanco.withValues(alpha: 0.9),
            ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.abierto});

  final bool abierto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: abierto
            ? FoodlyColors.blanco.withValues(alpha: 0.95)
            : FoodlyColors.grisOscuro.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        abierto ? 'Abierto' : 'Cerrado',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: abierto ? FoodlyColors.celeste : FoodlyColors.blanco,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: FoodlyColors.grisOscuro.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: FoodlyColors.amarillo),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: FoodlyColors.blanco,
            ),
          ),
        ],
      ),
    );
  }
}
