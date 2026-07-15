import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/session/session_manager.dart';
import '../models/cliente_profile_model.dart';
import '../models/direccion_model.dart';
import '../models/usuario_info_model.dart';

class ActualizarPerfilData {
  const ActualizarPerfilData({
    required this.nombre,
    required this.apellido,
    required this.calle,
    required this.numero,
    required this.ciudad,
    required this.codigoPostal,
    this.celular,
    this.fotoBytes,
    this.fotoFilename,
  });

  final String nombre;
  final String apellido;
  final String calle;
  final String numero;
  final String ciudad;
  final String codigoPostal;
  /// E.164 completo (ej. `+598991234567`). Si viene vacío no se manda la
  /// clave al backend (mandar `""` rompe la validación del lado servidor).
  final String? celular;
  final List<int>? fotoBytes;
  final String? fotoFilename;
}

class ClienteProfileRepository {
  ClienteProfileRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<ClienteProfileModel> fetchAndCache() async {
    final profile = await _fetchProfile();
    if (_tieneDatosCompletos(profile)) {
      await SessionManager.saveProfileJson(jsonEncode(profile.toJson()));
    }
    return profile;
  }

  Future<ClienteProfileModel> fetch() => fetchAndCache();

  Future<ClienteProfileModel?> getCached() async {
    final json = await SessionManager.getProfileJson();
    if (json == null || json.isEmpty) return null;
    try {
      return ClienteProfileModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Intenta traer datos frescos del backend; si falla, usa caché con datos reales.
  Future<ClienteProfileModel> getOrFetch() async {
    try {
      return await fetchAndCache();
    } on ApiException {
      final cached = await getCached();
      if (cached != null && _tieneDatosCompletos(cached)) {
        return cached;
      }
      rethrow;
    }
  }

  /// Actualiza perfil del cliente autenticado y refresca caché local.
  Future<ClienteProfileModel> actualizarPerfil(ActualizarPerfilData data) async {
    if (!await SessionManager.hasSession()) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'Tu sesión expiró. Volvé a iniciar sesión.',
      );
    }

    try {
      // El backend espera un @RequestPart "datos" con JSON anidado,
      // no campos planos de formulario.
      final celular = data.celular?.trim();
      final datosJson = jsonEncode({
        'nombre': data.nombre.trim(),
        'apellido': data.apellido.trim(),
        'direccion': {
          'calle': data.calle.trim(),
          'numero': data.numero.trim(),
          'ciudad': data.ciudad.trim(),
          'codigoPostal': data.codigoPostal.trim(),
        },
        if (celular != null && celular.isNotEmpty) 'celular': celular,
      });

      final files = <String, http.MultipartFile>{
        'datos': http.MultipartFile.fromString(
          'datos',
          datosJson,
          contentType: MediaType('application', 'json'),
        ),
      };

      if (data.fotoBytes != null && data.fotoBytes!.isNotEmpty) {
        files['foto'] = http.MultipartFile.fromBytes(
          'foto',
          data.fotoBytes!,
          filename: data.fotoFilename ?? 'foto.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
      }

      final response = await _api.putMultipart(
        endpoint: ApiConstants.perfilEndpoint,
        fields: const {},
        files: files,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return _parseAndCacheProfileResponse(response.body);
      }

      // Compatibilidad con backends que aún respondían 204 sin body.
      if (response.statusCode == 204) {
        return _aplicarActualizacionLocal(data);
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: _mapErrorMessage(response.body) ??
            'No pudimos actualizar tu perfil. Intentalo más tarde.',
        debugInfo: response.body,
      );
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
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

  /// Parsea `DtCliente` devuelto por `PUT /usuarios/perfil` y persiste en sesión.
  Future<ClienteProfileModel> _parseAndCacheProfileResponse(String body) async {
    if (body.isEmpty) {
      throw const ApiException(
        statusCode: 200,
        userMessage: 'El servidor no devolvió los datos actualizados del perfil.',
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Respuesta de perfil inválida');
      }

      final profile = ClienteProfileModel.fromJson(decoded);
      await SessionManager.saveProfileJson(jsonEncode(profile.toJson()));
      return profile;
    } on FormatException {
      throw ApiException(
        statusCode: 200,
        userMessage: 'No pudimos interpretar la respuesta del perfil.',
        debugInfo: body,
      );
    }
  }

  /// Fallback si el backend responde 204 sin body (versiones anteriores).
  Future<ClienteProfileModel> _aplicarActualizacionLocal(
    ActualizarPerfilData data,
  ) async {
    final base = await getCached() ?? await _fromSession();
    if (base == null) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'No pudimos actualizar tu perfil. Volvé a iniciar sesión.',
      );
    }

    final updated = base.copyWith(
      nombre: data.nombre.trim(),
      apellido: data.apellido.trim(),
      direccion: DireccionModel(
        calle: data.calle.trim(),
        numero: data.numero.trim(),
        ciudad: data.ciudad.trim(),
        codigoPostal: data.codigoPostal.trim(),
      ),
    );

    await SessionManager.saveProfileJson(jsonEncode(updated.toJson()));
    return updated;
  }

  Future<ClienteProfileModel> _fetchProfile() async {
    if (!await SessionManager.hasSession()) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'No pudimos cargar tu perfil. Volvé a iniciar sesión.',
      );
    }

    try {
      final response = await _api.get(
        ApiConstants.perfilEndpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ClienteProfileModel.fromJson(data);
      }
    } on SessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (_) {
      // GET /perfil no disponible en el backend actual.
    }

    final cached = await getCached();
    if (cached != null && _tieneDatosCompletos(cached)) {
      return cached;
    }

    final fromSession = await _fromSession();
    if (fromSession == null) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'No pudimos cargar tu perfil. Volvé a iniciar sesión.',
      );
    }
    return fromSession;
  }

  bool _tieneDatosCompletos(ClienteProfileModel profile) {
    return profile.nombre.trim().isNotEmpty ||
        profile.apellido.trim().isNotEmpty ||
        profile.tieneFoto ||
        profile.direccion != null;
  }

  Future<ClienteProfileModel?> _fromSession() async {
    final usuarioJson = await SessionManager.getUsuarioInfoJson();
    if (usuarioJson == null) return null;
    try {
      final usuario = UsuarioInfoModel.fromJson(
        jsonDecode(usuarioJson) as Map<String, dynamic>,
      );
      return ClienteProfileModel(
        id: usuario.id,
        email: usuario.email,
        nombre: '',
        apellido: '',
      );
    } catch (_) {
      return null;
    }
  }
}
