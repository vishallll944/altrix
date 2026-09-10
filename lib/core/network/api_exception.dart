import 'package:dio/dio.dart';

String? extractApiErrorCode(dynamic data) {
  if (data is! Map) return null;
  final error = data['error'];
  if (error is Map) {
    final code = error['code'];
    if (code != null && code.toString().trim().isNotEmpty) {
      return code.toString().trim();
    }
  }
  final code = data['code'];
  if (code != null && code.toString().trim().isNotEmpty) {
    return code.toString().trim();
  }
  return null;
}

String? extractApiErrorMessage(dynamic data) {
  if (data is! Map) return null;

  final error = data['error'];
  if (error is String && error.trim().isNotEmpty) {
    return error.trim();
  }

  if (error is Map) {
    final msg = error['message'] ?? error['error'] ?? error['detail'];
    if (msg is String && msg.trim().isNotEmpty) {
      final fields = error['fields'] ?? error['details'];
      if (fields is Map && fields.isNotEmpty) {
        final fieldErrors = fields.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        if (fieldErrors.isNotEmpty) {
          return '$msg ($fieldErrors)';
        }
      }
      return msg.trim();
    }
  }

  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }

  final nestedData = data['data'];
  if (nestedData is Map) {
    final nested = nestedData['error'] ?? nestedData['message'];
    if (nested is String && nested.trim().isNotEmpty) {
      return nested.trim();
    }
    if (nested is Map) {
      final msg = nested['message'] ?? nested['error'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
  }

  return null;
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  bool get isValidationError => code == 'VALIDATION_ERROR';
  bool get isUnauthorized =>
      statusCode == 401 || code == 'UNAUTHORIZED' || code == 'AUTH_REQUIRED';
  bool get isNotFound => statusCode == 404 || code == 'NOT_FOUND';

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map) {
      final apiMessage = extractApiErrorMessage(data);
      final apiCode = extractApiErrorCode(data);
      if (apiMessage != null && apiMessage.isNotEmpty) {
        return ApiException(
          apiMessage,
          statusCode: response?.statusCode,
          code: apiCode,
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Request timed out. Try again.');
      case DioExceptionType.connectionError:
        return const ApiException('No internet connection.');
      default:
        return ApiException(
          'Something went wrong. Please try again.',
          statusCode: response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
