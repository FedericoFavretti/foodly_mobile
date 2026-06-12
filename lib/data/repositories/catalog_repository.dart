import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../mock_catalog_data.dart';
import '../models/local_model.dart';
import '../models/plato_model.dart';

abstract class CatalogDataSource {
  Future<List<LocalModel>> listarLocales();
  Future<List<PlatoModel>> listarPlatos();
}

class MockCatalogDataSource implements CatalogDataSource {
  const MockCatalogDataSource();

  @override
  Future<List<LocalModel>> listarLocales() async => mockLocales;

  @override
  Future<List<PlatoModel>> listarPlatos() async => mockPlatos;
}

class ApiCatalogDataSource implements CatalogDataSource {
  ApiCatalogDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  @override
  Future<List<LocalModel>> listarLocales() async {
    final response = await _api.get(
      ApiConstants.localesEndpoint,
      requiresAuth: true,
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') {
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      if (decoded is! List) {
        throw ApiException(
          statusCode: 200,
          userMessage: 'Respuesta de locales inválida.',
          debugInfo: response.body,
        );
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalModel.fromJson)
          .toList();
    }

    throw ApiException(
      statusCode: response.statusCode,
      userMessage: 'No pudimos cargar los locales. Intentalo más tarde.',
      debugInfo: response.body,
    );
  }

  @override
  Future<List<PlatoModel>> listarPlatos() async {
    // [PENDIENTE backend]: contrato estable para CU-CL05.
    return [];
  }
}

class CatalogRepository {
  CatalogRepository({CatalogDataSource? dataSource})
      : _dataSource = dataSource ??
            (ApiConstants.useMockCatalog
                ? const MockCatalogDataSource()
                : ApiCatalogDataSource());

  final CatalogDataSource _dataSource;

  bool get usesMockData => _dataSource is MockCatalogDataSource;

  Future<List<LocalModel>> listarLocales() => _dataSource.listarLocales();

  Future<List<PlatoModel>> listarPlatos() => _dataSource.listarPlatos();

  Future<LocalModel?> obtenerLocal(int id) async {
    final locales = await listarLocales();
    for (final local in locales) {
      if (local.id == id) return local;
    }
    return null;
  }

  Future<List<PlatoModel>> platosDeLocal(int localId) async {
    final platos = await listarPlatos();
    return platos.where((p) => p.localId == localId).toList();
  }
}
