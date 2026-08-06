import '../../../../core/network/api_result.dart';
import '../models/post_item.dart';

abstract class FeedRepository {
  Future<ApiResult<List<PostItem>>> getFeed({
    required String feedType,
    int page = 1,
    int limit = 10,
  });

  Future<ApiResult<PostItem>> createPost({
    required String title,
    required String content,
    String type = 'GENERAL',
    List<Map<String, String>>? attachments,
  });

  Future<ApiResult<bool>> toggleLike(String postId);

  Future<ApiResult<bool>> toggleSave(String postId);

  Future<ApiResult<PostCommentItem>> addComment(String postId, String content);

  Future<ApiResult<List<PostCommentItem>>> getComments(String postId);
}
