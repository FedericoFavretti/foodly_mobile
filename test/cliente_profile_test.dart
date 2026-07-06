import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/models/cliente_profile_model.dart';
import 'package:foodly_mobile/data/repositories/cliente_profile_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SessionManager.resetForTest());

  test('ClienteProfileModel.fromJson parsea dirección y foto', () {
    final profile = ClienteProfileModel.fromJson({
      'id': 7,
      'email': 'cliente@test.com',
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'foto': 'https://cdn.test/foto.jpg',
      'direccion': {
        'calle': 'Av. Italia',
        'numero': '100',
        'ciudad': 'Montevideo',
        'codigoPostal': '11000',
      },
    });

    expect(profile.id, 7);
    expect(profile.fotoUrl, 'https://cdn.test/foto.jpg');
    expect(profile.tieneFoto, isTrue);
    expect(profile.direccion?.calle, 'Av. Italia');
  });

  test('tryFromLoginJson parsea respuesta extendida de login', () {
    final profile = ClienteProfileModel.tryFromLoginJson({
      'id': 41,
      'email': 'fedcam42@hotmail.com',
      'nombre': 'Federico',
      'apellido': 'Favretti',
      'foto': 'https://cdn.test/foto.jpg',
      'direccion': {
        'calle': 'Rivera',
        'numero': '1',
        'ciudad': 'Empalme Olmos',
        'codigoPostal': '15600',
      },
      'token': 'ignored',
      'tipo': 'cliente',
    });

    expect(profile, isNotNull);
    expect(profile!.nombre, 'Federico');
    expect(profile.apellido, 'Favretti');
    expect(profile.direccion?.ciudad, 'Empalme Olmos');
  });

  test('getOrFetch usa perfil cacheado del login si GET /perfil falla', () async {
    await SessionManager.saveToken('test.token');
    await SessionManager.saveProfileJson(jsonEncode({
      'id': 7,
      'email': 'cliente@test.com',
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'direccion': {
        'calle': 'Av. Italia',
        'numero': '100',
        'ciudad': 'Montevideo',
      },
    }));

    final client = MockClient((request) async {
      return http.Response(
        '{"mensaje":"Error interno del servidor","status":500}',
        500,
      );
    });

    final repository = ClienteProfileRepository(api: ApiClient(client: client));
    final profile = await repository.getOrFetch();

    expect(profile.nombre, 'Juan');
    expect(profile.apellido, 'Pérez');
    expect(profile.direccion?.calle, 'Av. Italia');
  });

  test('fetchAndCache trae nombre y dirección desde GET /perfil', () async {
    await SessionManager.saveToken('test.token');

    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/usuarios/perfil');
      return http.Response(
        jsonEncode({
          'id': 7,
          'email': 'cliente@test.com',
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

    final repository = ClienteProfileRepository(api: ApiClient(client: client));
    final profile = await repository.fetchAndCache();

    expect(profile.nombre, 'Juan');
    expect(profile.apellido, 'Pérez');
    expect(profile.fotoUrl, 'https://cdn.test/foto.jpg');
    expect(profile.direccion?.calle, 'Av. Italia');

    final cached = await SessionManager.getProfileJson();
    expect(cached, contains('"nombre":"Juan"'));
  });

  test('actualizarPerfil parsea DtCliente del PUT y actualiza caché con foto', () async {
    await SessionManager.saveToken('test.token');
    await SessionManager.saveProfileJson(jsonEncode({
      'id': 7,
      'email': 'cliente@test.com',
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'direccion': {
        'calle': 'Av. Italia',
        'numero': '100',
        'ciudad': 'Montevideo',
        'codigoPostal': '11000',
      },
    }));

    var putCount = 0;
    var getCount = 0;

    final client = MockClient((request) async {
      if (request.method == 'PUT' &&
          request.url.path == '/api/v1/usuarios/perfil') {
        putCount++;
        return http.Response(
          jsonEncode({
            'id': 7,
            'email': 'cliente@test.com',
            'tipo': 'cliente',
            'nombre': 'María',
            'apellido': 'Gómez',
            'foto': 'https://cdn.cloudinary.com/nueva-foto.jpg',
            'direccion': {
              'calle': '18 de Julio',
              'numero': '1234',
              'ciudad': 'Montevideo',
              'codigoPostal': '11200',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      getCount++;
      return http.Response('', 404);
    });

    final repository = ClienteProfileRepository(api: ApiClient(client: client));
    final profile = await repository.actualizarPerfil(
      const ActualizarPerfilData(
        nombre: 'Nombre enviado',
        apellido: 'Apellido enviado',
        calle: 'Calle enviada',
        numero: '1',
        ciudad: 'Ciudad enviada',
        codigoPostal: '11000',
      ),
    );

    expect(putCount, 1);
    expect(getCount, 0);
    expect(profile.nombre, 'María');
    expect(profile.apellido, 'Gómez');
    expect(profile.direccion?.calle, '18 de Julio');
    expect(profile.fotoUrl, 'https://cdn.cloudinary.com/nueva-foto.jpg');

    final cached = await SessionManager.getProfileJson();
    expect(cached, contains('"nombre":"María"'));
    expect(cached, contains('"foto":"https://cdn.cloudinary.com/nueva-foto.jpg"'));
  });

  test('actualizarPerfil con 204 sin body usa fallback local', () async {
    await SessionManager.saveToken('test.token');
    await SessionManager.saveProfileJson(jsonEncode({
      'id': 7,
      'email': 'cliente@test.com',
      'nombre': 'Juan',
      'apellido': 'Pérez',
    }));

    final client = MockClient((request) async {
      return http.Response('', 204);
    });

    final repository = ClienteProfileRepository(api: ApiClient(client: client));
    final profile = await repository.actualizarPerfil(
      const ActualizarPerfilData(
        nombre: 'María',
        apellido: 'Gómez',
        calle: '18 de Julio',
        numero: '1234',
        ciudad: 'Montevideo',
        codigoPostal: '11200',
      ),
    );

    expect(profile.nombre, 'María');
    expect(profile.apellido, 'Gómez');
  });
}
