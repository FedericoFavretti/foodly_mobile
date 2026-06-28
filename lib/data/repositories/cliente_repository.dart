import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/session/session_manager.dart';

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
    this.fotoBytes,
    this.fotoFilename,
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
  final List<int>? fotoBytes;
  final String? fotoFilename;
}

class ClienteRepository {
  ClienteRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// JPEG mínimo válido por si el backend exige la parte `foto`.
  static const _placeholderJpegBytes = <int>[
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x03, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
    0x7F, 0xFF, 0xD9,
  ];

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

      // Construir files map - foto es opcional
      final files = <String, http.MultipartFile>{
        'datos': http.MultipartFile.fromString(
          'datos',
          datosJson,
          contentType: MediaType('application', 'json'),
        ),
      };

      final fotoBytes = data.fotoBytes ?? _placeholderJpegBytes;
      files['foto'] = http.MultipartFile.fromBytes(
        'foto',
        fotoBytes,
        filename: data.fotoFilename ?? 'foto.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      final response = await _api.postMultipart(
        endpoint: ApiConstants.registroEndpoint,
        fields: const {},
        files: files,
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

  /// Elimina la cuenta del cliente autenticado.
  /// Endpoint: `DELETE /api/v1/usuarios/mi-cuenta`
  Future<void> eliminarCuenta() async {
    if (!await SessionManager.hasSession()) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'Tu sesión expiró. Volvé a iniciar sesión.',
      );
    }

    try {
      final response = await _api.delete(
        ApiConstants.eliminarCuentaEndpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) return;

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: 'No se pudo eliminar la cuenta. Intentalo más tarde.',
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
        final message = decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    if (body.length < 200 && !body.contains('<html')) return body;
    return null;
  }
}
