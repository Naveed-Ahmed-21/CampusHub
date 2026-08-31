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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If connection error (e.g. adb reverse was dropped or network route changed)
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.response == null) {
      for (final candidate in ApiEndpoints.candidateUrls) {
        if (candidate != ApiEndpoints.baseUrl) {
          try {
            final testDio = Dio(BaseOptions(
              connectTimeout: const Duration(milliseconds: 2000),
            ));
            final ping = await testDio.get('$candidate/health');
            if (ping.statusCode == 200) {
              ApiEndpoints.setBaseUrl(candidate);
              final reqOptions = err.requestOptions;
              reqOptions.baseUrl = candidate;
              final retryRes = await testDio.fetch(reqOptions);
              return handler.resolve(retryRes);
            }
          } catch (_) {}
        }
      }
    }
    handler.next(err);
  }
}

final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  final options = BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
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
