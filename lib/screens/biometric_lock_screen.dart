import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/auth/biometric_service.dart';
import '../core/errors/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/session/session_manager.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import 'login_screen.dart';
import 'main_screen.dart';

/// Pantalla de desbloqueo mostrada al reabrir la app cuando el usuario
/// activó el acceso biométrico. Dispara la autenticación automáticamente
/// al entrar; si falla repetidas veces (o la biometría dejó de estar
/// disponible), solo queda la salida de "Usar contraseña", que fuerza un
/// login completo con email y contraseña.
///
/// Si al momento de mostrarse ya hay un JWT válido guardado, la huella solo
/// lo "desbloquea" (no hace ningún pedido de red). Si en cambio no hay
/// sesión activa (expiró, o la app se cerró hace rato) pero sí una
/// credencial guardada, la huella dispara un login real contra el backend
/// — este backend no tiene refresh token, así que es la única forma de que
/// la biometría funcione como reemplazo del login y no solo como acceso
/// rápido mientras la sesión sigue viva.
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({
    super.key,
    this.biometricService,
    this.authRepository,
  });

  static const routeName = '/biometric-lock';

  final BiometricService? biometricService;
  final AuthRepository? authRepository;

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  static const _maxIntentos = 3;

  late final BiometricService _biometricService =
      widget.biometricService ?? LocalAuthBiometricService();
  late final AuthRepository _authRepository =
      widget.authRepository ?? AuthRepository();

  int _intentos = 0;
  bool _autenticando = false;
  bool _soloContrasena = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autenticar());
  }

  Future<void> _autenticar() async {
    if (_autenticando || _soloContrasena) return;
    setState(() {
      _autenticando = true;
      _mensaje = null;
    });

    final result = await _biometricService.authenticate();
    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        await _onBiometricSuccess();
        return;
      case BiometricResult.failed:
        _intentos++;
        setState(() {
          _autenticando = false;
          if (_intentos >= _maxIntentos) {
            _soloContrasena = true;
            _mensaje = 'Demasiados intentos fallidos. Usá tu contraseña.';
          } else {
            _mensaje = 'No pudimos verificar tu identidad. Intentá de nuevo.';
          }
        });
      case BiometricResult.lockedOut:
        setState(() {
          _autenticando = false;
          _soloContrasena = true;
          _mensaje = 'Demasiados intentos. Usá tu contraseña.';
        });
      case BiometricResult.notEnrolled:
      case BiometricResult.unavailable:
        setState(() {
          _autenticando = false;
          _soloContrasena = true;
          _mensaje =
              'La biometría ya no está disponible en este dispositivo. '
              'Usá tu contraseña.';
        });
    }
  }

  /// La huella se validó. Si ya hay una sesión activa, alcanza con
  /// navegar. Si no (sesión expirada o la app estuvo cerrada un buen
  /// rato), se reautentica con la credencial guardada para que la huella
  /// funcione como un login real.
  Future<void> _onBiometricSuccess() async {
    final hasSession = await SessionManager.hasSession();
    if (!mounted) return;
    if (hasSession) {
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
      return;
    }

    final credential = await SessionManager.getBiometricCredential();
    if (!mounted) return;
    if (credential == null) {
      setState(() => _autenticando = false);
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      return;
    }

    try {
      await _authRepository.login(
        email: credential.email,
        password: credential.password,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
    } on ApiException catch (_) {
      // La contraseña guardada ya no sirve (la cambiaron, cuenta
      // eliminada, etc.) — no tiene sentido seguir intentándolo sola.
      await SessionManager.clearBiometricCredential();
      if (!mounted) return;
      setState(() {
        _autenticando = false;
        _soloContrasena = true;
        _mensaje = 'Tu acceso guardado ya no es válido. Usá tu contraseña.';
      });
    } on NetworkException catch (_) {
      if (!mounted) return;
      setState(() {
        _autenticando = false;
        _mensaje = 'Sin conexión. Intentá de nuevo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _autenticando = false;
        _soloContrasena = true;
        _mensaje = 'No pudimos iniciar sesión. Usá tu contraseña.';
      });
    }
  }

  Future<void> _usarContrasena() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Foodly',
                style: FoodlyTheme.sansBlack.copyWith(
                  fontSize: 28,
                  color: FoodlyColors.celeste,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: FoodlyColors.celeste.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 52,
                  color: FoodlyColors.celeste,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Desbloqueá Foodly',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 26,
                  color: FoodlyColors.grisOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirmá tu identidad con tu huella o Face ID para continuar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: FoodlyColors.grisIntermedio,
                  height: 1.4,
                ),
              ),
              if (_mensaje != null) ...[
                const SizedBox(height: 16),
                Text(
                  _mensaje!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD32F2F),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (_autenticando)
                const CircularProgressIndicator(color: FoodlyColors.celeste)
              else ...[
                if (!_soloContrasena) ...[
                  FoodlyButton(label: 'REINTENTAR', onPressed: _autenticar),
                  const SizedBox(height: 12),
                ],
                FoodlyButton(
                  label: 'USAR CONTRASEÑA',
                  variant: FoodlyButtonVariant.outline,
                  onPressed: _usarContrasena,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
