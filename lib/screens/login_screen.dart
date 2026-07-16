import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/auth/biometric_service.dart';
import '../core/auth/google_sign_in_service.dart';
import '../core/auth/post_login_helper.dart';
import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/session/session_manager.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import '../widgets/google_icon.dart';
import '../widgets/password_field.dart';
import '../widgets/wavy_accent.dart';
import 'activate_account_screen.dart';
import 'biometric_lock_screen.dart';
import 'forgot_password_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.successMessage,
    this.googleSignInService,
    this.authRepository,
    this.biometricService,
  });

  static const routeName = '/login';

  final String? successMessage;
  final GoogleSignInService? googleSignInService;
  final AuthRepository? authRepository;
  final BiometricService? biometricService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthRepository _authRepository =
      widget.authRepository ?? AuthRepository();
  late final BiometricService _biometricService =
      widget.biometricService ?? LocalAuthBiometricService();
  late final GoogleSignInService _googleSignInService =
      widget.googleSignInService ?? PlatformGoogleSignInService();
  bool _isLoading = false;
  bool _showBiometricButton = false;

  bool get _googleConfigured => _googleSignInService.isConfigured;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = widget.successMessage;
      if (message != null && message.isNotEmpty) {
        _showMessage(message);
      }
    });
  }

  /// Muestra el acceso rápido por huella si el usuario lo activó y hay algo
  /// con lo que la huella pueda entrar: una sesión activa para desbloquear,
  /// o una credencial guardada con la que reautenticar de verdad (este
  /// backend no tiene refresh token).
  Future<void> _checkBiometricAvailability() async {
    final enabled = await SessionManager.getBiometricEnabled();
    if (enabled != true) return;

    final hasSession = await SessionManager.hasSession();
    final hasCredential =
        hasSession || await SessionManager.getBiometricCredential() != null;
    if (!hasCredential) return;

    final available = await _biometricService.isAvailable();
    if (!mounted) return;
    setState(() => _showBiometricButton = available);
  }

  void _openBiometricLock() {
    Navigator.pushReplacementNamed(context, BiometricLockScreen.routeName);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      await _authRepository.login(email: email, password: password);
      if (!mounted) return;
      await offerBiometricIfNeeded(context, _biometricService);
      if (!mounted) return;
      // Este backend no tiene refresh token: para que la huella pueda
      // iniciar sesión de verdad (no solo desbloquear un JWT que ya
      // existe), guardamos la contraseña cifrada junto al JWT cada vez
      // que hay un login exitoso con biometría activa.
      if (await SessionManager.getBiometricEnabled() == true) {
        await SessionManager.saveBiometricCredential(
          email: email.trim(),
          password: password,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
    } on ApiException catch (error) {
      _showLoginError(error);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (!_googleConfigured) {
      _showMessage(
        'Google Sign-In no está configurado. Definí GOOGLE_SERVER_CLIENT_ID al compilar.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tokens = await _googleSignInService.signIn();
      if (tokens == null) return;

      await _authRepository.loginWithGoogle(accessToken: tokens.accessToken);
      if (!mounted) return;
      await offerBiometricIfNeeded(context, _biometricService);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } catch (_) {
      _showMessage('No se pudo autenticar con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLoginError(ApiException error) {
    if (!mounted) return;
    if (error.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.userMessage),
          action: SnackBarAction(
            label: 'Activar',
            onPressed: () => Navigator.pushNamed(
              context,
              ActivateAccountScreen.routeName,
              arguments: _emailController.text.trim(),
            ),
          ),
        ),
      );
      return;
    }
    _showMessage(error.userMessage);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      onLogoTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
      child: Form(
        key: _formKey,
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
            FoodlyButton(
              label: 'CONTINUAR CON GOOGLE',
              variant: FoodlyButtonVariant.outline,
              leading: const GoogleIcon(),
              onPressed: _isLoading || !_googleConfigured
                  ? null
                  : _loginWithGoogle,
            ),
            if (!_googleConfigured) ...[
              const SizedBox(height: 8),
              Text(
                'Requiere GOOGLE_SERVER_CLIENT_ID (--dart-define)',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: SizedBox(height: 12, child: WavyAccent())),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o'),
                ),
                Expanded(child: SizedBox(height: 12, child: WavyAccent())),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Correo electrónico'),
              validator: FormValidators.email,
            ),
            const SizedBox(height: 16),
            PasswordField(label: 'Contraseña', controller: _passwordController),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        ForgotPasswordScreen.routeName,
                      ),
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              FoodlyButton(label: 'INGRESAR', onPressed: _submit),
            if (_showBiometricButton && !_isLoading) ...[
              const SizedBox(height: 12),
              _BiometricButton(onTap: _openBiometricLock),
            ],
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
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushReplacementNamed(context, '/register'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.fingerprint, size: 22),
      label: const Text('Usar huella / Face ID'),
      style: OutlinedButton.styleFrom(
        foregroundColor: FoodlyColors.celeste,
        side: const BorderSide(color: FoodlyColors.celeste),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
