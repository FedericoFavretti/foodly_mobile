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

    test(
      'authenticate retorna notEnrolled cuando no hay biometría registrada',
      () async {
        final service = _StubBiometricService(
          result: BiometricResult.notEnrolled,
        );
        expect(await service.authenticate(), BiometricResult.notEnrolled);
      },
    );
  });

  group('LocalAuthBiometricService.mapAuthError', () {
    test("'NotEnrolled' -> notEnrolled", () {
      expect(
        LocalAuthBiometricService.mapAuthError('NotEnrolled'),
        BiometricResult.notEnrolled,
      );
    });

    test("'NotAvailable' -> unavailable (no notEnrolled — regresión del bug "
        'que los confundía)', () {
      expect(
        LocalAuthBiometricService.mapAuthError('NotAvailable'),
        BiometricResult.unavailable,
      );
    });

    test("'LockedOut' y 'PermanentlyLockedOut' -> lockedOut", () {
      expect(
        LocalAuthBiometricService.mapAuthError('LockedOut'),
        BiometricResult.lockedOut,
      );
      expect(
        LocalAuthBiometricService.mapAuthError('PermanentlyLockedOut'),
        BiometricResult.lockedOut,
      );
    });

    test('código desconocido -> unavailable', () {
      expect(
        LocalAuthBiometricService.mapAuthError('AlgoRaro'),
        BiometricResult.unavailable,
      );
    });
  });

  group('SessionManager — biometric preference', () {
    test(
      'getBiometricEnabled devuelve null cuando nunca se configuró',
      () async {
        expect(await SessionManager.getBiometricEnabled(), isNull);
      },
    );

    test(
      'setBiometricEnabled(true) → getBiometricEnabled devuelve true',
      () async {
        await SessionManager.setBiometricEnabled(true);
        expect(await SessionManager.getBiometricEnabled(), isTrue);
      },
    );

    test(
      'setBiometricEnabled(false) → getBiometricEnabled devuelve false',
      () async {
        await SessionManager.setBiometricEnabled(false);
        expect(await SessionManager.getBiometricEnabled(), isFalse);
      },
    );

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

    test('clearSession (logout) no borra la preferencia biométrica: debe '
        'sobrevivir a un logout/re-login', () async {
      await SessionManager.saveToken('fake.token.here');
      await SessionManager.setBiometricEnabled(true);

      await SessionManager.clearSession();

      expect(await SessionManager.getToken(), isNull);
      expect(await SessionManager.getBiometricEnabled(), isTrue);
    });
  });

  group('SessionManager — credencial para login biométrico', () {
    test('getBiometricCredential devuelve null si nunca se guardó', () async {
      expect(await SessionManager.getBiometricCredential(), isNull);
    });

    test(
      'saveBiometricCredential → getBiometricCredential round-trip',
      () async {
        await SessionManager.saveBiometricCredential(
          email: 'cliente@test.com',
          password: 'F@odly2026',
        );

        final credential = await SessionManager.getBiometricCredential();
        expect(credential, isNotNull);
        expect(credential!.email, 'cliente@test.com');
        expect(credential.password, 'F@odly2026');
      },
    );

    test('clearBiometricCredential la borra', () async {
      await SessionManager.saveBiometricCredential(
        email: 'cliente@test.com',
        password: 'F@odly2026',
      );
      await SessionManager.clearBiometricCredential();

      expect(await SessionManager.getBiometricCredential(), isNull);
    });

    test('clearSession (expiración de token) NO borra la credencial: solo '
        'logout explícito debe hacerlo', () async {
      await SessionManager.saveToken('fake.token.here');
      await SessionManager.saveBiometricCredential(
        email: 'cliente@test.com',
        password: 'F@odly2026',
      );

      await SessionManager.clearSession();

      expect(await SessionManager.getToken(), isNull);
      expect(await SessionManager.getBiometricCredential(), isNotNull);
    });

    test(
      'saveBiometricCredential sobrescribe una credencial anterior',
      () async {
        await SessionManager.saveBiometricCredential(
          email: 'viejo@test.com',
          password: 'vieja',
        );
        await SessionManager.saveBiometricCredential(
          email: 'nuevo@test.com',
          password: 'nueva',
        );

        final credential = await SessionManager.getBiometricCredential();
        expect(credential!.email, 'nuevo@test.com');
        expect(credential.password, 'nueva');
      },
    );
  });

  group('BiometricResult enum', () {
    test('todos los valores del enum están definidos', () {
      expect(BiometricResult.values.length, 5);
      expect(
        BiometricResult.values,
        containsAll([
          BiometricResult.success,
          BiometricResult.failed,
          BiometricResult.unavailable,
          BiometricResult.notEnrolled,
          BiometricResult.lockedOut,
        ]),
      );
    });
  });
}
