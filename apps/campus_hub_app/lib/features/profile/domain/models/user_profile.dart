import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class SkillItem with _$SkillItem {
  const factory SkillItem({
    required String id,
    required String skillName,
    String? proficiency,
  }) = _SkillItem;

  factory SkillItem.fromJson(Map<String, dynamic> json) =>
      _$SkillItemFromJson(json);
}

@freezed
class ProjectItem with _$ProjectItem {
  const factory ProjectItem({
    required String id,
    required String title,
    String? description,
    String? projectUrl,
    String? repoUrl,
  }) = _ProjectItem;

  factory ProjectItem.fromJson(Map<String, dynamic> json) =>
      _$ProjectItemFromJson(json);
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    String? rollNumber,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
    String? resumeUrl,
    @Default([]) List<SkillItem> skills,
    @Default([]) List<ProjectItem> projects,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
