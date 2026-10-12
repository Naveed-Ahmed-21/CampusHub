import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  Future<void> saveAccessToken(String token) async =>
      await _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() async =>
      await _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) async =>
      await _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() async =>
      await _storage.read(key: _refreshTokenKey);

  Future<void> saveUserId(String id) async =>
      await _storage.write(key: _userIdKey, value: id);

  Future<String?> getUserId() async =>
      await _storage.read(key: _userIdKey);

  static const String _recentSearchesKey = 'recent_searches_v1';
  static const String _themeModeKey = 'theme_mode_preference';

  Future<void> saveRecentSearches(String jsonString) async =>
      await _storage.write(key: _recentSearchesKey, value: jsonString);

  Future<String?> getRecentSearches() async =>
      await _storage.read(key: _recentSearchesKey);

  Future<void> saveThemeMode(String mode) async =>
      await _storage.write(key: _themeModeKey, value: mode);

  Future<String?> getThemeMode() async =>
      await _storage.read(key: _themeModeKey);

  static const String _serverBaseUrlKey = 'custom_server_base_url';

  Future<void> saveServerBaseUrl(String url) async =>
      await _storage.write(key: _serverBaseUrlKey, value: url);

  Future<String?> getServerBaseUrl() async =>
      await _storage.read(key: _serverBaseUrlKey);

  static const String _seenPostIdsKey = 'seen_post_ids_v1';

  Future<Set<String>> getSeenPostIds() async {
    final raw = await _storage.read(key: _seenPostIdsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> markPostsAsSeen(List<String> postIds) async {
    if (postIds.isEmpty) return;
    final current = await getSeenPostIds();
    current.addAll(postIds);
    // Keep max 1500 to prevent unbounded growth
    final trimmed = current.length > 1500 ? current.toList().sublist(current.length - 1500).toSet() : current;
    await _storage.write(key: _seenPostIdsKey, value: jsonEncode(trimmed.toList()));
  }

  Future<void> clearAll() async => await _storage.deleteAll();
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return SecureStorageService(storage);
});
