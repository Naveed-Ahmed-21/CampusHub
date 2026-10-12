import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

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
  bool get isChecking => state == ServerConnectionState.checking;
  bool get isOffline => state == ServerConnectionState.offline;
}

class ServerHealthService extends StateNotifier<ServerStatus> {
  final SecureStorageService? _storage;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isChecking = false;

  late final Dio _healthDio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 1500),
    receiveTimeout: const Duration(milliseconds: 1500),
  ));

  ServerHealthService([this._storage])
      : super(ServerStatus(
          state: ServerConnectionState.checking,
          activeUrl: ApiEndpoints.baseUrl,
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (_storage != null) {
        final savedUrl = await _storage.getServerBaseUrl();
        if (savedUrl != null && savedUrl.trim().isNotEmpty) {
          ApiEndpoints.setBaseUrl(savedUrl.trim());
          state = ServerStatus(
            state: ServerConnectionState.checking,
            activeUrl: ApiEndpoints.baseUrl,
          );
        }
      }
    } catch (_) {}
    await checkHealth(null, true);
  }

  Future<bool> pingUrl(String url, {int timeoutMs = 1500}) async {
    try {
      final res = await _healthDio.get(
        '$url/health',
        options: Options(
          sendTimeout: Duration(milliseconds: timeoutMs),
          receiveTimeout: Duration(milliseconds: timeoutMs),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkHealth([String? specificUrl, bool autoFallback = false]) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final targetUrl = specificUrl ?? ApiEndpoints.baseUrl;

      // Quick test on target URL first
      final isOk = await pingUrl(targetUrl);
      if (isOk) {
        _onConnected(targetUrl);
        return;
      }

      // If auto-fallback is enabled (e.g. cold start), check safe candidate URLs
      if (autoFallback) {
        final candidates = ApiEndpoints.candidateUrls.where((c) => c != targetUrl).toList();
        final candidateResults = await Future.wait(
          candidates.map((candidate) async {
            final ok = await pingUrl(candidate, timeoutMs: 1200);
            return ok ? candidate : null;
          }),
        );

        final reachable = candidateResults.firstWhere((c) => c != null, orElse: () => null);
        if (reachable != null) {
          _onConnected(reachable);
          return;
        }
      }

      _onOffline(targetUrl);
    } finally {
      _isChecking = false;
    }
  }

  void _onConnected(String url) {
    ApiEndpoints.setBaseUrl(url);
    _storage?.saveServerBaseUrl(url);

    _stopReconnectTimer();
    _startHeartbeatTimer();

    state = ServerStatus(
      state: ServerConnectionState.connected,
      activeUrl: url,
    );
  }

  void _onOffline(String targetUrl) {
    state = ServerStatus(
      state: ServerConnectionState.offline,
      activeUrl: targetUrl,
      errorMessage: 'Server offline. Auto-reconnecting...',
    );

    _stopHeartbeatTimer();
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    // Auto-retry every 10 seconds while offline with single target ping
    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkHealth();
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startHeartbeatTimer() {
    if (_heartbeatTimer != null && _heartbeatTimer!.isActive) return;
    // Gentle heartbeat every 30 seconds while connected
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final ok = await pingUrl(ApiEndpoints.baseUrl, timeoutMs: 2000);
      if (!ok) {
        checkHealth();
      }
    });
  }

  void _stopHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> autoDetectServer() async {
    state = ServerStatus(
      state: ServerConnectionState.checking,
      activeUrl: ApiEndpoints.baseUrl,
    );

    final allCandidates = ApiEndpoints.candidateUrls;
    final results = await Future.wait(
      allCandidates.map((url) async {
        final ok = await pingUrl(url, timeoutMs: 1500);
        return ok ? url : null;
      }),
    );

    final reachable = results.firstWhere((c) => c != null, orElse: () => null);
    if (reachable != null) {
      _onConnected(reachable);
    } else {
      _onOffline(ApiEndpoints.baseUrl);
    }
  }

  Future<void> setCustomUrl(String customUrl) async {
    final cleanUrl = customUrl.trim().endsWith('/')
        ? customUrl.trim().substring(0, customUrl.trim().length - 1)
        : customUrl.trim();
    await checkHealth(cleanUrl);
  }

  @override
  void dispose() {
    _stopReconnectTimer();
    _stopHeartbeatTimer();
    _healthDio.close(force: true);
    super.dispose();
  }
}

final serverHealthServiceProvider =
    StateNotifierProvider<ServerHealthService, ServerStatus>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ServerHealthService(storage);
});
