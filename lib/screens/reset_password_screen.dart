import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/repositories/account_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import '../widgets/password_field.dart';
import 'login_screen.dart';

const _passwordHint = [
  'Un largo mínimo de 8 caracteres',
  'Al menos 1 letra mayúscula',
  'Al menos 1 número',
];

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token = ''});

  static const routeName = '/restablecer-contrasena';

  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _accountRepository = AccountRepository();
  bool _isLoading = false;

  bool get _hasValidToken => widget.token.trim().isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_hasValidToken) {
      _showMessage('El enlace de recuperación no es válido.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _accountRepository.restablecerContra(
        token: widget.token,
        nuevaPasswd: _passwordController.text,
        confirmacionPasswd: _confirmPasswordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (_) => false,
        arguments: AccountRepository.passwordResetSuccessMessage,
      );
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      onLogoTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (_) => false,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva contraseña',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresá y confirmá tu nueva contraseña.',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifSection.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (!_hasValidToken)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'El enlace de recuperación no es válido. Solicitá uno nuevo desde el login.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: FoodlyColors.grisOscuro,
                  ),
                ),
              ),
            if (!_hasValidToken) const SizedBox(height: 16),
            PasswordField(
              label: 'Nueva contraseña',
              controller: _passwordController,
              hint: _passwordHint,
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Confirmar contraseña',
              controller: _confirmPasswordController,
              validator: (value) => FormValidators.confirmPassword(
                _passwordController.text,
                value,
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              FoodlyButton(
                label: 'RESTABLECER',
                onPressed: _hasValidToken ? _submit : null,
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushReplacementNamed(
                        context,
                        LoginScreen.routeName,
                      ),
              child: Text(
                'Volver al inicio de sesión',
                style: FoodlyTheme.sansBold.copyWith(
                  color: FoodlyColors.celeste,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
