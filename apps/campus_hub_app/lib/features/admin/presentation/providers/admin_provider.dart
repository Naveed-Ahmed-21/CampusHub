import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_remote_datasource.dart';

final adminMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getMetrics();
});

class AdminUsersFilter {
  final String? role;
  final String? search;

  const AdminUsersFilter({this.role, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUsersFilter && role == other.role && search == other.search;

  @override
  int get hashCode => role.hashCode ^ search.hashCode;
}

final adminUsersProvider = FutureProvider.family<List<dynamic>, AdminUsersFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getUsers(
        role: filter?.role,
        search: filter?.search,
      );
});

final adminDepartmentsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getDepartments();
});

final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAnalytics();
});

final adminAuditReportsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAuditReports();
});
