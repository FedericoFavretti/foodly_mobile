import 'dart:convert';

import '../models/notificacion_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class NotificacionRepository {
  NotificacionRepository(this._api);

  final ApiClient _api;

  Future<List<NotificacionModel>> listarMias() async {
    final response = await _api.get(
      ApiConstants.notificacionesMiasEndpoint,
      requiresAuth: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar notificaciones: ${response.statusCode}');
    }

    if (response.body.isEmpty || response.body == 'null') return [];

    final dynamic decoded = jsonDecode(response.body);

    List<dynamic> lista;
    if (decoded is List) {
      lista = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded.containsKey('content')) {
      lista = decoded['content'] as List;
    } else if (decoded is Map<String, dynamic> &&
        decoded.containsKey('contenido')) {
      lista = decoded['contenido'] as List;
    } else {
      return [];
    }

    return lista
        .cast<Map<String, dynamic>>()
        .map(NotificacionModel.fromJson)
        .toList();
  }

  Future<void> marcarLeida(int id) async {
    await _api.post(
      ApiConstants.notificacionLeidaEndpoint(id),
      const <String, dynamic>{},
      requiresAuth: true,
    );
  }
}
