import 'package:flutter/foundation.dart';

abstract class ApiEndpoints {
  static String get baseUrl {
    const overrideUrl = String.fromEnvironment('API_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/profile';
  static const String feed = '/api/v1/posts';
  static const String clubs = '/api/v1/clubs';
  static const String events = '/api/v1/events';
  static const String placements = '/api/v1/placement';
  static const String chat = '/api/v1/chat';
}
