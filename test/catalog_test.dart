import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/catalog/catalog_filter.dart';
import 'package:foodly_mobile/domain/catalog/busqueda_platos_filter.dart';
import 'package:foodly_mobile/domain/catalog/catalog_global_search.dart';
import 'package:foodly_mobile/domain/catalog/catalog_search_merge.dart';
import 'package:foodly_mobile/domain/catalog/local_list_filter.dart';
import 'package:foodly_mobile/data/mock_catalog_data.dart';
import 'package:foodly_mobile/data/models/local_model.dart';
import 'package:foodly_mobile/data/models/plato_model.dart';
import 'package:foodly_mobile/data/models/promocion_model.dart';
import 'package:foodly_mobile/data/repositories/catalog_repository.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LocalModel', () {
    test('fromJson ignora campos extra como passwd', () {
      final json = {
        'id': 10,
        'nombre': 'Test Local',
        'descripcion': 'Desc',
        'calificacionGlobal': 4.2,
        'estaAbierto': true,
        'foto': 'https://cdn.test/logo.png',
        'imagenes': ['https://img.test/fachada.jpg'],
        'passwd': 'hash',
        'direccion': {
          'calle': 'Calle',
          'numero': '1',
          'ciudad': 'Montevideo',
        },
      };

      final local = LocalModel.fromJson(json);

      expect(local.id, 10);
      expect(local.nombre, 'Test Local');
      expect(local.foto, 'https://cdn.test/logo.png');
      expect(local.imagenPrincipal, 'https://cdn.test/logo.png');
    });

    test('imagenPrincipal usa imagenes si foto está vacía', () {
      final local = LocalModel.fromJson({
        'id': 1,
        'nombre': 'Local',
        'descripcion': '',
        'calificacionGlobal': 0,
        'estaAbierto': true,
        'imagenes': ['https://img.test/1.jpg'],
      });

      expect(local.imagenPrincipal, 'https://img.test/1.jpg');
    });
  });

  group('PlatoModel', () {
    test('fromJson parsea disponible false', () {
      final plato = PlatoModel.fromJson({
        'id': 1,
        'nombre': 'Test',
        'descripcion': '',
        'precio': 100,
        'imagenes': [],
        'disponible': false,
        'dtLocal': {'id': 2},
      });

      expect(plato.disponible, isFalse);
    });

    test('fromJson parsea disponible ausente como true', () {
      final plato = PlatoModel.fromJson({
        'id': 1,
        'nombre': 'Test',
        'descripcion': '',
        'precio': 100,
        'imagenes': [],
        'dtLocal': {'id': 2},
      });

      expect(plato.disponible, isTrue);
    });

    test('fromJson usa el campo "imagen" (singular) del backend', () {
      final plato = PlatoModel.fromJson({
        'id': 1,
        'nombre': 'Test',
        'descripcion': '',
        'precio': 100,
        'imagen': 'https://cdn.test/plato.jpg',
        'dtLocal': {'id': 2},
      });

      expect(plato.imagenPrincipal, 'https://cdn.test/plato.jpg');
    });

    test('fromJson usa "imagenes" como fallback si no hay "imagen"', () {
      final plato = PlatoModel.fromJson({
        'id': 1,
        'nombre': 'Test',
        'descripcion': '',
        'precio': 100,
        'imagenes': ['https://cdn.test/legacy.jpg'],
        'dtLocal': {'id': 2},
      });

      expect(plato.imagenPrincipal, 'https://cdn.test/legacy.jpg');
    });

    test('fromJson parsea dtCategoria', () {
      final plato = PlatoModel.fromJson({
        'id': 1,
        'nombre': 'Test',
        'descripcion': '',
        'precio': 100,
        'dtLocal': {'id': 2},
        'dtCategoria': {'id': 7, 'nombre': 'Postres', 'idLocal': 2},
      });

      expect(plato.categoriaId, 7);
      expect(plato.categoriaNombre, 'Postres');
    });
  });

  group('CatalogFilter', () {
    test('filtra por nombre y solo abiertos', () {
      final result = CatalogFilter.filterLocales(
        locales: mockLocales,
        query: 'pizza',
        soloAbiertos: true,
      );

      expect(result.length, 1);
      expect(result.first.nombre, 'Pizza Napoli');
    });

    test('ordena por calificación descendente', () {
      final result = CatalogFilter.filterLocales(
        locales: mockLocales,
        sort: LocalSortOption.calificacion,
      );

      expect(result.first.nombre, 'Sushi MVD');
    });

    test('destacados retorna abiertos ordenados por calificación', () {
      final result = CatalogFilter.destacados(locales: mockLocales, limit: 2);

      expect(result.length, 2);
      expect(result.every((local) => local.estaAbierto), isTrue);
      expect(
        result[0].calificacionGlobal >= result[1].calificacionGlobal,
        isTrue,
      );
    });

    test('filterPlatos filtra por categoriaId', () {
      const entrada = PlatoModel(
        id: 1,
        nombre: 'Empanada',
        descripcion: '',
        precio: 100,
        imagenes: [],
        disponible: true,
        localId: 1,
        categoriaId: 1,
        categoriaNombre: 'Entradas',
      );
      const postre = PlatoModel(
        id: 2,
        nombre: 'Flan',
        descripcion: '',
        precio: 150,
        imagenes: [],
        disponible: true,
        localId: 1,
        categoriaId: 2,
        categoriaNombre: 'Postres',
      );

      final result = CatalogFilter.filterPlatos(
        platos: [entrada, postre],
        localId: 1,
        categoriaId: 2,
      );

      expect(result.length, 1);
      expect(result.first.nombre, 'Flan');
    });

    test('categoriasDeLocal deduplica y ordena por nombre', () {
      const a = PlatoModel(
        id: 1,
        nombre: 'Empanada',
        descripcion: '',
        precio: 100,
        imagenes: [],
        disponible: true,
        localId: 1,
        categoriaId: 2,
        categoriaNombre: 'Postres',
      );
      const b = PlatoModel(
        id: 2,
        nombre: 'Flan',
        descripcion: '',
        precio: 150,
        imagenes: [],
        disponible: true,
        localId: 1,
        categoriaId: 2,
        categoriaNombre: 'Postres',
      );
      const c = PlatoModel(
        id: 3,
        nombre: 'Milanesa',
        descripcion: '',
        precio: 300,
        imagenes: [],
        disponible: true,
        localId: 1,
        categoriaId: 1,
        categoriaNombre: 'Principales',
      );

      final result = CatalogFilter.categoriasDeLocal(
        platos: [a, b, c],
        localId: 1,
      );

      expect(result.length, 2);
      expect(result[0].nombre, 'Postres');
      expect(result[1].nombre, 'Principales');
    });
  });

  group('CatalogRepository', () {
    test('mock retorna locales', () async {
      final repository = CatalogRepository(
        dataSource: const MockCatalogDataSource(),
      );

      final locales = await repository.listarLocales();

      expect(locales, isNotEmpty);
      expect(repository.usesMockData, isTrue);
    });

    test('API null retorna lista vacía', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/clientes/listar_locales');
        return http.Response('null', 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final locales = await repository.listarLocales();

      expect(locales, isEmpty);
    });

    test('API lista parsea locales', () async {
      final body = jsonEncode([
        {
          'id': 1,
          'nombre': 'API Local',
          'descripcion': 'Desde API',
          'calificacionGlobal': 5,
          'estaAbierto': true,
          'imagenes': [],
        },
      ]);

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/clientes/listar_locales');
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final locales = await repository.listarLocales();

      expect(locales.length, 1);
      expect(locales.first.nombre, 'API Local');
    });

    test('API error 500 lanza ApiException', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      // Debe lanzar ApiException para que la UI muestre error
      expect(
        () => repository.listarLocales(),
        throwsA(isA<Exception>()),
      );
    });

    test('API con catálogo real habilitado por defecto', () async {
      // Verificar que useMockCatalog es false por defecto (Fase 8)
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/clientes/listar_locales');
        return http.Response(jsonEncode([]), 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      await repository.listarLocales();

      expect(repository.usesMockData, isFalse);
    });

    test('API parsea múltiples locales con imágenes', () async {
      final body = jsonEncode([
        {
          'id': 1,
          'nombre': 'Local 1',
          'descripcion': 'Desc 1',
          'calificacionGlobal': 4.5,
          'estaAbierto': true,
          'imagenes': ['img1.jpg', 'img2.jpg'],
        },
        {
          'id': 2,
          'nombre': 'Local 2',
          'descripcion': 'Desc 2',
          'calificacionGlobal': 4.8,
          'estaAbierto': false,
          'imagenes': ['img3.jpg'],
        },
      ]);

      final client = MockClient((request) async {
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final locales = await repository.listarLocales();

      expect(locales.length, 2);
      expect(locales[0].imagenPrincipal, 'img1.jpg');
      expect(locales[1].imagenPrincipal, 'img3.jpg');
      expect(locales[0].estaAbierto, isTrue);
      expect(locales[1].estaAbierto, isFalse);
    });
    test('API parsea platos de un local', () async {
      final body = jsonEncode({
        'platos': [
          {
            'id': 10,
            'nombre': 'Milanesa',
            'descripcion': 'Con papas',
            'precio': 450.0,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 3},
          },
        ],
        'promociones': [],
      });

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/clientes/busqueda');
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos.length, 1);
      expect(platos.first.nombre, 'Milanesa');
      expect(platos.first.localId, 3);
    });

    test('API listar_locales envía query params de filtros server-side', () async {
      Map<String, String>? capturedParams;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/clientes/listar_locales');
        capturedParams = request.url.queryParameters;
        return http.Response(jsonEncode([]), 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      await repository.listarLocales(
        filter: const LocalListFilter(
          nombre: 'pizza',
          soloAbiertos: true,
          ordenarPor: 'calificacion',
          direccion: 'desc',
        ),
      );

      expect(capturedParams, {
        'nombre': 'pizza',
        'estaAbierto': 'true',
        'ordenarPor': 'calificacion',
        'direccion': 'desc',
      });
    });

    test('API merge plato con promoción aplica descuento', () async {
      final body = jsonEncode({
        'platos': [
          {
            'id': 10,
            'nombre': 'Milanesa',
            'descripcion': 'Con papas',
            'precio': 500.0,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 3},
          },
        ],
        'promociones': [
          {
            'id': 99,
            'descuento': 20,
            'descripcion': '20% off',
            'dtPlato': {
              'id': 10,
              'nombre': 'Milanesa',
              'descripcion': 'Con papas',
              'precio': 500.0,
              'disponible': true,
              'imagenes': [],
              'dtLocal': {'id': 3},
            },
          },
        ],
      });

      final client = MockClient((request) async {
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos.length, 1);
      expect(platos.first.tienePromocion, isTrue);
      expect(platos.first.precioOriginal, 500);
      expect(platos.first.precioFinal, 400);
      expect(platos.first.descuentoPercent, 20);
      expect(platos.first.promocionId, 99);
    });

    test('API 400 sin resultados retorna lista vacía', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"mensaje":"No se encontraron platos o promociones que coincidan con su búsqueda.","status":400}',
          400,
        );
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos, isEmpty);
    });

    test('respuesta 200 con promos inválidas devuelve platos sin merge', () async {
      final body = jsonEncode({
        'platos': [
          {
            'id': 10,
            'nombre': 'Milanesa',
            'descripcion': 'Con papas',
            'precio': 450.0,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 3},
          },
        ],
        'promociones': [
          {'id': 'no-numerico', 'descuento': 10},
        ],
      });

      final client = MockClient((request) async {
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos.length, 1);
      expect(platos.first.nombre, 'Milanesa');
      expect(platos.first.tienePromocion, isFalse);
    });

    test('respuesta backend enriquecida + promociones merge badge y precio', () async {
      // Forma real de ClienteService.buscarPlatosYPromociones tras el fix de platos.
      final body = jsonEncode({
        'platos': [
          {
            'id': 10,
            'nombre': 'Milanesa',
            'descripcion': 'Con papas',
            'precio': 500.0,
            'precioFinal': 400.0,
            'tienePromocion': true,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 3},
            'dtCategoria': {'id': 1, 'nombre': 'Principal', 'idLocal': 3},
          },
        ],
        'promociones': [
          {
            'id': 99,
            'descuento': 20.0,
            'descripcion': '20% off',
            'dtPlato': {
              'id': 10,
              'nombre': 'Milanesa',
              'descripcion': 'Con papas',
              'precio': 500.0,
              'disponible': true,
              'imagenes': [],
              'dtLocal': {'id': 3},
            },
          },
        ],
      });

      final client = MockClient((request) async {
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos.length, 1);
      expect(platos.first.tienePromocion, isTrue);
      expect(platos.first.precioOriginal, 500);
      expect(platos.first.precioFinal, 400);
      expect(platos.first.descuentoPercent, 20);
      expect(platos.first.promocionId, 99);
      expect(platos.first.promocionTitulo, '20% off');
    });

    test('platos con promo del backend sin array promociones muestran descuento', () async {
      final body = jsonEncode({
        'platos': [
          {
            'id': 10,
            'nombre': 'Milanesa',
            'precio': 500.0,
            'precioFinal': 400.0,
            'tienePromocion': true,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 3},
          },
        ],
        'promociones': [],
      });

      final client = MockClient((request) async {
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos.single.descuentoPercent, 20);
      expect(platos.single.precioFinal, 400);
    });

    test('500 en busqueda intenta fallback GET platos del local', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        if (request.url.path == '/api/v1/clientes/busqueda') {
          return http.Response(
            '{"mensaje":"Error interno del servidor","status":500}',
            500,
          );
        }
        expect(request.url.path, '/api/v1/locales/busqueda_plato_local/3');
        return http.Response(
          jsonEncode([
            {
              'id': 10,
              'nombre': 'Pizza',
              'descripcion': '',
              'precio': 300.0,
              'disponible': true,
              'imagenes': [],
              'dtLocal': {'id': 3},
            },
          ]),
          200,
        );
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final platos = await repository.platosDeLocal(3);

      expect(platos.length, 1);
      expect(platos.first.nombre, 'Pizza');
    });
  });

  group('LocalListFilter', () {
    test('toRequestBody omite campos vacíos', () {
      expect(const LocalListFilter().toRequestBody(), isEmpty);
    });

    test('fromUi mapea búsqueda y chip abiertos', () {
      final filter = LocalListFilter.fromUi(
        query: ' burger ',
        soloAbiertos: true,
        sort: LocalSortOption.nombre,
      );

      expect(filter.toRequestBody(), {
        'nombre': 'burger',
        'estaAbierto': true,
        'ordenarPor': 'nombre',
        'direccion': 'asc',
      });
    });
  });

  group('CatalogSearchMerge', () {
    test('elige la promo con mayor descuento si hay empate de precio', () {
      const plato = PlatoModel(
        id: 1,
        nombre: 'Burger',
        descripcion: '',
        precio: 500,
        imagenes: [],
        disponible: true,
        localId: 2,
      );

      final merged = CatalogSearchMerge.merge(
        platos: [plato],
        promociones: [
          PromocionModel(
            id: 1,
            descuento: 10,
            plato: plato,
          ),
          PromocionModel(
            id: 2,
            descuento: 25,
            plato: plato,
          ),
        ],
      );

      expect(merged.single.precioFinal, 375);
      expect(merged.single.descuentoPercent, 25);
    });
  });

  group('BusquedaPlatosFilter', () {
    test('toRequestBody mapea nombre y promociones', () {
      const filter = BusquedaPlatosFilter(
        query: 'burger',
        soloPromociones: true,
        sort: PlatoSearchSort.precioAsc,
      );

      expect(filter.toRequestBody(), {
        'nombre': 'burger',
        'promocionActiva': true,
        'precioMasBajo': true,
      });
    });

    test('toRequestBody vacío sin query ni filtros', () {
      expect(const BusquedaPlatosFilter().toRequestBody(), isEmpty);
    });
  });

  group('CatalogGlobalSearch', () {
    test('fromResponse extrae localNombre y merge promo', () {
      final decoded = {
        'platos': [
          {
            'id': 10,
            'nombre': 'Milanesa',
            'descripcion': '',
            'precio': 500.0,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 3, 'nombre': 'La Milanesa'},
          },
        ],
        'promociones': [
          {
            'id': 1,
            'descuento': 20,
            'dtPlato': {
              'id': 10,
              'nombre': 'Milanesa',
              'precio': 500.0,
              'dtLocal': {'id': 3, 'nombre': 'La Milanesa'},
            },
          },
        ],
      };

      final items = CatalogGlobalSearch.fromResponse(decoded);

      expect(items.length, 1);
      expect(items.first.localNombre, 'La Milanesa');
      expect(items.first.plato.localId, 3);
      expect(items.first.plato.tienePromocion, isTrue);
      expect(items.first.plato.precioFinal, 400);
    });

    test('soloPromociones filtra platos sin descuento', () {
      final decoded = {
        'platos': [
          {
            'id': 1,
            'nombre': 'Sin promo',
            'precio': 100.0,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 1, 'nombre': 'Local A'},
          },
          {
            'id': 2,
            'nombre': 'Con promo',
            'precio': 200.0,
            'precioFinal': 150.0,
            'tienePromocion': true,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 2, 'nombre': 'Local B'},
          },
        ],
        'promociones': [],
      };

      final all = CatalogGlobalSearch.fromResponse(decoded);
      final promos = CatalogGlobalSearch.fromResponse(
        decoded,
        soloPromociones: true,
      );

      expect(all.length, 2);
      expect(promos.length, 1);
      expect(promos.first.plato.nombre, 'Con promo');
    });
  });

  group('CatalogRepository buscarPlatos', () {
    test('mock filtra por nombre', () async {
      final repository = CatalogRepository(
        dataSource: const MockCatalogDataSource(),
      );

      final items = await repository.buscarPlatos(
        const BusquedaPlatosFilter(query: 'muzz'),
      );

      expect(items.length, 1);
      expect(items.first.plato.nombre, 'Muzzarella');
      expect(items.first.localNombre, 'Pizza Napoli');
    });

    test('API envía query params de búsqueda global', () async {
      Map<String, String>? capturedParams;

      final body = jsonEncode({
        'platos': [
          {
            'id': 10,
            'nombre': 'Burger',
            'precio': 400.0,
            'disponible': true,
            'imagenes': [],
            'dtLocal': {'id': 1, 'nombre': 'Burger House'},
          },
        ],
        'promociones': [],
      });

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/clientes/busqueda');
        capturedParams = request.url.queryParameters;
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final items = await repository.buscarPlatos(
        const BusquedaPlatosFilter(
          query: 'burger',
          sort: PlatoSearchSort.precioDesc,
        ),
      );

      expect(capturedParams, {
        'nombre': 'burger',
        'precioMasAlto': 'true',
      });
      expect(items.length, 1);
      expect(items.first.localNombre, 'Burger House');
    });
  });
}
