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
       tokenStorage = tokenStorage ?? InMemoryTokenStorage('test_token'),
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

  Future<List<int>> getBytes(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = apiConfig.uri(path, queryParameters);
    final requestHeaders = await _buildHeaders(headers);
    requestHeaders.remove('Content-Type');

    try {
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      _handleResponse(response);
      return response.bodyBytes;
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

  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    String? fileName,
    List<int>? bytes,
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) async {
    return _sendMultipart(
      'POST',
      path,
      fileField: fileField,
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
      headers: headers,
      fields: fields,
    );
  }

  Future<dynamic> putMultipart(
    String path, {
    required String fileField,
    required String filePath,
    String? fileName,
    List<int>? bytes,
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) async {
    return _sendMultipart(
      'PUT',
      path,
      fileField: fileField,
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
      headers: headers,
      fields: fields,
    );
  }

  Future<dynamic> _sendMultipart(
    String method,
    String path, {
    required String fileField,
    required String filePath,
    String? fileName,
    List<int>? bytes,
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) async {
    final uri = apiConfig.uri(path);
    final request = http.MultipartRequest(method, uri);

    final baseHeaders = await _buildHeaders(headers);
    baseHeaders.remove('Content-Type');
    request.headers.addAll(baseHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (bytes != null && bytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: fileName ??
              (filePath.isNotEmpty
                  ? filePath.split(Platform.pathSeparator).last
                  : 'upload.file'),
        ),
      );
    } else if (filePath.isNotEmpty) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const ApiException(
          type: ApiErrorType.validationError,
          message: 'File not found at specified path.',
        );
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
          filename: fileName,
        ),
      );
    } else {
      throw const ApiException(
        type: ApiErrorType.validationError,
        message: 'No file path or byte content provided for upload.',
      );
    }

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
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
      final response = await requestCall().timeout(
        const Duration(seconds: 5),
      );
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
