import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import '../core/errors/api_exception.dart';

import '../core/validators/form_validators.dart';

import '../data/repositories/account_repository.dart';

import '../theme/foodly_colors.dart';

import '../theme/foodly_theme.dart';

import '../widgets/foodly_button.dart';

import '../widgets/password_field.dart';



const _passwordHint = [

  'Un largo mínimo de 8 caracteres',

  'Al menos 1 letra mayúscula',

  'Al menos 1 número',

];



class ChangePasswordScreen extends StatefulWidget {

  const ChangePasswordScreen({super.key});



  static const routeName = '/cambiar-contrasena';



  @override

  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();

}



class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  final _accountRepository = AccountRepository();

  final _currentPasswordController = TextEditingController();

  final _codeController = TextEditingController();

  final _newPasswordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();



  int _step = 1;

  bool _isLoading = false;

  String? _successMessage;



  @override

  void dispose() {

    _currentPasswordController.dispose();

    _codeController.dispose();

    _newPasswordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();

  }



  Future<void> _handleStep1() async {

    final password = _currentPasswordController.text;

    if (password.isEmpty) {

      _showMessage('Ingresá tu contraseña actual.');

      return;

    }



    setState(() {

      _isLoading = true;

      _successMessage = null;

    });



    try {

      await _accountRepository.iniciarCambioPasswd(password);

      if (!mounted) return;

      setState(() {

        _step = 2;

        _successMessage = AccountRepository.passwordChangeCodeSentMessage;

      });

    } on ApiException catch (error) {

      _showMessage(error.userMessage);

    } on NetworkException catch (error) {

      _showMessage(error.userMessage);

    } finally {

      if (mounted) setState(() => _isLoading = false);

    }

  }



  Future<void> _handleStep2() async {

    final code = _codeController.text.trim();

    if (code.length != 6) {

      _showMessage('El código debe tener 6 dígitos.');

      return;

    }



    setState(() {

      _isLoading = true;

      _successMessage = null;

    });



    try {

      await _accountRepository.verificarCodigoCambioPasswd(code);

      if (!mounted) return;

      setState(() {

        _step = 3;

        _successMessage = AccountRepository.passwordChangeCodeVerifiedMessage;

      });

    } on ApiException catch (error) {

      _showMessage(error.userMessage);

    } on NetworkException catch (error) {

      _showMessage(error.userMessage);

    } finally {

      if (mounted) setState(() => _isLoading = false);

    }

  }



  Future<void> _handleStep3() async {

    final newPassword = _newPasswordController.text;

    final confirm = _confirmPasswordController.text;



    final passwordError = FormValidators.password(newPassword);

    if (passwordError != null) {

      _showMessage(passwordError);

      return;

    }



    final confirmError = FormValidators.confirmPassword(newPassword, confirm);

    if (confirmError != null) {

      _showMessage(confirmError);

      return;

    }



    setState(() {

      _isLoading = true;

      _successMessage = null;

    });



    try {

      await _accountRepository.confirmarCambioPasswd(

        passwdNueva: newPassword,

        passwdConfirmacion: confirm,

      );

      if (!mounted) return;

      Navigator.pop(

        context,

        AccountRepository.passwordChangeSuccessMessage,

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

    return Scaffold(

      backgroundColor: FoodlyColors.blanco,

      appBar: AppBar(

        backgroundColor: FoodlyColors.celeste,

        foregroundColor: FoodlyColors.blanco,

        title: Text(

          'Cambiar contraseña',

          style: FoodlyTheme.sansBlack.copyWith(fontSize: 18),

        ),

      ),

      body: ListView(

        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),

        children: [

          _StepIndicator(currentStep: _step),

          const SizedBox(height: 24),

          if (_successMessage != null) ...[

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

                _successMessage!,

                style: GoogleFonts.nunito(

                  fontSize: 14,

                  color: FoodlyColors.grisOscuro,

                  height: 1.4,

                ),

              ),

            ),

            const SizedBox(height: 24),

          ],

          if (_step == 1) ...[

            Text(

              'Ingresá tu contraseña actual para recibir un código de verificación por correo.',

              style: GoogleFonts.nunito(

                fontSize: 14,

                color: FoodlyColors.grisIntermedio,

                height: 1.4,

              ),

            ),

            const SizedBox(height: 20),

            PasswordField(

              label: 'Contraseña actual',

              controller: _currentPasswordController,

            ),

            const SizedBox(height: 24),

            if (_isLoading)

              const Center(child: CircularProgressIndicator())

            else

              FoodlyButton(

                label: 'SOLICITAR CÓDIGO',

                onPressed: _handleStep1,

              ),

          ],

          if (_step == 2) ...[

            TextFormField(

              controller: _codeController,

              enabled: !_isLoading,

              keyboardType: TextInputType.number,

              maxLength: 6,

              decoration: const InputDecoration(

                hintText: 'Código de verificación (6 dígitos)',

                counterText: '',

              ),

            ),

            const SizedBox(height: 24),

            if (_isLoading)

              const Center(child: CircularProgressIndicator())

            else

              FoodlyButton(

                label: 'VERIFICAR CÓDIGO',

                onPressed: _handleStep2,

              ),

          ],

          if (_step == 3) ...[

            PasswordField(

              label: 'Nueva contraseña',

              controller: _newPasswordController,

              hint: _passwordHint,

            ),

            const SizedBox(height: 16),

            PasswordField(

              label: 'Confirmar contraseña',

              controller: _confirmPasswordController,

              validator: (value) => FormValidators.confirmPassword(

                _newPasswordController.text,

                value,

              ),

            ),

            const SizedBox(height: 24),

            if (_isLoading)

              const Center(child: CircularProgressIndicator())

            else

              FoodlyButton(

                label: 'ACTUALIZAR CONTRASEÑA',

                onPressed: _handleStep3,

              ),

          ],

        ],

      ),

    );

  }

}



class _StepIndicator extends StatelessWidget {

  const _StepIndicator({required this.currentStep});



  final int currentStep;



  @override

  Widget build(BuildContext context) {

    return Row(

      children: List.generate(3, (index) {

        final step = index + 1;

        final isActive = step <= currentStep;

        return Expanded(

          child: Row(

            children: [

              Expanded(

                child: Container(

                  height: 4,

                  decoration: BoxDecoration(

                    color: isActive

                        ? FoodlyColors.celeste

                        : FoodlyColors.grisClaro,

                    borderRadius: BorderRadius.circular(2),

                  ),

                ),

              ),

              if (index < 2) const SizedBox(width: 6),

            ],

          ),

        );

      }),

    );

  }

}


