import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/repositories/account_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/recuperar-contrasena';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _accountRepository = AccountRepository();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailSent = false;
    });

    try {
      await _accountRepository.solicitarRecuperacion(_emailController.text);
      if (!mounted) return;
      setState(() => _emailSent = true);
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
              'Recuperar contraseña',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresá tu correo y te enviaremos un enlace de recuperación.',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifSection.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_emailSent) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FoodlyColors.celeste.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: FoodlyColors.celeste.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  AccountRepository.recoveryEmailSentMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: FoodlyColors.grisOscuro,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Correo electrónico',
              ),
              validator: FormValidators.email,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              FoodlyButton(
                label: _emailSent ? 'REENVIAR ENLACE' : 'ENVIAR ENLACE',
                onPressed: _submit,
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
