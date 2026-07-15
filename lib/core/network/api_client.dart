import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/session/session_manager.dart';
import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Base URL sin slash final para evitar doble slash al concatenar endpoints.
  static String get _baseUrl {
    final url = ApiConstants.baseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParameters,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint')
          .replace(queryParameters: queryParameters);
      return _client.get(uri, headers: headers);
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
    Map<String, String>? queryParameters,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint')
          .replace(queryParameters: queryParameters);
      return _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    }, requiresAuth: requiresAuth);
  }

  /// POST sin body (p. ej. activación con query params).
  Future<http.Response> postEmpty(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint')
          .replace(queryParameters: queryParameters);
      return _client.post(uri, headers: headers);
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return _execute(() async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint');
      return _client.delete(uri, headers: headers);
    }, requiresAuth: requiresAuth);
  }

  Future<http.Response> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    bool requiresAuth = false,
  }) async {
    return _multipart(
      method: 'POST',
      endpoint: endpoint,
      fields: fields,
      files: files,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> putMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    bool requiresAuth = true,
  }) async {
    return _multipart(
      method: 'PUT',
      endpoint: endpoint,
      fields: fields,
      files: files,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> _multipart({
    required String method,
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    required bool requiresAuth,
  }) async {
    return _execute(() async {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest(method, uri);
      final headers = await _buildHeaders(
        requiresAuth: requiresAuth,
        jsonContentType: false,
      );
      request.headers.addAll(headers);
      request.fields.addAll(fields);
      request.files.addAll(files.values);
      final streamed = await _sendMultipart(request);
      return http.Response.fromStream(streamed);
    }, requiresAuth: requiresAuth);
  }

  Future<http.StreamedResponse> _sendMultipart(
    http.MultipartRequest request,
  ) async {
    if (_client case final http.BaseClient baseClient) {
      return baseClient.send(request).timeout(
        const Duration(seconds: ApiConstants.timeoutSeconds),
      );
    }
    return request.send().timeout(
      const Duration(seconds: ApiConstants.timeoutSeconds),
    );
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
      // Permite al backend distinguir solicitudes mobile de web y usar
      // las URLs de retorno de Mercado Pago correctas (foodly:// vs https://).
      'X-Foodly-Client': 'mobile',
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
