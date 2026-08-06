import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clubs_repository.dart';
import '../../domain/club_models.dart';

class ClubFilterState {
  final String category;
  final bool? isCrossDepartment;
  final String searchQuery;

  const ClubFilterState({
    this.category = 'ALL',
    this.isCrossDepartment,
    this.searchQuery = '',
  });

  ClubFilterState copyWith({
    String? category,
    bool? isCrossDepartment,
    String? searchQuery,
  }) {
    return ClubFilterState(
      category: category ?? this.category,
      isCrossDepartment: isCrossDepartment ?? this.isCrossDepartment,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final clubFilterProvider = StateProvider<ClubFilterState>((ref) {
  return const ClubFilterState();
});

final approvedClubsProvider = FutureProvider.autoDispose<List<Club>>((ref) async {
  final repository = ref.watch(clubsRepositoryProvider);
  final filter = ref.watch(clubFilterProvider);

  return repository.getClubs(
    category: filter.category == 'ALL' ? null : filter.category,
    isCrossDepartment: filter.isCrossDepartment,
    search: filter.searchQuery.isEmpty ? null : filter.searchQuery,
  );
});

final pendingClubsProvider = FutureProvider.autoDispose<List<Club>>((ref) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getPendingClubs();
});

final clubDetailsProvider = FutureProvider.autoDispose.family<Club, String>((ref, clubId) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getClubDetails(clubId);
});

final clubMembersProvider = FutureProvider.autoDispose.family<List<ClubMember>, String>((ref, clubId) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getMembers(clubId);
});

final clubFeedProvider = FutureProvider.autoDispose.family<List<ClubPost>, String>((ref, clubId) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getClubFeed(clubId);
});

final clubEventsProvider = FutureProvider.autoDispose.family<List<ClubEvent>, String>((ref, clubId) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getClubEvents(clubId);
});

final clubResourcesProvider = FutureProvider.autoDispose.family<List<ClubResource>, String>((ref, clubId) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getClubResources(clubId);
});

final clubChatMessagesProvider = FutureProvider.autoDispose.family<List<ClubChatMessage>, String>((ref, clubId) async {
  final repository = ref.watch(clubsRepositoryProvider);
  return repository.getChatMessages(clubId);
});
