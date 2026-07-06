import 'dart:convert';

import '../../core/catalog/catalog_filter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_helpers.dart';
import '../../domain/catalog/busqueda_platos_filter.dart';
import '../../domain/catalog/catalog_global_search.dart';
import '../../domain/catalog/catalog_search_merge.dart';
import '../../domain/catalog/local_list_filter.dart';
import '../../domain/catalog/plato_busqueda_item.dart';
import '../mock_catalog_data.dart';
import '../models/local_model.dart';
import '../models/plato_model.dart';
import '../models/promocion_model.dart';

abstract class CatalogDataSource {
  Future<List<LocalModel>> listarLocales({LocalListFilter? filter});
  Future<List<PlatoModel>> listarPlatosDeLocal(int localId);
  Future<List<PlatoBusquedaItem>> buscarPlatos(BusquedaPlatosFilter filter);
}

class MockCatalogDataSource implements CatalogDataSource {
  const MockCatalogDataSource();

  @override
  Future<List<LocalModel>> listarLocales({LocalListFilter? filter}) async {
    if (filter == null) return mockLocales;

    final body = filter.toRequestBody();
    final query = body['nombre'] as String? ?? '';
    final soloAbiertos = body['estaAbierto'] == true;
    final sort = body['ordenarPor'] == 'calificacion'
        ? LocalSortOption.calificacion
        : LocalSortOption.nombre;

    return CatalogFilter.filterLocales(
      locales: mockLocales,
      query: query,
      soloAbiertos: soloAbiertos,
      sort: sort,
    );
  }

  @override
  Future<List<PlatoModel>> listarPlatosDeLocal(int localId) async {
    return mockPlatos.where((p) => p.localId == localId).toList();
  }

  @override
  Future<List<PlatoBusquedaItem>> buscarPlatos(
    BusquedaPlatosFilter filter,
  ) async {
    final localNames = {
      for (final local in mockLocales) local.id: local.nombre,
    };

    var platos = mockPlatos.toList();
    final query = filter.query.trim().toLowerCase();
    if (query.isNotEmpty) {
      platos = platos
          .where((p) => p.nombre.toLowerCase().contains(query))
          .toList();
    }
    if (filter.soloPromociones) {
      platos = platos.where((p) => p.tienePromocion).toList();
    }
    if (filter.precioMaximo != null) {
      platos =
          platos.where((p) => p.precio <= filter.precioMaximo!).toList();
    }

    switch (filter.sort) {
      case PlatoSearchSort.nombre:
        platos.sort((a, b) => a.nombre.compareTo(b.nombre));
      case PlatoSearchSort.precioAsc:
        platos.sort((a, b) => a.precio.compareTo(b.precio));
      case PlatoSearchSort.precioDesc:
        platos.sort((a, b) => b.precio.compareTo(a.precio));
      case PlatoSearchSort.none:
        break;
    }

    return platos
        .map(
          (plato) => PlatoBusquedaItem(
            plato: plato,
            localNombre: localNames[plato.localId] ?? 'Local',
          ),
        )
        .toList();
  }
}

class ApiCatalogDataSource implements CatalogDataSource {
  ApiCatalogDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  @override
  Future<List<LocalModel>> listarLocales({LocalListFilter? filter}) async {
    final body = filter?.toRequestBody() ?? const <String, dynamic>{};
    final response = await _api.post(
      ApiConstants.listarLocalesEndpoint,
      body,
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
  Future<List<PlatoModel>> listarPlatosDeLocal(int localId) async {
    final response = await _api.post(
      ApiConstants.busquedaPlatosEndpoint,
      {
        'dtLocal': {'id': localId},
      },
      requiresAuth: true,
    );

    if (response.statusCode == 200) {
      return _parseBusquedaResponse(response.body, localId);
    }

    final backendMessage = ApiResponseHelpers.mapErrorMessage(response.body);
    if (response.statusCode == 400 &&
        ApiResponseHelpers.isEmptySearchResult(backendMessage)) {
      return [];
    }

    if (response.statusCode >= 500) {
      final fallback = await _tryFetchPlatosSinPromociones(localId);
      if (fallback != null) return fallback;
    }

    throw ApiException(
      statusCode: response.statusCode,
      userMessage: backendMessage ??
          'No pudimos cargar los platos. Intentalo más tarde.',
      debugInfo: response.body,
    );
  }

  /// Si el backend expone platos sin pasar por promociones, los usamos como plan B.
  Future<List<PlatoModel>?> _tryFetchPlatosSinPromociones(int localId) async {
    try {
      final response = await _api.get(
        ApiConstants.platosLocalFallbackEndpoint(localId),
        requiresAuth: true,
      );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      final platos = decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => PlatoModel.tryFromJson(json, fallbackLocalId: localId))
          .whereType<PlatoModel>()
          .toList();

      return platos.isEmpty ? null : platos;
    } catch (_) {
      return null;
    }
  }

  List<PlatoModel> _parseBusquedaResponse(String body, int localId) {
    if (body.isEmpty || body == 'null') return [];

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: 200,
        userMessage: 'Respuesta de platos inválida.',
        debugInfo: body,
      );
    }

    final platos = _parsePlatosList(decoded['platos'], localId);

    try {
      final promociones = _parsePromocionesList(decoded['promociones']);
      if (promociones.isEmpty) return platos;
      return CatalogSearchMerge.merge(
        platos: platos,
        promociones: promociones,
      );
    } catch (_) {
      return platos;
    }
  }

  List<PlatoModel> _parsePlatosList(dynamic platosRaw, int localId) {
    if (platosRaw == null) return [];
    if (platosRaw is! List) return [];
    return platosRaw
        .whereType<Map<String, dynamic>>()
        .map((json) => PlatoModel.tryFromJson(json, fallbackLocalId: localId))
        .whereType<PlatoModel>()
        .toList();
  }

  List<PromocionModel> _parsePromocionesList(dynamic promocionesRaw) {
    if (promocionesRaw == null) return [];
    if (promocionesRaw is! List) return [];
    return promocionesRaw
        .whereType<Map<String, dynamic>>()
        .map(PromocionModel.tryFromJson)
        .whereType<PromocionModel>()
        .toList();
  }

  @override
  Future<List<PlatoBusquedaItem>> buscarPlatos(
    BusquedaPlatosFilter filter,
  ) async {
    final response = await _api.post(
      ApiConstants.busquedaPlatosEndpoint,
      filter.toRequestBody(),
      requiresAuth: true,
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') {
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: 200,
          userMessage: 'Respuesta de búsqueda inválida.',
          debugInfo: response.body,
        );
      }
      return CatalogGlobalSearch.fromResponse(
        decoded,
        soloPromociones: filter.soloPromociones,
        precioMaximo: filter.precioMaximo,
      );
    }

    final backendMessage = ApiResponseHelpers.mapErrorMessage(response.body);
    if (response.statusCode == 400 &&
        ApiResponseHelpers.isEmptySearchResult(backendMessage)) {
      return [];
    }

    throw ApiException(
      statusCode: response.statusCode,
      userMessage: backendMessage ??
          'No pudimos buscar platos. Intentalo más tarde.',
      debugInfo: response.body,
    );
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

  Future<List<LocalModel>> listarLocales({LocalListFilter? filter}) =>
      _dataSource.listarLocales(filter: filter);

  Future<LocalModel?> obtenerLocal(int id) async {
    final locales = await _dataSource.listarLocales();
    for (final local in locales) {
      if (local.id == id) return local;
    }
    return null;
  }

  Future<List<PlatoModel>> platosDeLocal(int localId) =>
      _dataSource.listarPlatosDeLocal(localId);

  Future<List<PlatoBusquedaItem>> buscarPlatos(BusquedaPlatosFilter filter) =>
      _dataSource.buscarPlatos(filter);
}
