import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/post_item.dart';

part 'feed_remote_datasource.g.dart';

class FeedRemoteDataSource {
  final Dio _dio;

  FeedRemoteDataSource(this._dio);

  Future<List<PostItem>> getFeed(String feedType, int page, int limit) async {
    final response = await _dio.get('/api/v1/posts', queryParameters: {
      'feedType': feedType,
      'page': page,
      'limit': limit,
    });

    final list = response.data['data'] as List;
    return list.map((item) => PostItem.fromJson(item)).toList();
  }

  Future<PostItem> createPost(String title, String content, String type, List<Map<String, String>>? attachments) async {
    final response = await _dio.post('/api/v1/posts', data: {
      'title': title,
      'content': content,
      'type': type,
      'attachments': attachments,
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

  Future<PostCommentItem> addComment(String postId, String content) async {
    final response = await _dio.post('/api/v1/posts/$postId/comments', data: {
      'content': content,
    });
    return PostCommentItem.fromJson(response.data['data']);
  }

  Future<List<PostCommentItem>> getComments(String postId) async {
    final response = await _dio.get('/api/v1/posts/$postId/comments');
    final list = response.data['data'] as List;
    return list.map((c) => PostCommentItem.fromJson(c)).toList();
  }
}

@Riverpod(keepAlive: true)
FeedRemoteDataSource feedRemoteDataSource(FeedRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return FeedRemoteDataSource(dio);
}
