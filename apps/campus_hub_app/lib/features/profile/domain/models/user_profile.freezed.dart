// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SkillItem _$SkillItemFromJson(Map<String, dynamic> json) {
  return _SkillItem.fromJson(json);
}

/// @nodoc
mixin _$SkillItem {
  String get id => throw _privateConstructorUsedError;
  String get skillName => throw _privateConstructorUsedError;
  String? get proficiency => throw _privateConstructorUsedError;

  /// Serializes this SkillItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillItemCopyWith<SkillItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillItemCopyWith<$Res> {
  factory $SkillItemCopyWith(SkillItem value, $Res Function(SkillItem) then) =
      _$SkillItemCopyWithImpl<$Res, SkillItem>;
  @useResult
  $Res call({String id, String skillName, String? proficiency});
}

/// @nodoc
class _$SkillItemCopyWithImpl<$Res, $Val extends SkillItem>
    implements $SkillItemCopyWith<$Res> {
  _$SkillItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? skillName = null,
    Object? proficiency = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      skillName: null == skillName
          ? _value.skillName
          : skillName // ignore: cast_nullable_to_non_nullable
              as String,
      proficiency: freezed == proficiency
          ? _value.proficiency
          : proficiency // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SkillItemImplCopyWith<$Res>
    implements $SkillItemCopyWith<$Res> {
  factory _$$SkillItemImplCopyWith(
          _$SkillItemImpl value, $Res Function(_$SkillItemImpl) then) =
      __$$SkillItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String skillName, String? proficiency});
}

/// @nodoc
class __$$SkillItemImplCopyWithImpl<$Res>
    extends _$SkillItemCopyWithImpl<$Res, _$SkillItemImpl>
    implements _$$SkillItemImplCopyWith<$Res> {
  __$$SkillItemImplCopyWithImpl(
      _$SkillItemImpl _value, $Res Function(_$SkillItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of SkillItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? skillName = null,
    Object? proficiency = freezed,
  }) {
    return _then(_$SkillItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      skillName: null == skillName
          ? _value.skillName
          : skillName // ignore: cast_nullable_to_non_nullable
              as String,
      proficiency: freezed == proficiency
          ? _value.proficiency
          : proficiency // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillItemImpl implements _SkillItem {
  const _$SkillItemImpl(
      {required this.id, required this.skillName, this.proficiency});

  factory _$SkillItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillItemImplFromJson(json);

  @override
  final String id;
  @override
  final String skillName;
  @override
  final String? proficiency;

  @override
  String toString() {
    return 'SkillItem(id: $id, skillName: $skillName, proficiency: $proficiency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.skillName, skillName) ||
                other.skillName == skillName) &&
            (identical(other.proficiency, proficiency) ||
                other.proficiency == proficiency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, skillName, proficiency);

  /// Create a copy of SkillItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillItemImplCopyWith<_$SkillItemImpl> get copyWith =>
      __$$SkillItemImplCopyWithImpl<_$SkillItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillItemImplToJson(
      this,
    );
  }
}

abstract class _SkillItem implements SkillItem {
  const factory _SkillItem(
      {required final String id,
      required final String skillName,
      final String? proficiency}) = _$SkillItemImpl;

  factory _SkillItem.fromJson(Map<String, dynamic> json) =
      _$SkillItemImpl.fromJson;

  @override
  String get id;
  @override
  String get skillName;
  @override
  String? get proficiency;

  /// Create a copy of SkillItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillItemImplCopyWith<_$SkillItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectItem _$ProjectItemFromJson(Map<String, dynamic> json) {
  return _ProjectItem.fromJson(json);
}

/// @nodoc
mixin _$ProjectItem {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get projectUrl => throw _privateConstructorUsedError;
  String? get repoUrl => throw _privateConstructorUsedError;

  /// Serializes this ProjectItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectItemCopyWith<ProjectItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectItemCopyWith<$Res> {
  factory $ProjectItemCopyWith(
          ProjectItem value, $Res Function(ProjectItem) then) =
      _$ProjectItemCopyWithImpl<$Res, ProjectItem>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      String? projectUrl,
      String? repoUrl});
}

/// @nodoc
class _$ProjectItemCopyWithImpl<$Res, $Val extends ProjectItem>
    implements $ProjectItemCopyWith<$Res> {
  _$ProjectItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? projectUrl = freezed,
    Object? repoUrl = freezed,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      projectUrl: freezed == projectUrl
          ? _value.projectUrl
          : projectUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      repoUrl: freezed == repoUrl
          ? _value.repoUrl
          : repoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectItemImplCopyWith<$Res>
    implements $ProjectItemCopyWith<$Res> {
  factory _$$ProjectItemImplCopyWith(
          _$ProjectItemImpl value, $Res Function(_$ProjectItemImpl) then) =
      __$$ProjectItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      String? projectUrl,
      String? repoUrl});
}

/// @nodoc
class __$$ProjectItemImplCopyWithImpl<$Res>
    extends _$ProjectItemCopyWithImpl<$Res, _$ProjectItemImpl>
    implements _$$ProjectItemImplCopyWith<$Res> {
  __$$ProjectItemImplCopyWithImpl(
      _$ProjectItemImpl _value, $Res Function(_$ProjectItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? projectUrl = freezed,
    Object? repoUrl = freezed,
  }) {
    return _then(_$ProjectItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      projectUrl: freezed == projectUrl
          ? _value.projectUrl
          : projectUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      repoUrl: freezed == repoUrl
          ? _value.repoUrl
          : repoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectItemImpl implements _ProjectItem {
  const _$ProjectItemImpl(
      {required this.id,
      required this.title,
      this.description,
      this.projectUrl,
      this.repoUrl});

  factory _$ProjectItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectItemImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? projectUrl;
  @override
  final String? repoUrl;

  @override
  String toString() {
    return 'ProjectItem(id: $id, title: $title, description: $description, projectUrl: $projectUrl, repoUrl: $repoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.projectUrl, projectUrl) ||
                other.projectUrl == projectUrl) &&
            (identical(other.repoUrl, repoUrl) || other.repoUrl == repoUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, description, projectUrl, repoUrl);

  /// Create a copy of ProjectItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectItemImplCopyWith<_$ProjectItemImpl> get copyWith =>
      __$$ProjectItemImplCopyWithImpl<_$ProjectItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectItemImplToJson(
      this,
    );
  }
}

abstract class _ProjectItem implements ProjectItem {
  const factory _ProjectItem(
      {required final String id,
      required final String title,
      final String? description,
      final String? projectUrl,
      final String? repoUrl}) = _$ProjectItemImpl;

  factory _ProjectItem.fromJson(Map<String, dynamic> json) =
      _$ProjectItemImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get projectUrl;
  @override
  String? get repoUrl;

  /// Create a copy of ProjectItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectItemImplCopyWith<_$ProjectItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get rollNumber => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get githubUrl => throw _privateConstructorUsedError;
  String? get linkedinUrl => throw _privateConstructorUsedError;
  String? get websiteUrl => throw _privateConstructorUsedError;
  String? get resumeUrl => throw _privateConstructorUsedError;
  List<SkillItem> get skills => throw _privateConstructorUsedError;
  List<ProjectItem> get projects => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String id,
      String firstName,
      String lastName,
      String email,
      String? rollNumber,
      String? phone,
      String? avatarUrl,
      String? bio,
      String? githubUrl,
      String? linkedinUrl,
      String? websiteUrl,
      String? resumeUrl,
      List<SkillItem> skills,
      List<ProjectItem> projects});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = null,
    Object? rollNumber = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? bio = freezed,
    Object? githubUrl = freezed,
    Object? linkedinUrl = freezed,
    Object? websiteUrl = freezed,
    Object? resumeUrl = freezed,
    Object? skills = null,
    Object? projects = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      rollNumber: freezed == rollNumber
          ? _value.rollNumber
          : rollNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      githubUrl: freezed == githubUrl
          ? _value.githubUrl
          : githubUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkedinUrl: freezed == linkedinUrl
          ? _value.linkedinUrl
          : linkedinUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrl: freezed == websiteUrl
          ? _value.websiteUrl
          : websiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      resumeUrl: freezed == resumeUrl
          ? _value.resumeUrl
          : resumeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      skills: null == skills
          ? _value.skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<SkillItem>,
      projects: null == projects
          ? _value.projects
          : projects // ignore: cast_nullable_to_non_nullable
              as List<ProjectItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String firstName,
      String lastName,
      String email,
      String? rollNumber,
      String? phone,
      String? avatarUrl,
      String? bio,
      String? githubUrl,
      String? linkedinUrl,
      String? websiteUrl,
      String? resumeUrl,
      List<SkillItem> skills,
      List<ProjectItem> projects});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = null,
    Object? rollNumber = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? bio = freezed,
    Object? githubUrl = freezed,
    Object? linkedinUrl = freezed,
    Object? websiteUrl = freezed,
    Object? resumeUrl = freezed,
    Object? skills = null,
    Object? projects = null,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      rollNumber: freezed == rollNumber
          ? _value.rollNumber
          : rollNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      githubUrl: freezed == githubUrl
          ? _value.githubUrl
          : githubUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkedinUrl: freezed == linkedinUrl
          ? _value.linkedinUrl
          : linkedinUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrl: freezed == websiteUrl
          ? _value.websiteUrl
          : websiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      resumeUrl: freezed == resumeUrl
          ? _value.resumeUrl
          : resumeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      skills: null == skills
          ? _value._skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<SkillItem>,
      projects: null == projects
          ? _value._projects
          : projects // ignore: cast_nullable_to_non_nullable
              as List<ProjectItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      this.rollNumber,
      this.phone,
      this.avatarUrl,
      this.bio,
      this.githubUrl,
      this.linkedinUrl,
      this.websiteUrl,
      this.resumeUrl,
      final List<SkillItem> skills = const [],
      final List<ProjectItem> projects = const []})
      : _skills = skills,
        _projects = projects;

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String email;
  @override
  final String? rollNumber;
  @override
  final String? phone;
  @override
  final String? avatarUrl;
  @override
  final String? bio;
  @override
  final String? githubUrl;
  @override
  final String? linkedinUrl;
  @override
  final String? websiteUrl;
  @override
  final String? resumeUrl;
  final List<SkillItem> _skills;
  @override
  @JsonKey()
  List<SkillItem> get skills {
    if (_skills is EqualUnmodifiableListView) return _skills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skills);
  }

  final List<ProjectItem> _projects;
  @override
  @JsonKey()
  List<ProjectItem> get projects {
    if (_projects is EqualUnmodifiableListView) return _projects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_projects);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, firstName: $firstName, lastName: $lastName, email: $email, rollNumber: $rollNumber, phone: $phone, avatarUrl: $avatarUrl, bio: $bio, githubUrl: $githubUrl, linkedinUrl: $linkedinUrl, websiteUrl: $websiteUrl, resumeUrl: $resumeUrl, skills: $skills, projects: $projects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.rollNumber, rollNumber) ||
                other.rollNumber == rollNumber) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.githubUrl, githubUrl) ||
                other.githubUrl == githubUrl) &&
            (identical(other.linkedinUrl, linkedinUrl) ||
                other.linkedinUrl == linkedinUrl) &&
            (identical(other.websiteUrl, websiteUrl) ||
                other.websiteUrl == websiteUrl) &&
            (identical(other.resumeUrl, resumeUrl) ||
                other.resumeUrl == resumeUrl) &&
            const DeepCollectionEquality().equals(other._skills, _skills) &&
            const DeepCollectionEquality().equals(other._projects, _projects));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      firstName,
      lastName,
      email,
      rollNumber,
      phone,
      avatarUrl,
      bio,
      githubUrl,
      linkedinUrl,
      websiteUrl,
      resumeUrl,
      const DeepCollectionEquality().hash(_skills),
      const DeepCollectionEquality().hash(_projects));

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String id,
      required final String firstName,
      required final String lastName,
      required final String email,
      final String? rollNumber,
      final String? phone,
      final String? avatarUrl,
      final String? bio,
      final String? githubUrl,
      final String? linkedinUrl,
      final String? websiteUrl,
      final String? resumeUrl,
      final List<SkillItem> skills,
      final List<ProjectItem> projects}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  String get email;
  @override
  String? get rollNumber;
  @override
  String? get phone;
  @override
  String? get avatarUrl;
  @override
  String? get bio;
  @override
  String? get githubUrl;
  @override
  String? get linkedinUrl;
  @override
  String? get websiteUrl;
  @override
  String? get resumeUrl;
  @override
  List<SkillItem> get skills;
  @override
  List<ProjectItem> get projects;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
