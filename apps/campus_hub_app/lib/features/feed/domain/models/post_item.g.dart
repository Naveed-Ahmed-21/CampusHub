// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostAttachmentItemImpl _$$PostAttachmentItemImplFromJson(
        Map<String, dynamic> json) =>
    _$PostAttachmentItemImpl(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
    );

Map<String, dynamic> _$$PostAttachmentItemImplToJson(
        _$PostAttachmentItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileType': instance.fileType,
    };

_$PostAuthorItemImpl _$$PostAuthorItemImplFromJson(Map<String, dynamic> json) =>
    _$PostAuthorItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
    );

Map<String, dynamic> _$$PostAuthorItemImplToJson(
        _$PostAuthorItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
    };

_$PostCommentItemImpl _$$PostCommentItemImplFromJson(
        Map<String, dynamic> json) =>
    _$PostCommentItemImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as String,
      author: PostAuthorItem.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PostCommentItemImplToJson(
        _$PostCommentItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'createdAt': instance.createdAt,
      'author': instance.author,
    };

_$PostItemImpl _$$PostItemImplFromJson(Map<String, dynamic> json) =>
    _$PostItemImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      author: PostAuthorItem.fromJson(json['author'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map(
                  (e) => PostAttachmentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
    );

Map<String, dynamic> _$$PostItemImplToJson(_$PostItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'type': instance.type,
      'isPinned': instance.isPinned,
      'createdAt': instance.createdAt,
      'author': instance.author,
      'attachments': instance.attachments,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'isLiked': instance.isLiked,
      'isSaved': instance.isSaved,
    };
