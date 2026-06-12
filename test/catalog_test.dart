import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/catalog/catalog_filter.dart';
import 'package:foodly_mobile/data/mock_catalog_data.dart';
import 'package:foodly_mobile/data/models/local_model.dart';
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
        'imagenes': ['https://img.test/1.jpg'],
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
      expect(local.imagenPrincipal, 'https://img.test/1.jpg');
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
        expect(request.url.path, '/api/v1/clientes');
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
        return http.Response(body, 200);
      });

      final repository = CatalogRepository(
        dataSource: ApiCatalogDataSource(api: ApiClient(client: client)),
      );

      final locales = await repository.listarLocales();

      expect(locales.length, 1);
      expect(locales.first.nombre, 'API Local');
    });
  });
}
