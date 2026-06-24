import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/session/session_manager.dart';
import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      return _client.get(uri, headers: headers);
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      return _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      return _client.delete(uri, headers: headers);
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    bool requiresAuth = false,
  }) async {
    return _execute(() async {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final headers = await _buildHeaders(
        requiresAuth: requiresAuth,
        jsonContentType: false,
      );
      request.headers.addAll(headers);
      request.fields.addAll(fields);
      request.files.addAll(files.values);
      final streamed = await request.send().timeout(
        const Duration(seconds: ApiConstants.timeoutSeconds),
      );
      return http.Response.fromStream(streamed);
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> _execute(
    Future<http.Response> Function() call, {
    required bool requiresAuth,
  }) async {
    try {
      final response = await call().timeout(
        const Duration(seconds: ApiConstants.timeoutSeconds),
      );
      if (requiresAuth && response.statusCode == 401) {
        await SessionManager.clearSession();
        throw const SessionExpiredException();
      }
      return response;
    } on SessionExpiredException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }

  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
    bool jsonContentType = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (requiresAuth) {
      final token = await SessionManager.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }
}
