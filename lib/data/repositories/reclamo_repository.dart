import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/reclamo/reclamo_rules.dart';
import '../models/reclamo_listado_model.dart';
import 'pedido_repository.dart';

class ReclamoRepository {
  ReclamoRepository({ApiClient? api, PedidoRepository? pedidoRepository})
      : _api = api ?? ApiClient(),
        _pedidoRepository = pedidoRepository ?? PedidoRepository();

  final ApiClient _api;
  final PedidoRepository _pedidoRepository;

  Future<void> realizarReclamo({
    required int pedidoId,
    required String motivo,
    required String tipoCompensacion,
    double? montoReintegro,
  }) async {
    final body = <String, dynamic>{
      'motivo': motivo.trim(),
      'tipoCompensacion': tipoCompensacion,
      'dtPedido': {'id': pedidoId},
      if (montoReintegro != null) 'montoReintegro': montoReintegro,
    };

    try {
      final response = await _api.post(
        ApiConstants.reclamoEndpoint,
        body,
        requiresAuth: true,
      );

      if (response.statusCode == 200) return;

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No pudimos registrar tu reclamo. Intentalo más tarde.',
        debugInfo: response.body,
      );
    } on ApiException {
      rethrow;
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',
        debugInfo: error.toString(),
      );
    }
  }

  /// Lista reclamos del cliente autenticado (CU-CL09).
  ///
  /// El backend solo expone [miReclamoEndpoint] por pedido; se consulta el
  /// historial y se obtiene el reclamo de cada pedido elegible en paralelo.
  Future<List<ReclamoListadoModel>> listarMisReclamos() async {
    try {
      final pedidos = await _pedidoRepository.listarHistorial();
      final candidatos = pedidos
          .where(
            (pedido) =>
                ReclamoRules.estadoPermiteReclamo(pedido.estado) ||
                pedido.tieneReclamo,
          )
          .toList();

      if (candidatos.isEmpty) return [];

      final reclamos = await Future.wait(
        candidatos.map((pedido) => obtenerReclamoDePedido(pedido.id)),
      );

      final lista = reclamos.whereType<ReclamoListadoModel>().toList()
        ..sort((a, b) {
          final fa = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          final fb = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          return fb.compareTo(fa);
        });

      return lista;
    } on ApiException {
      rethrow;
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',
        debugInfo: error.toString(),
      );
    }
  }

  Future<ReclamoListadoModel?> obtenerReclamoDePedido(int pedidoId) async {
    try {
      final response = await _api.get(
        '${ApiConstants.miReclamoEndpoint}/$pedidoId',
        requiresAuth: true,
      );

      if (response.statusCode == 404) return null;

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return null;
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return null;
        return ReclamoListadoModel.fromJson(decoded);
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: 'No pudimos cargar el reclamo. Intentalo más tarde.',
        debugInfo: response.body,
      );
    } on ApiException {
      rethrow;
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',
        debugInfo: error.toString(),
      );
    }
  }

  String? _mapErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}

    if (body.length < 300 && !body.contains('<html')) return body;
    return null;
  }
}
