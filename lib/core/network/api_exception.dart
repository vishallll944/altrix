import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final apiMessage = data['message'] ?? data['error'];
      if (apiMessage is String && apiMessage.isNotEmpty) {
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
