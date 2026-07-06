import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/repositories/account_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import 'confirm_email_change_screen.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({
    super.key,
    required this.currentEmail,
  });

  static const routeName = '/cambiar-correo';

  final String currentEmail;

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
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
      await _accountRepository.iniciarCambioCorreo(_emailController.text);
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
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      appBar: AppBar(
        backgroundColor: FoodlyColors.blanco,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Cambiar correo',
          style: FoodlyTheme.serifSection.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Por seguridad, te enviaremos un enlace de confirmación a tu correo actual.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  height: 1.4,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.currentEmail,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FoodlyColors.grisOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El correo no cambia hasta que confirmes desde ese enlace.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: FoodlyColors.grisIntermedio,
                ),
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
                    AccountRepository.emailChangeStartedMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    ConfirmEmailChangeScreen.routeName,
                  ),
                  child: const Text('Ya tengo el token del enlace'),
                ),
              ] else ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo correo electrónico',
                    hintText: 'nuevo@email.com',
                  ),
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 24),
                FoodlyButton(
                  label: 'ENVIAR ENLACE DE CONFIRMACIÓN',
                  onPressed: _isLoading ? null : _submit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
