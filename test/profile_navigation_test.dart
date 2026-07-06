import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/cliente_profile_model.dart';
import 'package:foodly_mobile/data/repositories/cliente_profile_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:foodly_mobile/screens/profile_screen.dart';
import 'package:foodly_mobile/theme/foodly_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  Future<void> pumpProfile(WidgetTester tester) async {
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
        home: ProfileScreen(profileRepository: repository),
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
  });
}
