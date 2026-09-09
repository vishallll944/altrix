import 'package:dio/dio.dart';

String? extractApiErrorMessage(dynamic data) {
  if (data is! Map<String, dynamic>) return null;
  final error = data['error'] ?? data['message'];
  if (error is String && error.isNotEmpty) {
    return error;
  }

  if (error is Map) {
    final msg = error['message'] ?? error['error'];
    if (msg is String && msg.isNotEmpty) {
      final fields = error['fields'];
      if (fields is Map && fields.isNotEmpty) {
        final fieldErrors = fields.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        if (fieldErrors.isNotEmpty) {
          return '$msg ($fieldErrors)';
        }
      }
      return msg;
    }
  }

  final nestedData = data['data'];
  if (nestedData is Map<String, dynamic>) {
    final nested = nestedData['error'] ?? nestedData['message'];
    if (nested is String && nested.isNotEmpty) {
      return nested;
    }
    if (nested is Map) {
      final msg = nested['message'] ?? nested['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
  }

  return null;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final apiMessage = extractApiErrorMessage(data);
      if (apiMessage != null && apiMessage.isNotEmpty) {
        return ApiException(apiMessage, statusCode: response?.statusCode);
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
