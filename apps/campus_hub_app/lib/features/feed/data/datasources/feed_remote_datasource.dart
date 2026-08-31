import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/post_item.dart';

class FeedRemoteDataSource {
  final Dio _dio;

  FeedRemoteDataSource(this._dio);

  Future<List<PostItem>> getFeed(
    String feedType,
    int page,
    int limit, {
    String? authorId,
    String? clubId,
    String? departmentId,
    String? search,
  }) async {
    final response = await _dio.get('/api/v1/posts', queryParameters: {
      'feedType': feedType,
      'page': page,
      'limit': limit,
      if (authorId != null && authorId.isNotEmpty) 'authorId': authorId,
      if (clubId != null && clubId.isNotEmpty) 'clubId': clubId,
      if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    final list = response.data['data'] as List;
    return list.map((item) => PostItem.fromJson(item)).toList();
  }

  Future<PostItem> createPost(
    String title,
    String content,
    String type,
    List<Map<String, String>>? attachments, {
    bool isCrossDepartment = false,
    String? scope,
    String? clubId,
  }) async {
    final response = await _dio.post('/api/v1/posts', data: {
      'title': title,
      'content': content,
      'type': type,
      'attachments': attachments,
      'isCrossDepartment': isCrossDepartment,
      'scope': isCrossDepartment ? 'CROSS_DEPARTMENT' : (scope ?? 'DEPARTMENT'),
      if (clubId != null && clubId.isNotEmpty) 'clubId': clubId,
    });
    return PostItem.fromJson(response.data['data']);
  }

  Future<bool> toggleLike(String postId) async {
    final response = await _dio.post('/api/v1/posts/$postId/like');
    return response.data['data']['isLiked'];
  }

  Future<bool> toggleSave(String postId) async {
    final response = await _dio.post('/api/v1/posts/$postId/save');
    return response.data['data']['isSaved'];
  }

  Future<PostCommentItem> addComment(String postId, String content, {String? parentCommentId}) async {
    final response = await _dio.post('/api/v1/posts/$postId/comments', data: {
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    });
    return PostCommentItem.fromJson(response.data['data']);
  }

  Future<bool> toggleCommentLike(String commentId) async {
    final response = await _dio.post('/api/v1/posts/comments/$commentId/like');
    return response.data['data']['isLiked'] ?? true;
  }

  Future<List<PostCommentItem>> getComments(String postId) async {
    final response = await _dio.get('/api/v1/posts/$postId/comments');
    final list = response.data['data'] as List;
    return list.map((c) => PostCommentItem.fromJson(c)).toList();
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete('/api/v1/posts/$postId');
  }

  Future<PostItem> updatePost(String postId, {String? title, String? content}) async {
    final response = await _dio.patch('/api/v1/posts/$postId', data: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
    });
    return PostItem.fromJson(response.data['data']);
  }
}

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return FeedRemoteDataSource(dio);
});
