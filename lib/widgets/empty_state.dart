import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/foodly_colors.dart';

/// Estado vacío reutilizable con icono, título, subtítulo y acción opcional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: iconColor ?? FoodlyColors.grisClaro,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: FoodlyColors.grisOscuro,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FoodlyColors.celeste,
                  side: const BorderSide(color: FoodlyColors.celeste),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error genérico con botón "Reintentar".
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      iconColor: const Color(0xFFD32F2F).withValues(alpha: 0.4),
      title: 'Algo salió mal',
      subtitle: message,
      actionLabel: onRetry != null ? 'Reintentar' : null,
      onAction: onRetry,
    );
  }
}
