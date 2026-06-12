import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';

class RegistroClienteData {
  const RegistroClienteData({
    required this.email,
    required this.password,
    required this.documento,
    required this.nombre,
    required this.apellido,
    required this.calle,
    required this.numero,
    required this.ciudad,
    required this.codigoPostal,
    required this.fotoBytes,
    required this.fotoFilename,
  });

  final String email;
  final String password;
  final String documento;
  final String nombre;
  final String apellido;
  final String calle;
  final String numero;
  final String ciudad;
  final String codigoPostal;
  final List<int> fotoBytes;
  final String fotoFilename;
}

class ClienteRepository {
  ClienteRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<void> registrar(RegistroClienteData data) async {
    try {
      final datosJson = jsonEncode({
        'email': data.email.trim(),
        'passwd': data.password,
        'documento': data.documento.replaceAll(RegExp(r'\D'), ''),
        'nombre': data.nombre.trim(),
        'apellido': data.apellido.trim(),
        'direccion': {
          'calle': data.calle.trim(),
          'numero': data.numero.trim(),
          'ciudad': data.ciudad.trim(),
          'codigoPostal': data.codigoPostal.trim(),
        },
      });

      final response = await _api.postMultipart(
        endpoint: ApiConstants.registroEndpoint,
        fields: const {},
        files: {
          'datos': http.MultipartFile.fromString(
            'datos',
            datosJson,
            contentType: MediaType('application', 'json'),
          ),
          'foto': http.MultipartFile.fromBytes(
            'foto',
            data.fotoBytes,
            filename: data.fotoFilename,
          ),
        },
        requiresAuth: false,
      );

      if (response.statusCode == 200) return;

      final message = _extractErrorMessage(response.body) ??
          'No se pudo completar el registro. Intentalo más tarde.';

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: message,
        debugInfo: response.body,
      );
    } on ApiException {
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

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    if (body.length < 200 && !body.contains('<html')) return body;
    return null;
  }
}
