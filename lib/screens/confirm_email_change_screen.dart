import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import 'login_screen.dart';

enum _ConfirmStatus { idle, loading, success, error }

class ConfirmEmailChangeScreen extends StatefulWidget {
  const ConfirmEmailChangeScreen({super.key, this.token = ''});

  static const routeName = '/confirmar-cambio-correo';

  final String token;

  @override
  State<ConfirmEmailChangeScreen> createState() =>
      _ConfirmEmailChangeScreenState();
}

class _ConfirmEmailChangeScreenState extends State<ConfirmEmailChangeScreen> {
  final _tokenController = TextEditingController();
  final _accountRepository = AccountRepository();
  final _authRepository = AuthRepository();
  _ConfirmStatus _status = _ConfirmStatus.idle;
  String? _message;

  bool get _hasInitialToken => widget.token.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasInitialToken) {
      _tokenController.text = widget.token.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _status = _ConfirmStatus.error;
        _message = 'El enlace de confirmación no es válido.';
      });
      return;
    }

    setState(() {
      _status = _ConfirmStatus.loading;
      _message = null;
    });

    try {
      await _accountRepository.confirmarCambioCorreo(token);
      await _authRepository.logout();
      if (!mounted) return;
      setState(() {
        _status = _ConfirmStatus.success;
        _message = AccountRepository.emailChangeSuccessMessage;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ConfirmStatus.error;
        _message = error.userMessage;
      });
    } on NetworkException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ConfirmStatus.error;
        _message = error.userMessage;
      });
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (_) => false,
      arguments: _status == _ConfirmStatus.success
          ? AccountRepository.emailChangeSuccessMessage
          : null,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirmar cambio de correo',
            textAlign: TextAlign.center,
            style: FoodlyTheme.serifTitle,
          ),
          const SizedBox(height: 24),
          if (_status == _ConfirmStatus.loading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              'Confirmando el cambio de correo...',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15),
            ),
          ] else if (_status == _ConfirmStatus.success) ...[
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: FoodlyColors.celeste,
            ),
            const SizedBox(height: 16),
            Text(
              _message ?? AccountRepository.emailChangeSuccessMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            FoodlyButton(
              label: 'IR A INICIAR SESIÓN',
              onPressed: _goToLogin,
            ),
          ] else ...[
            if (_status == _ConfirmStatus.error && _message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: const Color(0xFFD32F2F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!_hasInitialToken) ...[
              Text(
                'Pegá el token del enlace que recibiste por correo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Token de confirmación',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
            ],
            FoodlyButton(
              label: 'CONFIRMAR CAMBIO',
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToLogin,
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ],
      ),
    );
  }
}
