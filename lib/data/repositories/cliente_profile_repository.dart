import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/session/session_manager.dart';
import '../models/cliente_profile_model.dart';

class ClienteProfileRepository {
  ClienteProfileRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<ClienteProfileModel> fetchAndCache() async {
    final profile = await fetch();
    await SessionManager.saveProfileJson(jsonEncode(profile.toJson()));
    return profile;
  }

  Future<ClienteProfileModel> fetch() async {
    try {
      final response = await _api.get(
        ApiConstants.perfilClienteEndpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ClienteProfileModel.fromJson(data);
      }

      throw ApiException(
        statusCode: response.statusCode,
        userMessage: 'No pudimos cargar tu perfil. Intentalo más tarde.',
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
}
