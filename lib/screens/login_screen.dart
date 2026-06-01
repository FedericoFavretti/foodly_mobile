import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import '../widgets/password_field.dart';
import '../widgets/wavy_accent.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      onLogoTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (_) => false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bienvenido a Foodly',
            textAlign: TextAlign.center,
            style: FoodlyTheme.serifTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia sesión y pedí en segundos',
            textAlign: TextAlign.center,
            style: FoodlyTheme.serifSection,
          ),
          const SizedBox(height: 24),
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Correo electrónico',
            ),
          ),
          const SizedBox(height: 16),
          const PasswordField(label: 'Contraseña'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: FoodlyTheme.sansBold.copyWith(
                  color: FoodlyColors.amarillo,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FoodlyButton(
            label: 'INGRESAR',
            onPressed: () {},
          ),
          const SizedBox(height: 32),
          const WavyAccent(),
          const SizedBox(height: 32),
          Text(
            '¿No estás registrado?',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 22,
              color: FoodlyColors.celeste,
            ),
          ),
          const SizedBox(height: 12),
          FoodlyButton(
            label: 'REGISTRARSE',
            variant: FoodlyButtonVariant.outline,
            onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
          ),
        ],
      ),
    );
  }
}
