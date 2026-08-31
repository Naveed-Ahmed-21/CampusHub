import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';

enum ServerConnectionState { checking, connected, offline }

class ServerStatus {
  final ServerConnectionState state;
  final String activeUrl;
  final String? errorMessage;

  const ServerStatus({
    required this.state,
    required this.activeUrl,
    this.errorMessage,
  });

  bool get isConnected => state == ServerConnectionState.connected;
}

class ServerHealthService extends StateNotifier<ServerStatus> {
  ServerHealthService()
      : super(ServerStatus(
          state: ServerConnectionState.connected,
          activeUrl: ApiEndpoints.baseUrl,
        ));

  Future<bool> pingUrl(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(milliseconds: 2000),
        receiveTimeout: const Duration(milliseconds: 2000),
      ));
      final res = await dio.get('$url/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkHealth([String? specificUrl]) async {
    state = ServerStatus(
      state: ServerConnectionState.checking,
      activeUrl: specificUrl ?? ApiEndpoints.baseUrl,
    );

    final targetUrl = specificUrl ?? ApiEndpoints.baseUrl;
    final isOk = await pingUrl(targetUrl);

    if (isOk) {
      ApiEndpoints.setBaseUrl(targetUrl);
      state = ServerStatus(
        state: ServerConnectionState.connected,
        activeUrl: targetUrl,
      );
      return;
    }

    // Auto-discover candidate fallback URLs
    for (final candidate in ApiEndpoints.candidateUrls) {
      if (candidate == targetUrl) continue;
      final candidateOk = await pingUrl(candidate);
      if (candidateOk) {
        ApiEndpoints.setBaseUrl(candidate);
        state = ServerStatus(
          state: ServerConnectionState.connected,
          activeUrl: candidate,
        );
        return;
      }
    }

    state = ServerStatus(
      state: ServerConnectionState.offline,
      activeUrl: targetUrl,
      errorMessage: 'Cannot connect to backend server. Check that backend is running.',
    );
  }

  Future<void> setCustomUrl(String customUrl) async {
    final cleanUrl = customUrl.trim().endsWith('/')
        ? customUrl.trim().substring(0, customUrl.trim().length - 1)
        : customUrl.trim();
    await checkHealth(cleanUrl);
  }
}

final serverHealthServiceProvider =
    StateNotifierProvider<ServerHealthService, ServerStatus>((ref) {
  return ServerHealthService();
});
