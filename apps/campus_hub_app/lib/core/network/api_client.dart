import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DynamicHostInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.baseUrl = ApiEndpoints.baseUrl;
    handler.next(options);
  }
}

final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  final options = BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 45),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  dio.interceptors.addAll([
    DynamicHostInterceptor(),
    AuthInterceptor(secureStorage, dio),
    LoggingInterceptor(),
  ]);

  return dio;
});
