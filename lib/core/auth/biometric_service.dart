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
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotEnrolled':
        case 'NotAvailable':
          return BiometricResult.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricResult.lockedOut;
        default:
          return BiometricResult.unavailable;
      }
    } catch (_) {
      return BiometricResult.unavailable;
    }
  }
}
