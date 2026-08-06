import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/events_repository.dart';
import '../../domain/event_models.dart';

final selectedEventsScopeProvider = StateProvider<String?>((ref) => null);

final eventsListProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(eventsRepositoryProvider);
  final scope = ref.watch(selectedEventsScopeProvider);
  return repo.getEvents(scope: scope);
});

final calendarEventsProvider = FutureProvider.autoDispose.family<List<EventModel>, Map<String, int>>((ref, params) async {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getCalendarEvents(month: params['month'], year: params['year']);
});

final userEventRegistrationsProvider = FutureProvider.autoDispose<List<EventRegistrationModel>>((ref) async {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getUserRegistrations();
});
