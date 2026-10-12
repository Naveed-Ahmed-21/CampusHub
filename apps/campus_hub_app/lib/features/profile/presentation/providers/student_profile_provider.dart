import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/detailed_student_profile.dart';

final studentDetailedProfileProvider =
    FutureProvider.autoDispose<DetailedStudentProfile>((ref) async {
  final authUserId = ref.watch(authControllerProvider.select((s) => s.asData?.value?.id));
  if (authUserId == null || authUserId.isEmpty) {
    throw Exception('Unauthenticated');
  }
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/api/v1/profile/me');
  final data = response.data['data'] as Map<String, dynamic>;
  return DetailedStudentProfile.fromJson(data);
});

final studentChangeRequestsProvider =
    FutureProvider.autoDispose<List<ProfileChangeRequestItem>>((ref) async {
  final authUserId = ref.watch(authControllerProvider.select((s) => s.asData?.value?.id));
  if (authUserId == null || authUserId.isEmpty) {
    return [];
  }
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/api/v1/profile/change-requests');
  final list = response.data['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => ProfileChangeRequestItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

class StudentCareerProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  StudentCareerProfileNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateCareer({
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
    String? resumeUrl,
    List<String>? skills,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.patch('/api/v1/profile/career', data: {
        if (bio != null) 'bio': bio,
        if (githubUrl != null) 'githubUrl': githubUrl,
        if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        if (skills != null) 'skills': skills,
      });

      _ref.invalidate(studentDetailedProfileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelChangeRequest(String requestId) async {
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.delete('/api/v1/profile/change-requests/$requestId');
      _ref.invalidate(studentChangeRequestsProvider);
      _ref.invalidate(studentDetailedProfileProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final studentCareerProfileProvider =
    StateNotifierProvider<StudentCareerProfileNotifier, AsyncValue<void>>(
  (ref) => StudentCareerProfileNotifier(ref),
);
