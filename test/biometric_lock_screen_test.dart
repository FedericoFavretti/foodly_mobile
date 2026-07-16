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

String _fakeToken() {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': 'cliente@test.com',
            'role': 'ROLE_CLIENTE',
            'exp': DateTime(2999).millisecondsSinceEpoch ~/ 1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.firma';
}

/// Stub que devuelve una secuencia fija de resultados, uno por llamada a
/// authenticate() (el último se repite si se llama de más).
class _ScriptedBiometricService implements BiometricService {
  _ScriptedBiometricService(this._results);

  final List<BiometricResult> _results;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BiometricResult> authenticate() async {
    final result = _results[calls.clamp(0, _results.length - 1)];
    calls++;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SessionManager.enableMemoryStorageForTest();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildApp(BiometricService service, {AuthRepository? authRepository}) {
    return MaterialApp(
      theme: FoodlyTheme.light,
      routes: {
        MainScreen.routeName: (_) =>
            const Scaffold(body: Center(child: Text('MAIN'))),
        LoginScreen.routeName: (_) =>
            const Scaffold(body: Center(child: Text('LOGIN'))),
      },
      home: BiometricLockScreen(
        biometricService: service,
        authRepository: authRepository,
      ),
    );
  }

  testWidgets('éxito con sesión activa navega a Main sin pegarle al backend', (
    tester,
  ) async {
    await SessionManager.saveToken('sesion.activa');
    final service = _ScriptedBiometricService([BiometricResult.success]);
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    expect(find.text('MAIN'), findsOneWidget);
    expect(service.calls, 1);
  });

  testWidgets('fallo simple muestra "Reintentar" y "Usar contraseña"', (
    tester,
  ) async {
    final service = _ScriptedBiometricService([BiometricResult.failed]);
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    expect(find.text('REINTENTAR'), findsOneWidget);
    expect(find.text('USAR CONTRASEÑA'), findsOneWidget);
    expect(
      find.textContaining('No pudimos verificar tu identidad'),
      findsOneWidget,
    );
  });

  testWidgets('tras 3 fallos seguidos solo queda "Usar contraseña"', (
    tester,
  ) async {
    final service = _ScriptedBiometricService([BiometricResult.failed]);
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    // 2 reintentos más -> 3 fallos en total.
    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(service.calls, 3);
    expect(find.text('REINTENTAR'), findsNothing);
    expect(find.text('USAR CONTRASEÑA'), findsOneWidget);
    expect(find.textContaining('Demasiados intentos fallidos'), findsOneWidget);
  });

  testWidgets('lockedOut deja solo "Usar contraseña" sin esperar 3 intentos', (
    tester,
  ) async {
    final service = _ScriptedBiometricService([BiometricResult.lockedOut]);
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    expect(find.text('REINTENTAR'), findsNothing);
    expect(find.text('USAR CONTRASEÑA'), findsOneWidget);
  });

  testWidgets('"Usar contraseña" limpia la sesión y vuelve al login completo', (
    tester,
  ) async {
    await SessionManager.saveToken('sesion.activa');
    await SessionManager.setBiometricEnabled(true);

    final service = _ScriptedBiometricService([BiometricResult.failed]);
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('USAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
    expect(await SessionManager.getToken(), isNull);
    // La preferencia de biometría no se toca al usar el fallback.
    expect(await SessionManager.getBiometricEnabled(), isTrue);
  });

  testWidgets('éxito sin sesión pero con credencial guardada hace login real y '
      'navega a Main', (tester) async {
    await SessionManager.saveBiometricCredential(
      email: 'cliente@test.com',
      password: 'F@odly2026',
    );

    String? capturedEmail;
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      capturedEmail = body['email'] as String?;
      return http.Response(jsonEncode({'token': _fakeToken(), 'id': 1}), 200);
    });
    final authRepository = AuthRepository(api: ApiClient(client: client));

    final service = _ScriptedBiometricService([BiometricResult.success]);
    await tester.pumpWidget(buildApp(service, authRepository: authRepository));
    await tester.pumpAndSettle();

    expect(find.text('MAIN'), findsOneWidget);
    expect(capturedEmail, 'cliente@test.com');
    expect(await SessionManager.getToken(), isNotNull);
  });

  testWidgets(
    'éxito sin sesión ni credencial guardada vuelve al login completo',
    (tester) async {
      final service = _ScriptedBiometricService([BiometricResult.success]);
      await tester.pumpWidget(buildApp(service));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
    },
  );

  testWidgets(
    'éxito con credencial inválida (contraseña cambiada) la borra y cae '
    'al fallback de contraseña',
    (tester) async {
      await SessionManager.saveBiometricCredential(
        email: 'cliente@test.com',
        password: 'vieja-incorrecta',
      );

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'mensaje': 'Credenciales inválidas.'}),
          401,
        );
      });
      final authRepository = AuthRepository(api: ApiClient(client: client));

      final service = _ScriptedBiometricService([BiometricResult.success]);
      await tester.pumpWidget(
        buildApp(service, authRepository: authRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text('MAIN'), findsNothing);
      expect(find.text('USAR CONTRASEÑA'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsNothing);
      expect(await SessionManager.getBiometricCredential(), isNull);
    },
  );
}
