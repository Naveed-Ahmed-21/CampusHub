abstract class ApiEndpoints {
  static String? _dynamicBaseUrl;

  static const List<String> candidateUrls = [
    'http://localhost:5000',
    'http://172.18.15.11:5000',
    'http://10.0.2.2:5000',
  ];

  static String get baseUrl {
    if (_dynamicBaseUrl != null && _dynamicBaseUrl!.isNotEmpty) {
      return _dynamicBaseUrl!;
    }
    const overrideUrl = String.fromEnvironment('API_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;

    return 'http://localhost:5000';
  }

  static void setBaseUrl(String url) {
    _dynamicBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://localhost:5000') || trimmed.startsWith('http://127.0.0.1:5000')) {
      final path = trimmed.replaceFirst(RegExp(r'^http://(localhost|127\.0\.0\.1):5000'), '');
      return '$baseUrl$path';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '$baseUrl$trimmed';
    return '$baseUrl/$trimmed';
  }

  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/profile';
  static const String feed = '/api/v1/posts';
  static const String stories = '/api/v1/stories';
  static const String mediaUpload = '/api/v1/media/upload';
  static const String clubs = '/api/v1/clubs';
  static const String events = '/api/v1/events';
  static const String placements = '/api/v1/placement';
  static const String chat = '/api/v1/chat';
}
