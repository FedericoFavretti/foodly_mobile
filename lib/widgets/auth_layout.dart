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
    // viewInsets.bottom contiene la altura del teclado cuando está abierto.
    // Con resizeToAvoidBottomInset: false evitamos que el Scaffold cambie el
    // tamaño del body y en cambio sumamos el espacio del teclado al padding
    // inferior del scroll, lo que garantiza que el botón/campo enfocado no
    // quede tapado.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + keyboardHeight),
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
                  'assets/images/auth-delivery-panel.png',
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
