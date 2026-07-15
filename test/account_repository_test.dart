import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/account_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/errors/api_exception.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/account_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AccountRepository', () {
    setUp(() => SessionManager.resetForTest());
    test('solicitarRecuperacion envía correo al backend', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/usuarios/recuperar_contra_correo');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.solicitarRecuperacion('cliente@test.com');

      expect(capturedBody?['correo'], 'cliente@test.com');
    });

    test('restablecerContra envía token y contraseñas', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/recuperar');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.restablecerContra(
        token: 'abc123',
        nuevaPasswd: 'Clave123!',
        confirmacionPasswd: 'Clave123!',
      );

      expect(capturedBody?['token'], 'abc123');
      expect(capturedBody?['nuevaPasswd'], 'Clave123!');
      expect(capturedBody?['confirmacionPasswd'], 'Clave123!');
    });

    test('activarCuenta usa POST con query email', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/usuarios/activar');
        expect(request.url.queryParameters['email'], 'cliente@test.com');
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.activarCuenta('cliente@test.com');
    });

    test('restablecerContra acepta 204 No Content', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.restablecerContra(
        token: 'abc123',
        nuevaPasswd: 'Clave123!',
        confirmacionPasswd: 'Clave123!',
      );
    });

    test('iniciarCambioPasswd envía idUsuario y contraseña actual', () async {
      await SessionManager.saveToken('test.token');
      await SessionManager.saveUsuarioInfoJson('{"id":7,"email":"a@test.com"}');

      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/cambiar-passwd/iniciar');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.iniciarCambioPasswd('Actual123!');

      expect(capturedBody?['idUsuario'], 7);
      expect(capturedBody?['passwdActual'], 'Actual123!');
    });

    test('verificarCodigoCambioPasswd envía código de 6 dígitos', () async {
      await SessionManager.saveToken('test.token');
      await SessionManager.saveUsuarioInfoJson('{"id":7,"email":"a@test.com"}');

      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/usuarios/cambiar-passwd/verificar-codigo',
        );
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.verificarCodigoCambioPasswd('123456');

      expect(capturedBody?['idUsuario'], 7);
      expect(capturedBody?['codigo'], '123456');
    });

    test('confirmarCambioPasswd envía nueva contraseña', () async {
      await SessionManager.saveToken('test.token');
      await SessionManager.saveUsuarioInfoJson('{"id":7,"email":"a@test.com"}');

      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/cambiar-passwd/confirmar');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.confirmarCambioPasswd(
        passwdNueva: 'Nueva123!',
        passwdConfirmacion: 'Nueva123!',
      );

      expect(capturedBody?['idUsuario'], 7);
      expect(capturedBody?['passwdNueva'], 'Nueva123!');
      expect(capturedBody?['passwdConfirmacion'], 'Nueva123!');
    });

    test('400 propaga mensaje del backend', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'mensaje': 'El enlace de recuperación no es válido.'}),
          400,
        );
      });

      final repository = AccountRepository(api: ApiClient(client: client));

      expect(
        () => repository.restablecerContra(
          token: 'bad',
          nuevaPasswd: 'Clave123!',
          confirmacionPasswd: 'Clave123!',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('no es válido'),
          ),
        ),
      );
    });

    test('iniciarCambioCorreo envía nuevoCorreo autenticado', () async {
      await SessionManager.saveToken('test.token');

      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/cambiar-correo/iniciar');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.iniciarCambioCorreo('nuevo@test.com');

      expect(capturedBody?['nuevoCorreo'], 'nuevo@test.com');
    });

    test('confirmarCambioCorreo envía el token y el JWT del usuario', () async {
      await SessionManager.saveToken('sesion.activa');

      Map<String, dynamic>? capturedBody;
      String? capturedAuthHeader;

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/usuarios/cambiar-correo/confirmar');
        capturedAuthHeader = request.headers['Authorization'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 200);
      });

      final repository = AccountRepository(api: ApiClient(client: client));
      await repository.confirmarCambioCorreo('token-abc');

      expect(capturedBody?['token'], 'token-abc');
      // El backend rechaza este endpoint con 403 si no viaja el JWT.
      expect(capturedAuthHeader, 'Bearer sesion.activa');
    });
  });
}
