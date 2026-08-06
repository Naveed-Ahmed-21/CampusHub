import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorData;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorData,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(message: 'Connection timed out. Please try again.');
      case DioExceptionType.badResponse:
        final code = dioException.response?.statusCode;
        final data = dioException.response?.data;
        final msg = data is Map ? data['message'] ?? 'Server error' : 'Server error ($code)';
        return ApiException(message: msg, statusCode: code, errorData: data);
      case DioExceptionType.connectionError:
        return const ApiException(message: 'No internet connection available.');
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      default:
        return ApiException(message: dioException.message ?? 'An unexpected error occurred.');
    }
  }

  @override
  String toString() => message;
}
