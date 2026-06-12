import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/cart/cart_item.dart';
import '../models/direccion_model.dart';
import '../models/pedido_response_model.dart';

class PedidoRepository {
  PedidoRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const sinPlatosMessage =
      'Debe agregar al menos un plato para realizar el pedido.';
  static const cantidadInvalidaMessage =
      'La cantidad debe ser un número entero mayor a cero.';
  static const localCerradoMessage =
      'Lo sentimos, el local seleccionado cerró y no acepta más pedidos por el momento.';

  Future<PedidoResponseModel> realizarPedido({
    required int clienteId,
    required int localId,
    required DireccionModel domicilio,
    required List<CartItem> items,
  }) async {
    if (items.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        userMessage: sinPlatosMessage,
      );
    }

    for (final item in items) {
      if (item.cantidad <= 0) {
        throw const ApiException(
          statusCode: 400,
          userMessage: cantidadInvalidaMessage,
        );
      }
    }

    final body = {
      'dtLocal': {'id': localId},
      'dtCliente': {'id': clienteId},
      'domicilioEntrega': {
        'calle': domicilio.calle,
        'numero': domicilio.numero,
        'ciudad': domicilio.ciudad,
        'codigoPostal': domicilio.codigoPostal ?? '',
      },
      'medioDePago': 'simulado',
      'detalles': items
          .map(
            (item) => {
              'dtPlato': {'id': item.plato.id},
              'cantidad': item.cantidad,
            },
          )
          .toList(),
    };

    try {
      final response = await _api.post(
        ApiConstants.pedidosEndpoint,
        body,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PedidoResponseModel.fromJson(data);
      }

      final userMessage = _mapErrorMessage(response.body) ??
          'No pudimos confirmar tu pedido. Intentalo más tarde.';

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: userMessage,
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

  Future<List<PedidoResponseModel>> listarHistorial() async {
    try {
      final response = await _api.get(
        ApiConstants.historialClienteEndpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return [];
        final decoded = jsonDecode(response.body);
        if (decoded == null) return [];
        if (decoded is! List) return [];
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(PedidoResponseModel.fromJson)
            .toList();
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: 'No pudimos cargar tu historial. Intentalo más tarde.',
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

  Future<void> cancelarPedido(int pedidoId) async {
    try {
      final response = await _api.post(
        '${ApiConstants.pedidosEndpoint}/$pedidoId/cancelar',
        {},
        requiresAuth: true,
      );

      if (response.statusCode == 200) return;

      final userMessage = _mapErrorMessage(response.body) ??
          'No pudimos cancelar el pedido. Intentalo más tarde.';

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: userMessage,
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
    if (body.contains(sinPlatosMessage)) return sinPlatosMessage;
    if (body.contains(cantidadInvalidaMessage)) return cantidadInvalidaMessage;
    if (body.contains(localCerradoMessage)) return localCerradoMessage;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}

    if (body.length < 300 && !body.contains('<html')) return body;
    return null;
  }
}
