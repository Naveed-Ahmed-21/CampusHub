import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../datasources/feed_remote_datasource.dart';
import '../../domain/models/post_item.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remote;

  FeedRepositoryImpl(this._remote);

  @override
  Future<ApiResult<List<PostItem>>> getFeed({
    required String feedType,
    String? authorId,
    String? clubId,
    String? departmentId,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final posts = await _remote.getFeed(
        feedType,
        page,
        limit,
        authorId: authorId,
        clubId: clubId,
        departmentId: departmentId,
        search: search,
      );
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
    bool isCrossDepartment = false,
    String? scope,
    String? clubId,
    List<Map<String, String>>? attachments,
  }) async {
    try {
      final post = await _remote.createPost(
        title,
        content,
        type,
        attachments,
        isCrossDepartment: isCrossDepartment,
        scope: scope,
        clubId: clubId,
      );
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
  Future<ApiResult<PostCommentItem>> addComment(String postId, String content, {String? parentCommentId}) async {
    try {
      final comment = await _remote.addComment(postId, content, parentCommentId: parentCommentId);
      return ApiResult.success(comment);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<bool>> toggleCommentLike(String commentId) async {
    try {
      final isLiked = await _remote.toggleCommentLike(commentId);
      return ApiResult.success(isLiked);
    } catch (_) {
      return const ApiResult.success(true);
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

  @override
  Future<ApiResult<void>> deletePost(String postId) async {
    try {
      await _remote.deletePost(postId);
      return const ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<PostItem>> updatePost(String postId, {String? title, String? content}) async {
    try {
      final post = await _remote.updatePost(postId, title: title, content: content);
      return ApiResult.success(post);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final remote = ref.watch(feedRemoteDataSourceProvider);
  return FeedRepositoryImpl(remote);
});
