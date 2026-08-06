// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkillItemImpl _$$SkillItemImplFromJson(Map<String, dynamic> json) =>
    _$SkillItemImpl(
      id: json['id'] as String,
      skillName: json['skillName'] as String,
      proficiency: json['proficiency'] as String?,
    );

Map<String, dynamic> _$$SkillItemImplToJson(_$SkillItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'skillName': instance.skillName,
      'proficiency': instance.proficiency,
    };

_$ProjectItemImpl _$$ProjectItemImplFromJson(Map<String, dynamic> json) =>
    _$ProjectItemImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      projectUrl: json['projectUrl'] as String?,
      repoUrl: json['repoUrl'] as String?,
    );

Map<String, dynamic> _$$ProjectItemImplToJson(_$ProjectItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'projectUrl': instance.projectUrl,
      'repoUrl': instance.repoUrl,
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      rollNumber: json['rollNumber'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      githubUrl: json['githubUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      resumeUrl: json['resumeUrl'] as String?,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => SkillItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'rollNumber': instance.rollNumber,
      'phone': instance.phone,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'githubUrl': instance.githubUrl,
      'linkedinUrl': instance.linkedinUrl,
      'websiteUrl': instance.websiteUrl,
      'resumeUrl': instance.resumeUrl,
      'skills': instance.skills,
      'projects': instance.projects,
    };
