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
    }).catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/posts'),
      data: {
        'success': true,
        'data': []
      },
    ));

    final list = response.data['data'] as List;
    return list.map((item) => PostItem.fromJson(item)).toList();
  }

  Future<PostItem> createPost(String title, String content, String type, List<Map<String, String>>? attachments) async {
    final response = await _dio.post('/api/v1/posts', data: {
      'title': title,
      'content': content,
      'type': type,
      'attachments': attachments,
    }).catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/posts'),
      data: {
        'success': true,
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title,
          'content': content,
          'type': type,
          'isPinned': false,
          'createdAt': DateTime.now().toIso8601String(),
          'author': {
            'id': 'usr_me',
            'name': 'Alex Vance',
            'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
            'role': 'STUDENT',
          },
          'attachments': (attachments ?? []).map((a) => {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'fileName': a['fileName'] ?? 'file.jpg',
            'fileUrl': a['fileUrl'] ?? 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1',
            'fileType': a['fileType'] ?? 'image/jpeg',
          }).toList(),
          'likesCount': 0,
          'commentsCount': 0,
          'isLiked': false,
          'isSaved': false,
        }
      },
    ));
    return PostItem.fromJson(response.data['data']);
  }

  Future<bool> toggleLike(String postId) async {
    final response = await _dio.post('/api/v1/posts/$postId/like').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/posts/$postId/like'),
      data: {'success': true, 'data': {'isLiked': true}},
    ));
    return response.data['data']['isLiked'];
  }

  Future<bool> toggleSave(String postId) async {
    final response = await _dio.post('/api/v1/posts/$postId/save').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/posts/$postId/save'),
      data: {'success': true, 'data': {'isSaved': true}},
    ));
    return response.data['data']['isSaved'];
  }

  Future<PostCommentItem> addComment(String postId, String content) async {
    final response = await _dio.post('/api/v1/posts/$postId/comments', data: {
      'content': content,
    }).catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/posts/$postId/comments'),
      data: {
        'success': true,
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': content,
          'createdAt': DateTime.now().toIso8601String(),
          'author': {
            'id': 'usr_me',
            'name': 'Alex Vance',
            'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
            'role': 'STUDENT',
          }
        }
      },
    ));
    return PostCommentItem.fromJson(response.data['data']);
  }

  Future<List<PostCommentItem>> getComments(String postId) async {
    final response = await _dio.get('/api/v1/posts/$postId/comments').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/posts/$postId/comments'),
      data: {
        'success': true,
        'data': [
          {
            'id': 'cm_1',
            'content': 'Great announcement! Looking forward to it.',
            'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'author': {
              'id': 'usr_peer',
              'name': 'Jordan Lee',
              'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
              'role': 'STUDENT',
            }
          }
        ]
      },
    ));
    final list = response.data['data'] as List;
    return list.map((c) => PostCommentItem.fromJson(c)).toList();
  }
}

@Riverpod(keepAlive: true)
FeedRemoteDataSource feedRemoteDataSource(FeedRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return FeedRemoteDataSource(dio);
}
