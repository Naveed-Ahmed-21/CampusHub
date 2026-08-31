import '../../../../core/network/api_result.dart';
import '../models/post_item.dart';

abstract class FeedRepository {
  Future<ApiResult<List<PostItem>>> getFeed({
    required String feedType,
    String? authorId,
    String? clubId,
    String? departmentId,
    String? search,
    int page = 1,
    int limit = 10,
  });

  Future<ApiResult<PostItem>> createPost({
    required String title,
    required String content,
    String type = 'GENERAL',
    bool isCrossDepartment = false,
    String? scope,
    String? clubId,
    List<Map<String, String>>? attachments,
  });

  Future<ApiResult<bool>> toggleLike(String postId);

  Future<ApiResult<bool>> toggleSave(String postId);

  Future<ApiResult<PostCommentItem>> addComment(String postId, String content, {String? parentCommentId});

  Future<ApiResult<bool>> toggleCommentLike(String commentId);

  Future<ApiResult<List<PostCommentItem>>> getComments(String postId);

  Future<ApiResult<void>> deletePost(String postId);

  Future<ApiResult<PostItem>> updatePost(String postId, {String? title, String? content});
}
