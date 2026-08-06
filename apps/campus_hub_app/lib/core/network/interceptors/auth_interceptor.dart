import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../../constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  bool _isRefreshing = false;

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
    // Avoid recursion if failure was from auth endpoints or if already refreshing
    if (path.contains('/auth/refresh') || path.contains('/auth/login') || path.contains('/auth/register')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
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

            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            _isRefreshing = false;
            final clonedRequest = await _dio.fetch(opts);
            return handler.resolve(clonedRequest);
          } else {
            await _storage.clearAll();
          }
        } catch (_) {
          await _storage.clearAll();
        } finally {
          _isRefreshing = false;
        }
      } else {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }
}
