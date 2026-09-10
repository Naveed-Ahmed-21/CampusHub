import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/search_repository.dart';
import '../../../../features/feed/presentation/controllers/feed_controller.dart';
import '../../../../features/profile/presentation/controllers/profile_controller.dart';

class RecentSearchUserItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? username;
  final String? role;

  RecentSearchUserItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.username,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'username': username,
        'role': role,
      };

  factory RecentSearchUserItem.fromJson(Map<String, dynamic> json) => RecentSearchUserItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        username: json['username'] as String?,
        role: json['role'] as String?,
      );
}

class SearchState {
  final String query;
  final String selectedType;
  final bool isLoading;
  final SearchResultsModel? results;
  final String? errorMessage;
  final List<RecentSearchUserItem> recentSearches;

  SearchState({
    required this.query,
    required this.selectedType,
    required this.isLoading,
    this.results,
    this.errorMessage,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    String? query,
    String? selectedType,
    bool? isLoading,
    SearchResultsModel? results,
    String? errorMessage,
    List<RecentSearchUserItem>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedType: selectedType ?? this.selectedType,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  final Ref _ref;
  final SecureStorageService _storage;

  SearchNotifier(this._repository, this._ref, this._storage)
      : super(SearchState(query: '', selectedType: 'all', isLoading: true)) {
    _loadRecentSearches();
    loadDiscover();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final jsonStr = await _storage.getRecentSearches();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        final loaded = list.map((item) => RecentSearchUserItem.fromJson(item as Map<String, dynamic>)).toList();
        state = state.copyWith(recentSearches: loaded);
      }
    } catch (_) {}
  }

  Future<void> _persistRecentSearches(List<RecentSearchUserItem> list) async {
    try {
      final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storage.saveRecentSearches(jsonStr);
    } catch (_) {}
  }

  void addRecentSearch(SearchUserItem user) {
    final current = List<RecentSearchUserItem>.from(state.recentSearches);
    current.removeWhere((item) => item.id == user.id);
    current.insert(
      0,
      RecentSearchUserItem(
        id: user.id,
        name: user.fullName,
        avatarUrl: user.avatarUrl,
        username: user.displayUsername,
        role: user.role,
      ),
    );
    if (current.length > 15) {
      current.removeRange(15, current.length);
    }
    state = state.copyWith(recentSearches: current);
    _persistRecentSearches(current);
  }

  void removeRecentSearch(String userId) {
    final current = List<RecentSearchUserItem>.from(state.recentSearches);
    current.removeWhere((item) => item.id == userId);
    state = state.copyWith(recentSearches: current);
    _persistRecentSearches(current);
  }

  void clearAllRecentSearches() {
    state = state.copyWith(recentSearches: []);
    _persistRecentSearches([]);
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
  final storage = ref.watch(secureStorageServiceProvider);
  return SearchNotifier(repo, ref, storage);
});
