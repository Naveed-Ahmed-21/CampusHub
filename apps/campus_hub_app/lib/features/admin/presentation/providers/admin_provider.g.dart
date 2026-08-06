// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminMetricsHash() => r'c22a4446efe5f6ca090bd1c867c22db436595843';

/// See also [adminMetrics].
@ProviderFor(adminMetrics)
final adminMetricsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  adminMetrics,
  name: r'adminMetricsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adminMetricsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminMetricsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$adminUsersHash() => r'1ef2c88168be2adc164b52c496e57417e57ad11d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [adminUsers].
@ProviderFor(adminUsers)
const adminUsersProvider = AdminUsersFamily();

/// See also [adminUsers].
class AdminUsersFamily extends Family<AsyncValue<List<dynamic>>> {
  /// See also [adminUsers].
  const AdminUsersFamily();

  /// See also [adminUsers].
  AdminUsersProvider call({
    String? role,
    String? search,
  }) {
    return AdminUsersProvider(
      role: role,
      search: search,
    );
  }

  @override
  AdminUsersProvider getProviderOverride(
    covariant AdminUsersProvider provider,
  ) {
    return call(
      role: provider.role,
      search: provider.search,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminUsersProvider';
}

/// See also [adminUsers].
class AdminUsersProvider extends AutoDisposeFutureProvider<List<dynamic>> {
  /// See also [adminUsers].
  AdminUsersProvider({
    String? role,
    String? search,
  }) : this._internal(
          (ref) => adminUsers(
            ref as AdminUsersRef,
            role: role,
            search: search,
          ),
          from: adminUsersProvider,
          name: r'adminUsersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$adminUsersHash,
          dependencies: AdminUsersFamily._dependencies,
          allTransitiveDependencies:
              AdminUsersFamily._allTransitiveDependencies,
          role: role,
          search: search,
        );

  AdminUsersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.role,
    required this.search,
  }) : super.internal();

  final String? role;
  final String? search;

  @override
  Override overrideWith(
    FutureOr<List<dynamic>> Function(AdminUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminUsersProvider._internal(
        (ref) => create(ref as AdminUsersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        role: role,
        search: search,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<dynamic>> createElement() {
    return _AdminUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUsersProvider &&
        other.role == role &&
        other.search == search;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, role.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminUsersRef on AutoDisposeFutureProviderRef<List<dynamic>> {
  /// The parameter `role` of this provider.
  String? get role;

  /// The parameter `search` of this provider.
  String? get search;
}

class _AdminUsersProviderElement
    extends AutoDisposeFutureProviderElement<List<dynamic>> with AdminUsersRef {
  _AdminUsersProviderElement(super.provider);

  @override
  String? get role => (origin as AdminUsersProvider).role;
  @override
  String? get search => (origin as AdminUsersProvider).search;
}

String _$adminDepartmentsHash() => r'c8549024bb56ddbfce0737fefbe00fbf2518e65f';

/// See also [adminDepartments].
@ProviderFor(adminDepartments)
final adminDepartmentsProvider =
    AutoDisposeFutureProvider<List<dynamic>>.internal(
  adminDepartments,
  name: r'adminDepartmentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminDepartmentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminDepartmentsRef = AutoDisposeFutureProviderRef<List<dynamic>>;
String _$adminAnalyticsHash() => r'178c72f1d3531bd9550e63840631360f39c39f9f';

/// See also [adminAnalytics].
@ProviderFor(adminAnalytics)
final adminAnalyticsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  adminAnalytics,
  name: r'adminAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminAnalyticsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$adminAuditReportsHash() => r'f802e08f7f207942d3d8afb0210693f6225a5e6a';

/// See also [adminAuditReports].
@ProviderFor(adminAuditReports)
final adminAuditReportsProvider =
    AutoDisposeFutureProvider<List<dynamic>>.internal(
  adminAuditReports,
  name: r'adminAuditReportsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminAuditReportsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminAuditReportsRef = AutoDisposeFutureProviderRef<List<dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
