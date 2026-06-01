import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import '../widgets/password_field.dart';
import '../widgets/google_icon.dart';
import '../widgets/wavy_accent.dart';

const _passwordHint = [
  'Un largo mínimo de 8 caracteres',
  'Al menos 1 letra mayúscula',
  'Al menos 1 número',
  'Al menos 1 carácter especial (ej. _ @ !)',
];

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

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
            'Registrate en Foodly',
            textAlign: TextAlign.center,
            style: FoodlyTheme.serifTitle,
          ),
          const SizedBox(height: 20),
          FoodlyButton(
            label: 'CONTINUAR CON GOOGLE',
            variant: FoodlyButtonVariant.outline,
            leading: const GoogleIcon(),
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: SizedBox(height: 12, child: WavyAccent()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18,
                    color: FoodlyColors.grisOscuro,
                  ),
                ),
              ),
              const Expanded(
                child: SizedBox(height: 12, child: WavyAccent()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ingresa tus datos para registrarte',
            textAlign: TextAlign.center,
            style: FoodlyTheme.serifSection,
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(hintText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(hintText: 'Apellido'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Domicilio (calle, número)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Correo electrónico',
            ),
          ),
          const SizedBox(height: 12),
          const PasswordField(
            label: 'Contraseña',
            hint: _passwordHint,
          ),
          const SizedBox(height: 12),
          const PasswordField(label: 'Confirmar contraseña'),
          const SizedBox(height: 24),
          FoodlyButton(
            label: 'REGISTRARSE',
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: '¿Ya tenés cuenta? ',
              style: GoogleFonts.nunito(
                color: FoodlyColors.grisIntermedio,
                fontSize: 15,
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    ),
                    child: Text(
                      'Iniciá sesión',
                      style: FoodlyTheme.sansBold.copyWith(
                        color: FoodlyColors.celeste,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
