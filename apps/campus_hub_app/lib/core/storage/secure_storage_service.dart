import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

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

  Future<void> clearAll() async => await _storage.deleteAll();
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(SecureStorageServiceRef ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return SecureStorageService(storage);
}
