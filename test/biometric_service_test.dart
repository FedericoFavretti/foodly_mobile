import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/auth/biometric_service.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';

/// Implementación stub de BiometricService para tests.
class _StubBiometricService implements BiometricService {
  _StubBiometricService({
    this.available = true,
    this.result = BiometricResult.success,
  });

  final bool available;
  final BiometricResult result;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate() async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  group('BiometricService (stub)', () {
    test('isAvailable devuelve true cuando el stub está configurado', () async {
      final service = _StubBiometricService(available: true);
      expect(await service.isAvailable(), isTrue);
    });

    test('isAvailable devuelve false cuando no hay biometría', () async {
      final service = _StubBiometricService(available: false);
      expect(await service.isAvailable(), isFalse);
    });

    test('authenticate retorna success en stub exitoso', () async {
      final service = _StubBiometricService(result: BiometricResult.success);
      expect(await service.authenticate(), BiometricResult.success);
    });

    test('authenticate retorna failed en stub fallido', () async {
      final service = _StubBiometricService(result: BiometricResult.failed);
      expect(await service.authenticate(), BiometricResult.failed);
    });

    test('authenticate retorna lockedOut cuando está bloqueado', () async {
      final service = _StubBiometricService(result: BiometricResult.lockedOut);
      expect(await service.authenticate(), BiometricResult.lockedOut);
    });

    test('authenticate retorna notEnrolled cuando no hay biometría registrada',
        () async {
      final service =
          _StubBiometricService(result: BiometricResult.notEnrolled);
      expect(await service.authenticate(), BiometricResult.notEnrolled);
    });
  });

  group('SessionManager — biometric preference', () {
    test('getBiometricEnabled devuelve null cuando nunca se configuró',
        () async {
      expect(await SessionManager.getBiometricEnabled(), isNull);
    });

    test('setBiometricEnabled(true) → getBiometricEnabled devuelve true',
        () async {
      await SessionManager.setBiometricEnabled(true);
      expect(await SessionManager.getBiometricEnabled(), isTrue);
    });

    test('setBiometricEnabled(false) → getBiometricEnabled devuelve false',
        () async {
      await SessionManager.setBiometricEnabled(false);
      expect(await SessionManager.getBiometricEnabled(), isFalse);
    });

    test('resetForTest limpia la preferencia biométrica', () async {
      await SessionManager.setBiometricEnabled(true);
      SessionManager.resetForTest();
      expect(await SessionManager.getBiometricEnabled(), isNull);
    });

    test('setBiometricEnabled no afecta el token de sesión', () async {
      await SessionManager.saveToken('fake.token.here');
      await SessionManager.setBiometricEnabled(true);
      expect(await SessionManager.getToken(), 'fake.token.here');
    });
  });

  group('BiometricResult enum', () {
    test('todos los valores del enum están definidos', () {
      expect(BiometricResult.values.length, 5);
      expect(BiometricResult.values, containsAll([
        BiometricResult.success,
        BiometricResult.failed,
        BiometricResult.unavailable,
        BiometricResult.notEnrolled,
        BiometricResult.lockedOut,
      ]));
    });
  });
}
