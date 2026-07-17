import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/auth/biometric_service.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/cliente_profile_model.dart';
import 'package:foodly_mobile/data/repositories/cliente_profile_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:foodly_mobile/screens/profile_screen.dart';
import 'package:foodly_mobile/theme/foodly_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Stub que cuenta cuántas veces se llamó a authenticate() (para verificar
/// que activar Y desactivar el toggle biométrico piden confirmación).
class _CountingBiometricService implements BiometricService {
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BiometricResult> authenticate() async {
    authenticateCalls++;
    return BiometricResult.success;
  }
}

/// Simula un dispositivo que no expone ningún biométrico a la app (sin
/// nada configurado en el sistema, o un fabricante que no deja usar el
/// reconocimiento facial propio desde apps de terceros).
class _UnavailableBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricResult> authenticate() async => BiometricResult.unavailable;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SessionManager.enableMemoryStorageForTest();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const profile = ClienteProfileModel(
    id: 7,
    email: 'cliente@test.com',
    nombre: 'Juan',
    apellido: 'Pérez',
  );

  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('No apareció ${finder.description}');
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    BiometricService? biometricService,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await SessionManager.saveToken('test.token');
    await SessionManager.saveProfileJson(jsonEncode(profile.toJson()));

    final repository = ClienteProfileRepository(
      api: ApiClient(
        client: MockClient(
          (_) async => http.Response('{"mensaje":"no disponible"}', 500),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: FoodlyTheme.light,
        home: ProfileScreen(
          profileRepository: repository,
          biometricService: biometricService,
        ),
      ),
    );

    await pumpUntil(tester, find.text('Editar'));
  }

  testWidgets('Editar abre la pantalla de edición de perfil', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Editar'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets(
    'Editar perfil: "Número" y "Código postal" solo aceptan dígitos',
    (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Editar'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final numeroField = find.widgetWithText(TextFormField, 'Número');
      expect(numeroField, findsOneWidget);
      await tester.enterText(numeroField, '12a b3');
      await tester.pump();
      expect(tester.widget<TextFormField>(numeroField).controller?.text, '123');

      final cpField = find.widgetWithText(TextFormField, 'Código postal');
      expect(cpField, findsOneWidget);
      await tester.enterText(cpField, '11a 000');
      await tester.pump();
      expect(tester.widget<TextFormField>(cpField).controller?.text, '11000');
    },
  );

  testWidgets('Cambiar contraseña abre el wizard', (tester) async {
    await pumpProfile(tester);

    final changePassword = find.text('Cambiar contraseña');
    await tester.ensureVisible(changePassword);
    await tester.pump();
    await tester.tap(changePassword);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('SOLICITAR CÓDIGO'), findsOneWidget);
    expect(find.textContaining('iniciaste sesión con Google'), findsOneWidget);
  });

  testWidgets(
    'Desactivar el acceso biométrico también pide confirmación biométrica',
    (tester) async {
      await SessionManager.setBiometricEnabled(true);
      await SessionManager.saveBiometricCredential(
        email: 'cliente@test.com',
        password: 'F@odly2026',
      );
      final biometricService = _CountingBiometricService();

      await pumpProfile(tester, biometricService: biometricService);

      final toggle = find.byType(Switch);
      expect(toggle, findsOneWidget);
      expect(tester.widget<Switch>(toggle).value, isTrue);

      await tester.tap(toggle);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(biometricService.authenticateCalls, 1);
      expect(tester.widget<Switch>(toggle).value, isFalse);
      expect(await SessionManager.getBiometricEnabled(), isFalse);
      // Sin el toggle activo no tiene sentido seguir guardando la
      // credencial que usaba el login biométrico.
      expect(await SessionManager.getBiometricCredential(), isNull);
    },
  );

  testWidgets(
    'Sin biometría disponible en el dispositivo, muestra el aviso en vez '
    'del toggle',
    (tester) async {
      await pumpProfile(
        tester,
        biometricService: _UnavailableBiometricService(),
      );

      expect(find.byType(Switch), findsNothing);
      expect(
        find.textContaining('no tiene huella o Face ID configurados'),
        findsOneWidget,
      );
    },
  );
}
