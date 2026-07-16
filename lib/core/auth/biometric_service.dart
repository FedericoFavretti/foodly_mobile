import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Resultado de una autenticación biométrica.
enum BiometricResult { success, failed, unavailable, notEnrolled, lockedOut }

/// Abstrae `local_auth` para facilitar tests sin plugin nativo.
abstract class BiometricService {
  Future<bool> isAvailable();
  Future<BiometricResult> authenticate();
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricResult> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Confirmá tu identidad para ingresar a Foodly',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return mapAuthError(e.code);
    } catch (_) {
      return BiometricResult.unavailable;
    }
  }

  /// Mapea el `code` de un `PlatformException` de `local_auth` al resultado
  /// correspondiente. Función pura (sin el plugin nativo) para poder
  /// testear el mapeo directamente.
  static BiometricResult mapAuthError(String code) {
    switch (code) {
      case 'NotEnrolled':
        return BiometricResult.notEnrolled;
      case 'NotAvailable':
        return BiometricResult.unavailable;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return BiometricResult.lockedOut;
      default:
        return BiometricResult.unavailable;
    }
  }
}
