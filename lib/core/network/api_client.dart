import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final ApiConfig apiConfig;
  final TokenStorage tokenStorage;
  final http.Client _client;

  ApiClient({
    ApiConfig? apiConfig,
    TokenStorage? tokenStorage,
    http.Client? client,
  }) : apiConfig = apiConfig ?? const ApiConfig(),
       tokenStorage = tokenStorage ?? InMemoryTokenStorage(),
       _client = client ?? http.Client();

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? customHeaders,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?customHeaders,
    };

    final token = await tokenStorage.getToken();
    if (token != null &&
        token.isNotEmpty &&
        !headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = apiConfig.uri(path, queryParameters);
    final requestHeaders = await _buildHeaders(headers);

    return _send(() => _client.get(uri, headers: requestHeaders));
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = apiConfig.uri(path);
    final requestHeaders = await _buildHeaders(headers);
    final requestBody = _encodeBody(body, requestHeaders['Content-Type']);

    return _send(
      () => _client.post(uri, headers: requestHeaders, body: requestBody),
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = apiConfig.uri(path);
    final requestHeaders = await _buildHeaders(headers);
    final requestBody = _encodeBody(body, requestHeaders['Content-Type']);

    return _send(
      () => _client.patch(uri, headers: requestHeaders, body: requestBody),
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = apiConfig.uri(path);
    final requestHeaders = await _buildHeaders(headers);
    final requestBody = _encodeBody(body, requestHeaders['Content-Type']);

    return _send(
      () => _client.put(uri, headers: requestHeaders, body: requestBody),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = apiConfig.uri(path);
    final requestHeaders = await _buildHeaders(headers);
    final requestBody = _encodeBody(body, requestHeaders['Content-Type']);

    return _send(
      () => _client.delete(uri, headers: requestHeaders, body: requestBody),
    );
  }

  Object? _encodeBody(Object? body, String? contentType) {
    if (body == null) return null;
    if (body is String) return body;
    if (contentType != null && contentType.contains('application/json')) {
      return jsonEncode(body);
    }
    return body;
  }

  Future<dynamic> _send(Future<http.Response> Function() requestCall) async {
    try {
      final response = await requestCall().timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        type: ApiErrorType.networkError,
        message: 'Could not connect to host: ${e.message}',
      );
    } on TimeoutException {
      throw const ApiException(
        type: ApiErrorType.networkError,
        message: 'Request timed out.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        type: ApiErrorType.networkError,
        message: 'Network client error: ${e.message}',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(type: ApiErrorType.unknown, message: e.toString());
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    throw ApiException.fromStatusCode(statusCode, body);
  }
}
