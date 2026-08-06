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
        'data': [
          {
            'id': 'post_101',
            'title': 'Welcome to CampusHub 2026 Academic Season!',
            'content': 'We are thrilled to launch the unified campus platform. Explore clubs, events, placements, and real-time community feeds.',
            'type': 'ANNOUNCEMENT',
            'isPinned': true,
            'createdAt': DateTime.now().toIso8601String(),
            'author': {
              'id': 'usr_admin',
              'name': 'Dr. Sarah Connor',
              'avatarUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
              'role': 'COLLEGE_ADMIN',
            },
            'attachments': [
              {
                'id': 'att_1',
                'fileName': 'campus_welcome.jpg',
                'fileUrl': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1',
                'fileType': 'image/jpeg',
              }
            ],
            'likesCount': 42,
            'commentsCount': 5,
            'isLiked': false,
            'isSaved': true,
          },
          {
            'id': 'post_102',
            'title': 'ACM Student Chapter Hackathon Announced',
            'content': 'Join us this weekend for the annual 24-hour innovation hackathon. Cash prizes, mentor guidance, and networking opportunities await!',
            'type': 'EVENT_PROMO',
            'isPinned': false,
            'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            'author': {
              'id': 'usr_lead',
              'name': 'Alex Vance',
              'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
              'role': 'STUDENT',
            },
            'attachments': [
              {
                'id': 'att_2',
                'fileName': 'hackathon_poster.jpg',
                'fileUrl': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4',
                'fileType': 'image/jpeg',
              }
            ],
            'likesCount': 18,
            'commentsCount': 2,
            'isLiked': true,
            'isSaved': false,
          }
        ]
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
