import 'dart:convert';

import '../../core/errors/api_exception.dart';
import '../../domain/session/session_manager.dart';
import '../models/cliente_profile_model.dart';
import '../models/usuario_info_model.dart';

class ClienteProfileRepository {
  Future<ClienteProfileModel> fetchAndCache() async {
    final profile = await _fromSession();
    if (profile == null) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'No pudimos cargar tu perfil. Volvé a iniciar sesión.',
      );
    }
    await SessionManager.saveProfileJson(jsonEncode(profile.toJson()));
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

  Future<ClienteProfileModel> getOrFetch() async {
    final cached = await getCached();
    if (cached != null) return cached;
    return fetchAndCache();
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
