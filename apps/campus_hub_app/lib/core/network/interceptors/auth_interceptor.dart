import 'dart:async';
import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../../constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    if (!path.contains('/auth/login') &&
        !path.contains('/auth/register') &&
        !path.contains('/auth/forgot-password')) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    // Avoid recursion if failure was from auth endpoints
    if (path.contains('/auth/refresh') ||
        path.contains('/auth/login') ||
        path.contains('/auth/register')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      if (_refreshCompleter != null) {
        // A refresh is already in progress: wait for it to complete
        try {
          final newAccessToken = await _refreshCompleter!.future;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final clonedRequest = await _dio.fetch(opts);
            return handler.resolve(clonedRequest);
          }
        } catch (_) {
          return handler.next(err);
        }
        return handler.next(err);
      }

      // First request that encountered 401 initiates the refresh
      _refreshCompleter = Completer<String?>();
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final response = await _dio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken, 'refresh_token': refreshToken},
          );
          final resData = response.data is Map ? (response.data['data'] ?? response.data) : response.data;
          final newAccessToken = (resData['accessToken'] ?? resData['access_token']) as String?;
          final newRefreshToken = (resData['refreshToken'] ?? resData['refresh_token']) as String?;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await _storage.saveAccessToken(newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _storage.saveRefreshToken(newRefreshToken);
            }

            final completer = _refreshCompleter;
            _refreshCompleter = null;
            completer?.complete(newAccessToken);

            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final clonedRequest = await _dio.fetch(opts);
            return handler.resolve(clonedRequest);
          } else {
            await _storage.clearAll();
            final completer = _refreshCompleter;
            _refreshCompleter = null;
            completer?.complete(null);
          }
        } catch (_) {
          await _storage.clearAll();
          final completer = _refreshCompleter;
          _refreshCompleter = null;
          completer?.complete(null);
        }
      } else {
        final completer = _refreshCompleter;
        _refreshCompleter = null;
        completer?.complete(null);
      }
    }
    return handler.next(err);
  }
}
