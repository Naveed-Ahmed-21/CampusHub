class AppConfig {
  static const String appName = 'CampusHub';
  
  // Default development local server URL
  static const String apiBaseUrl = 'http://10.0.2.2:5000/api/v1'; // Android emulator default
  static const String socketUrl = 'http://10.0.2.2:5000';

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Storage Keys
  static const String accessTokenKey = 'campushub_access_token';
  static const String refreshTokenKey = 'campushub_refresh_token';
  static const String userDataKey = 'campushub_user_data';
}
