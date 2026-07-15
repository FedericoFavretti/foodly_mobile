import 'dart:async';

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
  bool _isResending = false;
  bool _activated = false;

  /// Segundos restantes de cooldown para el botón Reenviar.
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown({int seconds = 60}) {
    setState(() => _resendCooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _reenviar() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Ingresá tu correo para reenviar el email.');
      return;
    }

    setState(() => _isResending = true);
    try {
      await _accountRepository.reenviarActivacion(_emailController.text);
      if (!mounted) return;
      _showMessage('Te reenviamos el correo de activación. Revisá tu bandeja.');
      _startCooldown();
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
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
              const SizedBox(height: 16),
              // ── Reenviar correo ────────────────────────────────────────
              _ResendEmailButton(
                isLoading: _isResending,
                cooldownSeconds: _resendCooldown,
                onPressed: _isLoading || _isResending || _resendCooldown > 0
                    ? null
                    : _reenviar,
              ),
              const SizedBox(height: 16),
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

class _ResendEmailButton extends StatelessWidget {
  const _ResendEmailButton({
    required this.isLoading,
    required this.cooldownSeconds,
    required this.onPressed,
  });

  final bool isLoading;
  final int cooldownSeconds;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = cooldownSeconds > 0
        ? 'Reenviar correo (${cooldownSeconds}s)'
        : '¿No recibiste el correo? Reenviar';

    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Enviando…',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: FoodlyColors.grisIntermedio,
            ),
          ),
        ],
      );
    }

    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: onPressed != null
              ? FoodlyColors.amarillo
              : FoodlyColors.grisIntermedio,
        ),
      ),
    );
  }
}
