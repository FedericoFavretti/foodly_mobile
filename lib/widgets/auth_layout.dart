import 'package:flutter/material.dart';

import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.onLogoTap,
  });

  final Widget child;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onLogoTap,
                  child: Text(
                    'Foodly',
                    style: FoodlyTheme.sansBlack.copyWith(
                      fontSize: 28,
                      color: FoodlyColors.celeste,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/login-register.png',
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
