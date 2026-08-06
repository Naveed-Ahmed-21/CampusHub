import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_item.freezed.dart';
part 'post_item.g.dart';

@freezed
class PostAttachmentItem with _$PostAttachmentItem {
  const factory PostAttachmentItem({
    required String id,
    required String fileName,
    required String fileUrl,
    required String fileType,
  }) = _PostAttachmentItem;

  factory PostAttachmentItem.fromJson(Map<String, dynamic> json) =>
      _$PostAttachmentItemFromJson(json);
}

@freezed
class PostAuthorItem with _$PostAuthorItem {
  const factory PostAuthorItem({
    required String id,
    required String name,
    String? avatarUrl,
    required String role,
  }) = _PostAuthorItem;

  factory PostAuthorItem.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorItemFromJson(json);
}

@freezed
class PostCommentItem with _$PostCommentItem {
  const factory PostCommentItem({
    required String id,
    required String content,
    required String createdAt,
    required PostAuthorItem author,
  }) = _PostCommentItem;

  factory PostCommentItem.fromJson(Map<String, dynamic> json) =>
      _$PostCommentItemFromJson(json);
}

@freezed
class PostItem with _$PostItem {
  const factory PostItem({
    required String id,
    required String title,
    required String content,
    required String type,
    @Default(false) bool isPinned,
    required String createdAt,
    required PostAuthorItem author,
    @Default([]) List<PostAttachmentItem> attachments,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
  }) = _PostItem;

  factory PostItem.fromJson(Map<String, dynamic> json) =>
      _$PostItemFromJson(json);
}
