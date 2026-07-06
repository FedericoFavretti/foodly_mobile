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

class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key, this.initialEmail = ''});

  static const routeName = '/activar-cuenta';

  final String initialEmail;

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _accountRepository = AccountRepository();
  bool _isLoading = false;
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _activated = false;
    });

    try {
      await _accountRepository.activarCuenta(_emailController.text);
      if (!mounted) return;
      setState(() => _activated = true);
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

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (_) => false,
      arguments: AccountRepository.accountActivatedMessage,
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
              'Activar cuenta',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifTitle,
            ),
            const SizedBox(height: 8),
            Text(
              _activated
                  ? 'Tu cuenta ya está activa.'
                  : 'Confirmá el correo de tu cuenta para poder iniciar sesión.',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifSection.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_activated) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  AccountRepository.accountActivatedMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: FoodlyColors.grisOscuro,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FoodlyButton(
                label: 'IR AL LOGIN',
                onPressed: _goToLogin,
              ),
            ] else ...[
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
                  label: 'ACTIVAR CUENTA',
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
          ],
        ),
      ),
    );
  }
}
