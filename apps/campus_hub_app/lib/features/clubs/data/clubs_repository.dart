import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/club_models.dart';
import '../../feed/domain/models/post_item.dart';

class ClubsRepository {
  final Dio _dio;

  ClubsRepository(this._dio);

  Future<List<Club>> getClubs({
    String? category,
    bool? isCrossDepartment,
    String? search,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (isCrossDepartment != null) query['is_cross_department'] = isCrossDepartment.toString();
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _dio.get('/api/v1/clubs', queryParameters: query);
    final data = response.data['data'];
    final List clubsList = data is Map ? (data['clubs'] ?? []) : (data ?? []);

    return clubsList.map((json) => Club.fromJson(json)).toList();
  }

  Future<List<Club>> getPendingClubs() async {
    final response = await _dio.get('/api/v1/clubs/pending');
    final data = response.data['data'];
    final List clubsList = data is Map ? (data['clubs'] ?? []) : (data ?? []);

    return clubsList.map((json) => Club.fromJson(json)).toList();
  }

  Future<List<Club>> getMyProposedClubs() async {
    final response = await _dio.get('/api/v1/clubs/my-proposed');
    final List list = response.data['data'] ?? [];
    return list.map((json) => Club.fromJson(json)).toList();
  }

  Future<Club> getClubDetails(String clubId) async {
    final response = await _dio.get('/api/v1/clubs/$clubId');
    return Club.fromJson(response.data['data']);
  }

  Future<Club> createClub({
    required String name,
    required String category,
    String? description,
    String? logoUrl,
    bool isCrossDepartment = true,
  }) async {
    final response = await _dio.post(
      '/api/v1/clubs',
      data: {
        'name': name,
        'category': category,
        'description': description,
        'logo_url': logoUrl,
        'is_cross_department': isCrossDepartment,
      },
    );
    return Club.fromJson(response.data['data']);
  }

  Future<Club> verifyClub(String clubId, String status, {String? rejectionReason}) async {
    final response = await _dio.patch(
      '/api/v1/clubs/$clubId/verify',
      data: {
        'status': status,
        'rejection_reason': rejectionReason,
      },
    );
    return Club.fromJson(response.data['data']);
  }

  Future<void> deleteClub(String clubId) async {
    await _dio.delete('/api/v1/clubs/$clubId');
  }

  Future<void> joinClub(String clubId) async {
    await _dio.post('/api/v1/clubs/$clubId/join');
  }

  Future<void> leaveClub(String clubId) async {
    await _dio.post('/api/v1/clubs/$clubId/leave');
  }

  Future<void> addMember(String clubId, String emailOrUserId, {String role = 'MEMBER'}) async {
    await _dio.post(
      '/api/v1/clubs/$clubId/members',
      data: {
        'email': emailOrUserId.contains('@') ? emailOrUserId.trim() : null,
        'userId': !emailOrUserId.contains('@') ? emailOrUserId.trim() : null,
        'role': role,
      },
    );
  }

  Future<List<ClubMember>> getMembers(String clubId) async {
    final response = await _dio.get('/api/v1/clubs/$clubId/members');
    final List list = response.data['data'] ?? [];
    return list.map((json) => ClubMember.fromJson(json)).toList();
  }

  Future<void> updateMemberRole(String clubId, String userId, String role) async {
    await _dio.patch(
      '/api/v1/clubs/$clubId/members/$userId',
      data: {'role': role},
    );
  }

  Future<List<PostItem>> getClubFeed(String clubId) async {
    final response = await _dio.get('/api/v1/clubs/$clubId/feed');
    final data = response.data['data'];
    final List list = data is Map ? (data['posts'] ?? []) : (data ?? []);
    return list.map((json) => PostItem.fromJson(json)).toList();
  }

  Future<PostItem> createClubPost(String clubId, String title, String content) async {
    final response = await _dio.post(
      '/api/v1/clubs/$clubId/feed',
      data: {
        'title': title,
        'content': content,
      },
    );
    return PostItem.fromJson(response.data['data']);
  }

  Future<List<ClubEvent>> getClubEvents(String clubId) async {
    final response = await _dio.get('/api/v1/clubs/$clubId/events');
    final List list = response.data['data'] ?? [];
    return list.map((json) => ClubEvent.fromJson(json)).toList();
  }

  Future<ClubEvent> createClubEvent({
    required String clubId,
    required String title,
    String? description,
    String? venue,
    required DateTime startTime,
    required DateTime endTime,
    String? bannerUrl,
  }) async {
    final response = await _dio.post(
      '/api/v1/clubs/$clubId/events',
      data: {
        'title': title,
        'description': description,
        'venue': venue,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'banner_url': bannerUrl,
      },
    );
    return ClubEvent.fromJson(response.data['data']);
  }

  Future<List<ClubResource>> getClubResources(String clubId) async {
    final response = await _dio.get('/api/v1/clubs/$clubId/resources');
    final List list = response.data['data'] ?? [];
    return list.map((json) => ClubResource.fromJson(json)).toList();
  }

  Future<ClubResource> createClubResource({
    required String clubId,
    required String title,
    String? description,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    final response = await _dio.post(
      '/api/v1/clubs/$clubId/resources',
      data: {
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type': fileType,
      },
    );
    return ClubResource.fromJson(response.data['data']);
  }

  Future<void> deleteClubResource(String clubId, String resourceId) async {
    await _dio.delete('/api/v1/clubs/$clubId/resources/$resourceId');
  }

  Future<List<ClubChatMessage>> getChatMessages(String clubId) async {
    final response = await _dio.get('/api/v1/clubs/$clubId/chat/messages');
    final List list = response.data['data'] ?? [];
    return list.map((json) => ClubChatMessage.fromJson(json)).toList();
  }

  Future<ClubChatMessage> sendChatMessage(String clubId, String message) async {
    final response = await _dio.post(
      '/api/v1/clubs/$clubId/chat/messages',
      data: {'message': message},
    );
    return ClubChatMessage.fromJson(response.data['data']);
  }
}

final clubsRepositoryProvider = Provider<ClubsRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ClubsRepository(dio);
});
