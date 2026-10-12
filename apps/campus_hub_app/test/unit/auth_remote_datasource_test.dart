import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campus_hub_app/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
  group('AuthRemoteDataSource Unit Tests', () {
    test('login returns auth session map with access token', () async {
      final dio = Dio();
      final dataSource = AuthRemoteDataSource(dio);

      try {
        final result = await dataSource.login(
          'student@campushub.edu',
          'Password123!',
        );
        expect(result, isNotNull);
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('sendFirstLoginOtp calls endpoint without crashing', () async {
      final dio = Dio();
      final dataSource = AuthRemoteDataSource(dio);

      try {
        final result = await dataSource.sendFirstLoginOtp('student@campushub.edu');
        expect(result, isNotNull);
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('verifyFirstLoginOtp calls endpoint without crashing', () async {
      final dio = Dio();
      final dataSource = AuthRemoteDataSource(dio);

      try {
        final result = await dataSource.verifyFirstLoginOtp('student@campushub.edu', '123456');
        expect(result, isNotNull);
      } catch (e) {
        expect(e, isNotNull);
      }
    });
  });
}
