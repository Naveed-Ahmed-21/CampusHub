import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class SearchUserItem {
  final String id;
  final String? username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? rollNumber;
  final String role;
  final String? departmentName;
  final bool isFollowing;

  SearchUserItem({
    required this.id,
    this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.rollNumber,
    required this.role,
    this.departmentName,
    this.isFollowing = false,
  });

  String get displayUsername => username != null && username!.isNotEmpty
      ? (username!.startsWith('@') ? username! : '@$username')
      : (email.isNotEmpty ? '@${email.split('@').first}' : '@user');

  factory SearchUserItem.fromJson(Map<String, dynamic> json) {
    final dept = json['department'];
    final dName = dept is Map ? dept['name'] as String? : (dept is String ? dept : null);
    final fName = json['firstName'] as String? ?? json['first_name'] as String? ?? '';
    final lName = json['lastName'] as String? ?? json['last_name'] as String? ?? '';
    final emailStr = json['email'] as String? ?? '';
    final rawUsername = json['username'] as String?;
    final resolvedUsername = rawUsername ?? (emailStr.isNotEmpty ? '@${emailStr.split('@').first}' : null);

    return SearchUserItem(
      id: json['id'] as String? ?? '',
      username: resolvedUsername,
      firstName: fName,
      lastName: lName,
      fullName: json['fullName'] as String? ?? '$fName $lName'.trim(),
      email: emailStr,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      rollNumber: json['rollNumber'] as String? ?? json['roll_number'] as String?,
      role: json['role'] as String? ?? 'STUDENT',
      departmentName: dName,
      isFollowing: json['isFollowing'] as bool? ?? json['is_following'] as bool? ?? false,
    );
  }

  SearchUserItem copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? rollNumber,
    String? role,
    String? departmentName,
    bool? isFollowing,
  }) {
    return SearchUserItem(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rollNumber: rollNumber ?? this.rollNumber,
      role: role ?? this.role,
      departmentName: departmentName ?? this.departmentName,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class SearchResultsModel {
  final List<SearchUserItem> users;
  final List<SearchUserItem> students;
  final List<SearchUserItem> faculty;
  final List<dynamic> clubs;
  final List<dynamic> posts;
  final List<dynamic> events;
  final List<dynamic> careerResources;

  SearchResultsModel({
    required this.users,
    required this.students,
    required this.faculty,
    required this.clubs,
    required this.posts,
    required this.events,
    required this.careerResources,
  });

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] as List<dynamic>? ?? [];
    final rawStudents = json['students'] as List<dynamic>? ?? [];
    final rawFaculty = json['faculty'] as List<dynamic>? ?? [];

    return SearchResultsModel(
      users: rawUsers.map((u) => SearchUserItem.fromJson(u as Map<String, dynamic>)).toList(),
      students: rawStudents.map((s) => SearchUserItem.fromJson(s as Map<String, dynamic>)).toList(),
      faculty: rawFaculty.map((f) => SearchUserItem.fromJson(f as Map<String, dynamic>)).toList(),
      clubs: json['clubs'] as List<dynamic>? ?? [],
      posts: json['posts'] as List<dynamic>? ?? [],
      events: json['events'] as List<dynamic>? ?? [],
      careerResources: json['career_resources'] as List<dynamic>? ?? [],
    );
  }

  bool get isEmpty =>
      users.isEmpty &&
      students.isEmpty &&
      faculty.isEmpty &&
      clubs.isEmpty &&
      posts.isEmpty &&
      events.isEmpty &&
      careerResources.isEmpty;
}

class SearchRepository {
  final Dio _dio;

  SearchRepository(this._dio);

  Future<SearchResultsModel> search(String query, {String type = 'all'}) async {
    final response = await _dio.get(
      '/api/v1/search',
      queryParameters: {
        'q': query,
        'type': type,
      },
    );

    if (response.data != null && response.data['success'] == true) {
      return SearchResultsModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    return SearchResultsModel(
      users: [],
      students: [],
      faculty: [],
      clubs: [],
      posts: [],
      events: [],
      careerResources: [],
    );
  }

  Future<bool> toggleFollow(String targetUserId) async {
    final response = await _dio.post('/api/v1/profile/$targetUserId/follow');
    return response.data['data']['isFollowing'] ?? false;
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return SearchRepository(dio);
});
