import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/search_repository.dart';
import '../../../../features/feed/presentation/controllers/feed_controller.dart';
import '../../../../features/profile/presentation/controllers/profile_controller.dart';

class SearchState {
  final String query;
  final String selectedType;
  final bool isLoading;
  final SearchResultsModel? results;
  final String? errorMessage;

  SearchState({
    required this.query,
    required this.selectedType,
    required this.isLoading,
    this.results,
    this.errorMessage,
  });

  SearchState copyWith({
    String? query,
    String? selectedType,
    bool? isLoading,
    SearchResultsModel? results,
    String? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedType: selectedType ?? this.selectedType,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  final Ref _ref;

  SearchNotifier(this._repository, this._ref)
      : super(SearchState(query: '', selectedType: 'all', isLoading: true)) {
    loadDiscover();
  }

  Future<void> loadDiscover() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.search('', type: 'users');
      state = state.copyWith(isLoading: false, results: res);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setType(String type) {
    state = state.copyWith(selectedType: type);
    performSearch(state.query);
  }

  Future<void> performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = state.copyWith(query: '', isLoading: true, errorMessage: null);
      try {
        final res = await _repository.search('', type: state.selectedType == 'all' ? 'users' : state.selectedType);
        state = state.copyWith(isLoading: false, results: res);
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load suggestions.');
      }
      return;
    }

    state = state.copyWith(query: trimmedQuery, isLoading: true, errorMessage: null);

    try {
      final res = await _repository.search(trimmedQuery, type: state.selectedType);
      state = state.copyWith(isLoading: false, results: res);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Search failed. Please check network connection.',
      );
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    final currentResults = state.results;
    if (currentResults == null) return;

    final updatedUsers = currentResults.users.map((u) {
      if (u.id == targetUserId) {
        return u.copyWith(isFollowing: !u.isFollowing);
      }
      return u;
    }).toList();

    final updatedStudents = currentResults.students.map((s) {
      if (s.id == targetUserId) {
        return s.copyWith(isFollowing: !s.isFollowing);
      }
      return s;
    }).toList();

    final updatedFaculty = currentResults.faculty.map((f) {
      if (f.id == targetUserId) {
        return f.copyWith(isFollowing: !f.isFollowing);
      }
      return f;
    }).toList();

    state = state.copyWith(
      results: SearchResultsModel(
        users: updatedUsers,
        students: updatedStudents,
        faculty: updatedFaculty,
        clubs: currentResults.clubs,
        posts: currentResults.posts,
        events: currentResults.events,
        careerResources: currentResults.careerResources,
      ),
    );

    await _repository.toggleFollow(targetUserId);
    _ref.invalidate(profileControllerProvider);
    _ref.invalidate(userProfileProvider(targetUserId));
    _ref.invalidate(userFollowersProvider(targetUserId));
    _ref.invalidate(feedControllerProvider);
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotifier(repo, ref);
});
