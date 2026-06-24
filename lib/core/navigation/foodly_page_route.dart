import 'package:flutter/material.dart';

/// Transición de página con fade + slide sutil hacia arriba.
class FoodlyPageRoute<T> extends PageRouteBuilder<T> {
  FoodlyPageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: _buildTransition,
        );

  final Widget page;

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0, 0.04);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );
    final fadeTween = Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}
