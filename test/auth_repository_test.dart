import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/direccion_model.dart';
import 'package:foodly_mobile/data/repositories/auth_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _fakeToken({String role = 'ROLE_USER'}) {
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'role': role, 'sub': 'cliente@foodly.com'})),
  );
  return 'header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  group('AuthRepository', () {
    test('login envía passwd (no password) en el body', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/login');
        expect(request.method, 'POST');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'token': _fakeToken(role: 'ROLE_Cliente'),
            'id': 1,
            'email': 'cliente@foodly.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      await repository.login(
        email: 'cliente@foodly.com',
        password: 'Clave123',
      );

      expect(capturedBody?['email'], 'cliente@foodly.com');
      expect(capturedBody?['passwd'], 'Clave123');
      expect(capturedBody?.containsKey('password'), isFalse);

      await SessionManager.clearSession();
    });

    test('login 200 guarda token, usuario y perfil si el backend lo incluye', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/login');
        return http.Response(
          jsonEncode({
            'token': _fakeToken(),
            'id': 123,
            'email': 'cliente@foodly.com',
            'tipo': 'CLIENTE',
            'nombre': 'Juan',
            'apellido': 'Pérez',
            'foto': 'https://cdn.test/foto.jpg',
            'direccion': {
              'calle': 'Av. Italia',
              'numero': '100',
              'ciudad': 'Montevideo',
              'codigoPostal': '11000',
            },
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      final response = await repository.login(
        email: 'cliente@foodly.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(await SessionManager.getToken(), isNotEmpty);
      expect(await SessionManager.getUsuarioInfoJson(), isNotNull);
      expect(await SessionManager.getProfileJson(), contains('"nombre":"Juan"'));
      expect(await SessionManager.getProfileJson(), contains('"apellido":"Pérez"'));
      await SessionManager.clearSession();
    });

    test('login 200 sin datos de perfil no guarda profileJson', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/login');
        return http.Response(
          jsonEncode({
            'token': _fakeToken(),
            'id': 123,
            'email': 'cliente@foodly.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      await repository.login(
        email: 'cliente@foodly.com',
        password: 'Clave123',
      );

      expect(await SessionManager.getProfileJson(), isNull);
      await SessionManager.clearSession();
    });

    test('login 401 lanza ApiException con mensaje de credenciales', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'mensaje':
                'Correo electrónico o contraseña incorrectos',
          }),
          401,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      expect(
        () => repository.login(
          email: 'cliente@foodly.com',
          password: 'wrong',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 401)
              .having(
                (e) => e.userMessage,
                'userMessage',
                contains('incorrectos'),
              ),
        ),
      );
    });

    test('login 404 diferencia cuenta no activada', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'mensaje': 'Usuario no activado o bloqueado.'}),
          404,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      expect(
        () => repository.login(
          email: 'cliente@foodly.com',
          password: 'Clave123',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 404)
              .having(
                (e) => e.userMessage,
                'userMessage',
                contains('no activado'),
              ),
        ),
      );
    });

    test('login 200 con estructura flat del backend incluye usuario', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': _fakeToken(),
            'id': 456,
            'email': 'test@foodly.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      final response = await repository.login(
        email: 'test@foodly.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(response.usuario, isNotNull);
      expect(response.usuario!.id, 456);
      expect(response.usuario!.email, 'test@foodly.com');
      expect(response.usuario!.tipo, 'CLIENTE');

      await SessionManager.clearSession();
    });

    test('login 200 con ROLE_Cliente del backend permite acceso', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': _fakeToken(role: 'ROLE_Cliente'),
            'id': 789,
            'email': 'fedcam42@hotmail.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      final response = await repository.login(
        email: 'fedcam42@hotmail.com',
        password: 'Clave123',
      );

      expect(response.token, isNotEmpty);
      expect(await SessionManager.getToken(), isNotEmpty);

      await SessionManager.clearSession();
    });

    test('login 200 con ROLE_Admin lanza ApiException 403', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': _fakeToken(role: 'ROLE_Admin'),
            'id': 1,
            'email': 'admin@foodly.com',
            'tipo': 'ADMIN',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      expect(
        () => repository.login(
          email: 'admin@foodly.com',
          password: 'Clave123',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'status',
            403,
          ),
        ),
      );
      expect(await SessionManager.getToken(), isNull);
    });

    test('loginWithGoogle envía access token en idToken y esRegistro false', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        // Actualizado al nuevo endpoint móvil
        expect(request.url.path, '/api/v1/clientes/google/mobile');
        expect(request.method, 'POST');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'token': _fakeToken(role: 'ROLE_Cliente'),
            'id': 99,
            'email': 'google@foodly.com',
            'tipo': 'CLIENTE',
            'nombre': 'Google',
            'apellido': 'User',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      await repository.loginWithGoogle(accessToken: 'oauth-access-token-xyz');

      expect(capturedBody?['idToken'], 'oauth-access-token-xyz');
      expect(capturedBody?['esRegistro'], isFalse);
      expect(capturedBody?.containsKey('documento'), isFalse);
      expect(await SessionManager.getToken(), isNotEmpty);
      await SessionManager.clearSession();
    });

    test('loginWithGoogle registro incluye documento y dirección', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        // Verificar que se llama al endpoint móvil correcto
        expect(request.url.path, '/api/v1/clientes/google/mobile');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'token': _fakeToken(role: 'ROLE_Cliente'),
            'id': 100,
            'email': 'nuevo@foodly.com',
            'tipo': 'CLIENTE',
          }),
          200,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));
      await repository.loginWithGoogle(
        accessToken: 'google-token',
        esRegistro: true,
        documento: '12345678',
        direccion: const DireccionModel(
          calle: 'Av. Italia',
          numero: '100',
          ciudad: 'Montevideo',
          codigoPostal: '11000',
        ),
      );

      expect(capturedBody?['esRegistro'], isTrue);
      expect(capturedBody?['documento'], '12345678');
      expect(capturedBody?['direccion'], isA<Map<String, dynamic>>());
      final dir = capturedBody?['direccion'] as Map<String, dynamic>;
      expect(dir['calle'], 'Av. Italia');
      expect(dir['codigoPostal'], '11000');
      await SessionManager.clearSession();
    });

    test('loginWithGoogle error del backend propaga mensaje', () async {
      final client = MockClient((request) async {
        // Verificar que se llama al endpoint móvil correcto
        expect(request.url.path, '/api/v1/clientes/google/mobile');
        return http.Response(
          jsonEncode({
            'mensaje':
                'Ya existe una cuenta registrada con este email. Iniciá sesión en su lugar.',
          }),
          400,
        );
      });

      final repository = AuthRepository(api: ApiClient(client: client));

      expect(
        () => repository.loginWithGoogle(accessToken: 'bad-token'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 400)
              .having(
                (e) => e.userMessage,
                'userMessage',
                contains('Ya existe una cuenta'),
              ),
        ),
      );
    });
  });
}
