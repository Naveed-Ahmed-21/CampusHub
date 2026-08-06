import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../datasources/feed_remote_datasource.dart';
import '../../domain/models/post_item.dart';
import '../../domain/repositories/feed_repository.dart';

part 'feed_repository_impl.g.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remote;

  FeedRepositoryImpl(this._remote);

  @override
  Future<ApiResult<List<PostItem>>> getFeed({
    required String feedType,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final posts = await _remote.getFeed(feedType, page, limit);
      return ApiResult.success(posts);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<PostItem>> createPost({
    required String title,
    required String content,
    String type = 'GENERAL',
    List<Map<String, String>>? attachments,
  }) async {
    try {
      final post = await _remote.createPost(title, content, type, attachments);
      return ApiResult.success(post);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<bool>> toggleLike(String postId) async {
    try {
      final isLiked = await _remote.toggleLike(postId);
      return ApiResult.success(isLiked);
    } catch (_) {
      return const ApiResult.success(true);
    }
  }

  @override
  Future<ApiResult<bool>> toggleSave(String postId) async {
    try {
      final isSaved = await _remote.toggleSave(postId);
      return ApiResult.success(isSaved);
    } catch (_) {
      return const ApiResult.success(true);
    }
  }

  @override
  Future<ApiResult<PostCommentItem>> addComment(String postId, String content) async {
    try {
      final comment = await _remote.addComment(postId, content);
      return ApiResult.success(comment);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<List<PostCommentItem>>> getComments(String postId) async {
    try {
      final comments = await _remote.getComments(postId);
      return ApiResult.success(comments);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }
}

@Riverpod(keepAlive: true)
FeedRepository feedRepository(FeedRepositoryRef ref) {
  final remote = ref.watch(feedRemoteDataSourceProvider);
  return FeedRepositoryImpl(remote);
}
