import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/admin_remote_datasource.dart';

part 'admin_provider.g.dart';

@riverpod
Future<Map<String, dynamic>> adminMetrics(AdminMetricsRef ref) {
  return ref.watch(adminRemoteDataSourceProvider).getMetrics();
}

@riverpod
Future<List<dynamic>> adminUsers(AdminUsersRef ref, {String? role, String? search}) {
  return ref.watch(adminRemoteDataSourceProvider).getUsers(role: role, search: search);
}

@riverpod
Future<List<dynamic>> adminDepartments(AdminDepartmentsRef ref) {
  return ref.watch(adminRemoteDataSourceProvider).getDepartments();
}

@riverpod
Future<Map<String, dynamic>> adminAnalytics(AdminAnalyticsRef ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAnalytics();
}

@riverpod
Future<List<dynamic>> adminAuditReports(AdminAuditReportsRef ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAuditReports();
}
