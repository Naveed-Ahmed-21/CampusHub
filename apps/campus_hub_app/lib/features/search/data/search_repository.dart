import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class SearchResultsModel {
  final List<dynamic> students;
  final List<dynamic> faculty;
  final List<dynamic> clubs;
  final List<dynamic> posts;
  final List<dynamic> events;
  final List<dynamic> careerResources;

  SearchResultsModel({
    required this.students,
    required this.faculty,
    required this.clubs,
    required this.posts,
    required this.events,
    required this.careerResources,
  });

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) {
    return SearchResultsModel(
      students: json['students'] as List<dynamic>? ?? [],
      faculty: json['faculty'] as List<dynamic>? ?? [],
      clubs: json['clubs'] as List<dynamic>? ?? [],
      posts: json['posts'] as List<dynamic>? ?? [],
      events: json['events'] as List<dynamic>? ?? [],
      careerResources: json['career_resources'] as List<dynamic>? ?? [],
    );
  }

  bool get isEmpty =>
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
      students: [],
      faculty: [],
      clubs: [],
      posts: [],
      events: [],
      careerResources: [],
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return SearchRepository(dio);
});
