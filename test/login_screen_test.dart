import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/auth/biometric_service.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/auth_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:foodly_mobile/screens/biometric_lock_screen.dart';
import 'package:foodly_mobile/screens/login_screen.dart';
import 'package:foodly_mobile/screens/main_screen.dart';
import 'package:foodly_mobile/theme/foodly_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Stub que nunca reporta biometría disponible: evita que
/// offerBiometricIfNeeded muestre el diálogo post-login en estos tests.
class _UnavailableBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricResult> authenticate() async => BiometricResult.unavailable;
}

class _AvailableBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BiometricResult> authenticate() async => BiometricResult.success;
}

String _fakeToken({String role = 'ROLE_CLIENTE'}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': 'cliente@test.com',
            'role': role,
            'exp': DateTime(2999).millisecondsSinceEpoch ~/ 1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.firma';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SessionManager.enableMemoryStorageForTest();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpLogin(
    WidgetTester tester,
    AuthRepository authRepository, {
    BiometricService? biometricService,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: FoodlyTheme.light,
        routes: {
          MainScreen.routeName: (_) =>
              const Scaffold(body: Center(child: Text('MAIN'))),
          BiometricLockScreen.routeName: (_) =>
              const Scaffold(body: Center(child: Text('BIOMETRIC_LOCK'))),
        },
        home: LoginScreen(
          authRepository: authRepository,
          biometricService: biometricService ?? _UnavailableBiometricService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitLogin(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'facufa12@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'F@odly2026');
    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();
  }

  testWidgets('login exitoso con biometría ya activa guarda la credencial para '
      'reautenticar más tarde', (tester) async {
    await SessionManager.setBiometricEnabled(true);

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'token': _fakeToken(),
          'id': 7,
          'email': 'facufa12@gmail.com',
        }),
        200,
      );
    });
    final authRepository = AuthRepository(api: ApiClient(client: client));

    await pumpLogin(tester, authRepository);
    await submitLogin(tester);

    expect(find.text('MAIN'), findsOneWidget);
    final credential = await SessionManager.getBiometricCredential();
    expect(credential, isNotNull);
    expect(credential!.email, 'facufa12@gmail.com');
    expect(credential.password, 'F@odly2026');
  });

  testWidgets(
    'login exitoso sin biometría activa no guarda ninguna credencial',
    (tester) async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': _fakeToken(),
            'id': 7,
            'email': 'facufa12@gmail.com',
          }),
          200,
        );
      });
      final authRepository = AuthRepository(api: ApiClient(client: client));

      await pumpLogin(tester, authRepository);
      await submitLogin(tester);

      expect(find.text('MAIN'), findsOneWidget);
      expect(await SessionManager.getBiometricCredential(), isNull);
    },
  );

  testWidgets('muestra "Usar huella / Face ID" si hay biometría activa y una '
      'credencial guardada (aunque no haya sesión)', (tester) async {
    await SessionManager.setBiometricEnabled(true);
    await SessionManager.saveBiometricCredential(
      email: 'facufa12@gmail.com',
      password: 'F@odly2026',
    );

    final authRepository = AuthRepository(
      api: ApiClient(client: MockClient((_) async => http.Response('', 500))),
    );
    await pumpLogin(
      tester,
      authRepository,
      biometricService: _AvailableBiometricService(),
    );

    expect(find.text('Usar huella / Face ID'), findsOneWidget);

    await tester.tap(find.text('Usar huella / Face ID'));
    await tester.pumpAndSettle();

    expect(find.text('BIOMETRIC_LOCK'), findsOneWidget);
  });

  testWidgets(
    'NO muestra "Usar huella / Face ID" si la biometría está activa pero '
    'no hay sesión ni credencial guardada',
    (tester) async {
      await SessionManager.setBiometricEnabled(true);

      final authRepository = AuthRepository(
        api: ApiClient(client: MockClient((_) async => http.Response('', 500))),
      );
      await pumpLogin(
        tester,
        authRepository,
        biometricService: _AvailableBiometricService(),
      );

      expect(find.text('Usar huella / Face ID'), findsNothing);
    },
  );

  testWidgets(
    'NO muestra "Usar huella / Face ID" si el usuario nunca activó la '
    'biometría',
    (tester) async {
      await SessionManager.saveBiometricCredential(
        email: 'facufa12@gmail.com',
        password: 'F@odly2026',
      );

      final authRepository = AuthRepository(
        api: ApiClient(client: MockClient((_) async => http.Response('', 500))),
      );
      await pumpLogin(
        tester,
        authRepository,
        biometricService: _AvailableBiometricService(),
      );

      expect(find.text('Usar huella / Face ID'), findsNothing);
    },
  );
}
