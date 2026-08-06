// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PostAttachmentItem _$PostAttachmentItemFromJson(Map<String, dynamic> json) {
  return _PostAttachmentItem.fromJson(json);
}

/// @nodoc
mixin _$PostAttachmentItem {
  String get id => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  String get fileUrl => throw _privateConstructorUsedError;
  String get fileType => throw _privateConstructorUsedError;

  /// Serializes this PostAttachmentItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostAttachmentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostAttachmentItemCopyWith<PostAttachmentItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostAttachmentItemCopyWith<$Res> {
  factory $PostAttachmentItemCopyWith(
          PostAttachmentItem value, $Res Function(PostAttachmentItem) then) =
      _$PostAttachmentItemCopyWithImpl<$Res, PostAttachmentItem>;
  @useResult
  $Res call({String id, String fileName, String fileUrl, String fileType});
}

/// @nodoc
class _$PostAttachmentItemCopyWithImpl<$Res, $Val extends PostAttachmentItem>
    implements $PostAttachmentItemCopyWith<$Res> {
  _$PostAttachmentItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostAttachmentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileUrl = null,
    Object? fileType = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostAttachmentItemImplCopyWith<$Res>
    implements $PostAttachmentItemCopyWith<$Res> {
  factory _$$PostAttachmentItemImplCopyWith(_$PostAttachmentItemImpl value,
          $Res Function(_$PostAttachmentItemImpl) then) =
      __$$PostAttachmentItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String fileName, String fileUrl, String fileType});
}

/// @nodoc
class __$$PostAttachmentItemImplCopyWithImpl<$Res>
    extends _$PostAttachmentItemCopyWithImpl<$Res, _$PostAttachmentItemImpl>
    implements _$$PostAttachmentItemImplCopyWith<$Res> {
  __$$PostAttachmentItemImplCopyWithImpl(_$PostAttachmentItemImpl _value,
      $Res Function(_$PostAttachmentItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostAttachmentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileUrl = null,
    Object? fileType = null,
  }) {
    return _then(_$PostAttachmentItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostAttachmentItemImpl implements _PostAttachmentItem {
  const _$PostAttachmentItemImpl(
      {required this.id,
      required this.fileName,
      required this.fileUrl,
      required this.fileType});

  factory _$PostAttachmentItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostAttachmentItemImplFromJson(json);

  @override
  final String id;
  @override
  final String fileName;
  @override
  final String fileUrl;
  @override
  final String fileType;

  @override
  String toString() {
    return 'PostAttachmentItem(id: $id, fileName: $fileName, fileUrl: $fileUrl, fileType: $fileType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostAttachmentItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, fileName, fileUrl, fileType);

  /// Create a copy of PostAttachmentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostAttachmentItemImplCopyWith<_$PostAttachmentItemImpl> get copyWith =>
      __$$PostAttachmentItemImplCopyWithImpl<_$PostAttachmentItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostAttachmentItemImplToJson(
      this,
    );
  }
}

abstract class _PostAttachmentItem implements PostAttachmentItem {
  const factory _PostAttachmentItem(
      {required final String id,
      required final String fileName,
      required final String fileUrl,
      required final String fileType}) = _$PostAttachmentItemImpl;

  factory _PostAttachmentItem.fromJson(Map<String, dynamic> json) =
      _$PostAttachmentItemImpl.fromJson;

  @override
  String get id;
  @override
  String get fileName;
  @override
  String get fileUrl;
  @override
  String get fileType;

  /// Create a copy of PostAttachmentItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostAttachmentItemImplCopyWith<_$PostAttachmentItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostAuthorItem _$PostAuthorItemFromJson(Map<String, dynamic> json) {
  return _PostAuthorItem.fromJson(json);
}

/// @nodoc
mixin _$PostAuthorItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;

  /// Serializes this PostAuthorItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostAuthorItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostAuthorItemCopyWith<PostAuthorItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostAuthorItemCopyWith<$Res> {
  factory $PostAuthorItemCopyWith(
          PostAuthorItem value, $Res Function(PostAuthorItem) then) =
      _$PostAuthorItemCopyWithImpl<$Res, PostAuthorItem>;
  @useResult
  $Res call({String id, String name, String? avatarUrl, String role});
}

/// @nodoc
class _$PostAuthorItemCopyWithImpl<$Res, $Val extends PostAuthorItem>
    implements $PostAuthorItemCopyWith<$Res> {
  _$PostAuthorItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostAuthorItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatarUrl = freezed,
    Object? role = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostAuthorItemImplCopyWith<$Res>
    implements $PostAuthorItemCopyWith<$Res> {
  factory _$$PostAuthorItemImplCopyWith(_$PostAuthorItemImpl value,
          $Res Function(_$PostAuthorItemImpl) then) =
      __$$PostAuthorItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? avatarUrl, String role});
}

/// @nodoc
class __$$PostAuthorItemImplCopyWithImpl<$Res>
    extends _$PostAuthorItemCopyWithImpl<$Res, _$PostAuthorItemImpl>
    implements _$$PostAuthorItemImplCopyWith<$Res> {
  __$$PostAuthorItemImplCopyWithImpl(
      _$PostAuthorItemImpl _value, $Res Function(_$PostAuthorItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostAuthorItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatarUrl = freezed,
    Object? role = null,
  }) {
    return _then(_$PostAuthorItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostAuthorItemImpl implements _PostAuthorItem {
  const _$PostAuthorItemImpl(
      {required this.id,
      required this.name,
      this.avatarUrl,
      required this.role});

  factory _$PostAuthorItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostAuthorItemImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? avatarUrl;
  @override
  final String role;

  @override
  String toString() {
    return 'PostAuthorItem(id: $id, name: $name, avatarUrl: $avatarUrl, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostAuthorItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, avatarUrl, role);

  /// Create a copy of PostAuthorItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostAuthorItemImplCopyWith<_$PostAuthorItemImpl> get copyWith =>
      __$$PostAuthorItemImplCopyWithImpl<_$PostAuthorItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostAuthorItemImplToJson(
      this,
    );
  }
}

abstract class _PostAuthorItem implements PostAuthorItem {
  const factory _PostAuthorItem(
      {required final String id,
      required final String name,
      final String? avatarUrl,
      required final String role}) = _$PostAuthorItemImpl;

  factory _PostAuthorItem.fromJson(Map<String, dynamic> json) =
      _$PostAuthorItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get avatarUrl;
  @override
  String get role;

  /// Create a copy of PostAuthorItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostAuthorItemImplCopyWith<_$PostAuthorItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostCommentItem _$PostCommentItemFromJson(Map<String, dynamic> json) {
  return _PostCommentItem.fromJson(json);
}

/// @nodoc
mixin _$PostCommentItem {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  PostAuthorItem get author => throw _privateConstructorUsedError;

  /// Serializes this PostCommentItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostCommentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostCommentItemCopyWith<PostCommentItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostCommentItemCopyWith<$Res> {
  factory $PostCommentItemCopyWith(
          PostCommentItem value, $Res Function(PostCommentItem) then) =
      _$PostCommentItemCopyWithImpl<$Res, PostCommentItem>;
  @useResult
  $Res call(
      {String id, String content, String createdAt, PostAuthorItem author});

  $PostAuthorItemCopyWith<$Res> get author;
}

/// @nodoc
class _$PostCommentItemCopyWithImpl<$Res, $Val extends PostCommentItem>
    implements $PostCommentItemCopyWith<$Res> {
  _$PostCommentItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostCommentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
    Object? author = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as PostAuthorItem,
    ) as $Val);
  }

  /// Create a copy of PostCommentItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostAuthorItemCopyWith<$Res> get author {
    return $PostAuthorItemCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostCommentItemImplCopyWith<$Res>
    implements $PostCommentItemCopyWith<$Res> {
  factory _$$PostCommentItemImplCopyWith(_$PostCommentItemImpl value,
          $Res Function(_$PostCommentItemImpl) then) =
      __$$PostCommentItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String content, String createdAt, PostAuthorItem author});

  @override
  $PostAuthorItemCopyWith<$Res> get author;
}

/// @nodoc
class __$$PostCommentItemImplCopyWithImpl<$Res>
    extends _$PostCommentItemCopyWithImpl<$Res, _$PostCommentItemImpl>
    implements _$$PostCommentItemImplCopyWith<$Res> {
  __$$PostCommentItemImplCopyWithImpl(
      _$PostCommentItemImpl _value, $Res Function(_$PostCommentItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostCommentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
    Object? author = null,
  }) {
    return _then(_$PostCommentItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as PostAuthorItem,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostCommentItemImpl implements _PostCommentItem {
  const _$PostCommentItemImpl(
      {required this.id,
      required this.content,
      required this.createdAt,
      required this.author});

  factory _$PostCommentItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostCommentItemImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  final String createdAt;
  @override
  final PostAuthorItem author;

  @override
  String toString() {
    return 'PostCommentItem(id: $id, content: $content, createdAt: $createdAt, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostCommentItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.author, author) || other.author == author));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, createdAt, author);

  /// Create a copy of PostCommentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostCommentItemImplCopyWith<_$PostCommentItemImpl> get copyWith =>
      __$$PostCommentItemImplCopyWithImpl<_$PostCommentItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostCommentItemImplToJson(
      this,
    );
  }
}

abstract class _PostCommentItem implements PostCommentItem {
  const factory _PostCommentItem(
      {required final String id,
      required final String content,
      required final String createdAt,
      required final PostAuthorItem author}) = _$PostCommentItemImpl;

  factory _PostCommentItem.fromJson(Map<String, dynamic> json) =
      _$PostCommentItemImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  String get createdAt;
  @override
  PostAuthorItem get author;

  /// Create a copy of PostCommentItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostCommentItemImplCopyWith<_$PostCommentItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostItem _$PostItemFromJson(Map<String, dynamic> json) {
  return _PostItem.fromJson(json);
}

/// @nodoc
mixin _$PostItem {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  PostAuthorItem get author => throw _privateConstructorUsedError;
  List<PostAttachmentItem> get attachments =>
      throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  int get commentsCount => throw _privateConstructorUsedError;
  bool get isLiked => throw _privateConstructorUsedError;
  bool get isSaved => throw _privateConstructorUsedError;

  /// Serializes this PostItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostItemCopyWith<PostItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostItemCopyWith<$Res> {
  factory $PostItemCopyWith(PostItem value, $Res Function(PostItem) then) =
      _$PostItemCopyWithImpl<$Res, PostItem>;
  @useResult
  $Res call(
      {String id,
      String title,
      String content,
      String type,
      bool isPinned,
      String createdAt,
      PostAuthorItem author,
      List<PostAttachmentItem> attachments,
      int likesCount,
      int commentsCount,
      bool isLiked,
      bool isSaved});

  $PostAuthorItemCopyWith<$Res> get author;
}

/// @nodoc
class _$PostItemCopyWithImpl<$Res, $Val extends PostItem>
    implements $PostItemCopyWith<$Res> {
  _$PostItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? type = null,
    Object? isPinned = null,
    Object? createdAt = null,
    Object? author = null,
    Object? attachments = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLiked = null,
    Object? isSaved = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as PostAuthorItem,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<PostAttachmentItem>,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLiked: null == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaved: null == isSaved
          ? _value.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of PostItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostAuthorItemCopyWith<$Res> get author {
    return $PostAuthorItemCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostItemImplCopyWith<$Res>
    implements $PostItemCopyWith<$Res> {
  factory _$$PostItemImplCopyWith(
          _$PostItemImpl value, $Res Function(_$PostItemImpl) then) =
      __$$PostItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String content,
      String type,
      bool isPinned,
      String createdAt,
      PostAuthorItem author,
      List<PostAttachmentItem> attachments,
      int likesCount,
      int commentsCount,
      bool isLiked,
      bool isSaved});

  @override
  $PostAuthorItemCopyWith<$Res> get author;
}

/// @nodoc
class __$$PostItemImplCopyWithImpl<$Res>
    extends _$PostItemCopyWithImpl<$Res, _$PostItemImpl>
    implements _$$PostItemImplCopyWith<$Res> {
  __$$PostItemImplCopyWithImpl(
      _$PostItemImpl _value, $Res Function(_$PostItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? type = null,
    Object? isPinned = null,
    Object? createdAt = null,
    Object? author = null,
    Object? attachments = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLiked = null,
    Object? isSaved = null,
  }) {
    return _then(_$PostItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as PostAuthorItem,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<PostAttachmentItem>,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLiked: null == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaved: null == isSaved
          ? _value.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostItemImpl implements _PostItem {
  const _$PostItemImpl(
      {required this.id,
      required this.title,
      required this.content,
      required this.type,
      this.isPinned = false,
      required this.createdAt,
      required this.author,
      final List<PostAttachmentItem> attachments = const [],
      this.likesCount = 0,
      this.commentsCount = 0,
      this.isLiked = false,
      this.isSaved = false})
      : _attachments = attachments;

  factory _$PostItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostItemImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  final String type;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  final String createdAt;
  @override
  final PostAuthorItem author;
  final List<PostAttachmentItem> _attachments;
  @override
  @JsonKey()
  List<PostAttachmentItem> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  @JsonKey()
  final int likesCount;
  @override
  @JsonKey()
  final int commentsCount;
  @override
  @JsonKey()
  final bool isLiked;
  @override
  @JsonKey()
  final bool isSaved;

  @override
  String toString() {
    return 'PostItem(id: $id, title: $title, content: $content, type: $type, isPinned: $isPinned, createdAt: $createdAt, author: $author, attachments: $attachments, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked, isSaved: $isSaved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      content,
      type,
      isPinned,
      createdAt,
      author,
      const DeepCollectionEquality().hash(_attachments),
      likesCount,
      commentsCount,
      isLiked,
      isSaved);

  /// Create a copy of PostItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostItemImplCopyWith<_$PostItemImpl> get copyWith =>
      __$$PostItemImplCopyWithImpl<_$PostItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostItemImplToJson(
      this,
    );
  }
}

abstract class _PostItem implements PostItem {
  const factory _PostItem(
      {required final String id,
      required final String title,
      required final String content,
      required final String type,
      final bool isPinned,
      required final String createdAt,
      required final PostAuthorItem author,
      final List<PostAttachmentItem> attachments,
      final int likesCount,
      final int commentsCount,
      final bool isLiked,
      final bool isSaved}) = _$PostItemImpl;

  factory _PostItem.fromJson(Map<String, dynamic> json) =
      _$PostItemImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get content;
  @override
  String get type;
  @override
  bool get isPinned;
  @override
  String get createdAt;
  @override
  PostAuthorItem get author;
  @override
  List<PostAttachmentItem> get attachments;
  @override
  int get likesCount;
  @override
  int get commentsCount;
  @override
  bool get isLiked;
  @override
  bool get isSaved;

  /// Create a copy of PostItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostItemImplCopyWith<_$PostItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
