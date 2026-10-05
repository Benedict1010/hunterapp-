import 'dart:convert';

enum ApiErrorType {
  badRequest, // 400
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  conflict, // 409
  validationError, // 422
  serverError, // 500+
  networkError, // connection/socket failure
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
  });

  String get userFriendlyMessage {
    switch (type) {
      case ApiErrorType.unauthorized:
        return message.isNotEmpty ? message : 'Invalid email or password.';
      case ApiErrorType.forbidden:
        return 'Access denied. You do not have permission.';
      case ApiErrorType.notFound:
        return 'The requested resource was not found.';
      case ApiErrorType.conflict:
        return message.isNotEmpty ? message : 'A conflict occurred.';
      case ApiErrorType.validationError:
        return _formatValidationError(details) ??
            (message.isNotEmpty ? message : 'Validation error.');
      case ApiErrorType.badRequest:
        return message.isNotEmpty ? message : 'Bad request.';
      case ApiErrorType.serverError:
        return 'Server error. Please try again later.';
      case ApiErrorType.networkError:
        return 'Network error. Please check your connection and ensure the server is running.';
      case ApiErrorType.unknown:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }

  static String? _formatValidationError(dynamic details) {
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map && first.containsKey('msg')) {
        final loc = first['loc'] as List?;
        final field = (loc != null && loc.length > 1) ? loc.last : null;
        if (field != null) {
          return '$field: ${first['msg']}';
        }
        return first['msg'].toString();
      }
    }
    return null;
  }

  factory ApiException.fromStatusCode(int statusCode, String responseBody) {
    dynamic details;
    String message = 'HTTP Error $statusCode';

    try {
      if (responseBody.isNotEmpty) {
        final json = jsonDecode(responseBody);
        if (json is Map<String, dynamic>) {
          if (json.containsKey('detail')) {
            final detail = json['detail'];
            if (detail is String) {
              message = detail;
            } else if (detail is List) {
              details = detail;
              message = 'Validation error';
            }
          } else if (json.containsKey('message')) {
            message = json['message'].toString();
          }
        }
      }
    } catch (_) {}

    switch (statusCode) {
      case 400:
        return ApiException(
          type: ApiErrorType.badRequest,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      case 401:
        return ApiException(
          type: ApiErrorType.unauthorized,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      case 403:
        return ApiException(
          type: ApiErrorType.forbidden,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      case 404:
        return ApiException(
          type: ApiErrorType.notFound,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      case 409:
        return ApiException(
          type: ApiErrorType.conflict,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      case 422:
        return ApiException(
          type: ApiErrorType.validationError,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      default:
        if (statusCode >= 500) {
          return ApiException(
            type: ApiErrorType.serverError,
            message: message,
            statusCode: statusCode,
            details: details,
          );
        }
        return ApiException(
          type: ApiErrorType.unknown,
          message: message,
          statusCode: statusCode,
          details: details,
        );
    }
  }

  @override
  String toString() =>
      'ApiException($type, statusCode: $statusCode, message: $message)';
}
