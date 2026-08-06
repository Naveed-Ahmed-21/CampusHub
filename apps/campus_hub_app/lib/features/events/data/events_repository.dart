import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/event_models.dart';

class EventsRepository {
  final Dio _dio;

  EventsRepository(this._dio);

  Future<List<EventModel>> getEvents({
    String? scope,
    String? departmentId,
    String? clubId,
    String? category,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (scope != null && scope.isNotEmpty) query['scope'] = scope;
    if (departmentId != null && departmentId.isNotEmpty) query['department_id'] = departmentId;
    if (clubId != null && clubId.isNotEmpty) query['club_id'] = clubId;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get('/api/v1/events', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['events'] ?? []) : (data ?? []);
    return list.map((json) => EventModel.fromJson(json)).toList();
  }

  Future<List<EventModel>> getCalendarEvents({int? month, int? year}) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;

    final response = await _dio.get('/api/v1/events/calendar', queryParameters: query);
    final List list = response.data['data'] ?? [];
    return list.map((json) => EventModel.fromJson(json)).toList();
  }

  Future<EventModel> getEventDetails(String id) async {
    final response = await _dio.get('/api/v1/events/$id');
    return EventModel.fromJson(response.data['data']);
  }

  Future<EventModel> createEvent({
    required String title,
    required String scope,
    required String startTime,
    required String endTime,
    String? description,
    String? departmentId,
    String? clubId,
    String? category,
    String? venue,
    String? bannerUrl,
    int? maxCapacity,
  }) async {
    final response = await _dio.post(
      '/api/v1/events',
      data: {
        'title': title,
        'scope': scope,
        'start_time': startTime,
        'end_time': endTime,
        'description': description,
        'department_id': departmentId,
        'club_id': clubId,
        'category': category,
        'venue': venue,
        'banner_url': bannerUrl,
        'max_capacity': maxCapacity,
      },
    );
    return EventModel.fromJson(response.data['data']);
  }

  Future<EventRegistrationModel> registerForEvent(String eventId) async {
    final response = await _dio.post('/api/v1/events/$eventId/register');
    return EventRegistrationModel.fromJson(response.data['data']);
  }

  Future<List<EventRegistrationModel>> getUserRegistrations() async {
    final response = await _dio.get('/api/v1/events/my-registrations');
    final List list = response.data['data'] ?? [];
    return list.map((json) => EventRegistrationModel.fromJson(json)).toList();
  }

  Future<void> cancelRegistration(String eventId) async {
    await _dio.delete('/api/v1/events/$eventId/register');
  }

  Future<EventRegistrationModel> markQRAttendance(String ticketCode) async {
    final response = await _dio.post(
      '/api/v1/events/attendance/scan',
      data: {'ticket_code': ticketCode},
    );
    return EventRegistrationModel.fromJson(response.data['data']);
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return EventsRepository(dio);
});
