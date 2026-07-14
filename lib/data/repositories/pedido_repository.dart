import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/cart/cart_item.dart';
import '../../domain/pedido/medio_pago.dart';
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
    required MedioPago medioPago,
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
      'dtPedido': {
        'dtLocal': {'id': localId},
        'dtCliente': {'id': clienteId},
        'domicilioEntrega': {
          'calle': domicilio.calle,
          'numero': domicilio.numero,
          'ciudad': domicilio.ciudad,
          'codigoPostal': domicilio.codigoPostal ?? '',
        },
        'medioDePago': medioPago.apiValue,
        'pagoSimulado': false,
      },
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

  Future<PedidoResponseModel> obtenerPedido(int pedidoId) async {
    try {
      final response = await _api.get(
        ApiConstants.pedidoByIdEndpoint(pedidoId),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return PedidoResponseModel.fromJson(decoded);
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No se pudo obtener el pedido.',
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',
        debugInfo: error.toString(),
      );
    }
  }

  Future<List<PedidoResponseModel>> listarHistorial({String? estado}) async {
    try {
      final queryParameters = estado != null && estado.trim().isNotEmpty
          ? {'estado': estado.trim()}
          : null;

      final response = await _api.get(
        ApiConstants.historialPedidosEndpoint,
        requiresAuth: true,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return [];
        final decoded = jsonDecode(response.body);
        if (decoded == null) return [];

        // El backend devuelve DtPagina<DtPedidoListadoResponse>
        final rawList = decoded is Map<String, dynamic>
            ? decoded['contenido']
            : decoded;

        if (rawList is! List) return [];
        return rawList
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

  /// Reinicia el proceso de pago de un pedido MP fallido / pendiente.
  /// Devuelve el pedido actualizado con un nuevo `mpInitPoint`.
  /// Endpoint: `POST /pedidos/{id}/reintentar-pago`
  Future<PedidoResponseModel> reintentarPago(int pedidoId) async {
    try {
      final response = await _api.post(
        ApiConstants.reintentarPagoEndpoint(pedidoId),
        const <String, dynamic>{},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') {
          throw const ApiException(
            statusCode: 200,
            userMessage: 'No se pudo obtener el link de pago.',
          );
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return PedidoResponseModel.fromJson(decoded);
      }

      final backendMessage = _mapErrorMessage(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        userMessage: backendMessage ??
            'No se pudo reintentar el pago. Intentalo más tarde.',
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
        ApiConstants.cancelarPedidoEndpoint(pedidoId),
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
        final message = decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}

    if (body.length < 300 && !body.contains('<html')) return body;
    return null;
  }
}
