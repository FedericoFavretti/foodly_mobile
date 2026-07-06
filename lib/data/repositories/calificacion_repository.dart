import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/calificacion_detalle_model.dart';
import '../models/calificacion_global_model.dart';
import '../models/mi_calificacion_local_model.dart';

class CalificacionRepository {
  CalificacionRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Devuelve la calificación existente o `null` si el backend responde 204.
  Future<MiCalificacionLocalModel?> obtenerMiCalificacion(int localId) async {
    try {
      final response = await _api.get(
        ApiConstants.miCalificacionLocalEndpoint(localId),
        requiresAuth: true,
      );

      if (response.statusCode == 204 ||
          response.body.isEmpty ||
          response.body == 'null') {
        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MiCalificacionLocalModel.fromJson(data);
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No pudimos consultar tu calificación. Intentalo más tarde.',
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

  Future<void> calificarLocal({
    required int localId,
    required int puntaje,
    String? comentario,
  }) async {
    if (puntaje < 1 || puntaje > 5) {
      throw const ApiException(
        statusCode: 400,
        userMessage: 'El puntaje debe estar comprendido entre 1 y 5.',
      );
    }

    final body = <String, dynamic>{
      'puntaje': puntaje,
      'comentario': comentario?.trim() ?? '',
      'dtLocal': {'id': localId},
    };

    try {
      final response = await _api.post(
        ApiConstants.calificacionEndpoint,
        body,
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) return;

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No pudimos registrar tu calificación. Intentalo más tarde.',
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

  /// Calificaciones que los locales dejaron sobre este cliente (CU-CL11).
  /// Devuelve `null` si aún no recibió ninguna.
  Future<CalificacionGlobalModel?> obtenerCalificacionRecibida(
    int clienteId,
  ) async {
    try {
      final response = await _api.get(
        ApiConstants.calificacionGlobalClienteEndpoint(clienteId),
        requiresAuth: true,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CalificacionGlobalModel.fromJson(data);
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        final message = _mapErrorMessage(response.body)?.toLowerCase() ?? '';
        if (message.contains('no ha recibido') ||
            message.contains('sin calificaciones')) {
          return null;
        }
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No pudimos cargar tu calificación. Intentalo más tarde.',
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

  Future<List<CalificacionDetalleModel>> obtenerDetalleCalificacionRecibida(
    int clienteId,
  ) async {
    try {
      final response = await _api.get(
        ApiConstants.calificacionDetalleClienteEndpoint(clienteId),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return [];
        final decoded = jsonDecode(response.body);
        if (decoded is! List) return [];
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(CalificacionDetalleModel.fromJson)
            .toList();
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No pudimos cargar el detalle de calificaciones.',
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
        final message =
            decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}

    if (body.length < 300 && !body.contains('<html')) return body;
    return null;
  }
}
