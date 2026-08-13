import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/search_repository.dart';

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

  SearchNotifier(this._repository)
      : super(SearchState(query: '', selectedType: 'all', isLoading: false));

  void setType(String type) {
    state = state.copyWith(selectedType: type);
    if (state.query.trim().isNotEmpty) {
      performSearch(state.query);
    }
  }

  Future<void> performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = SearchState(query: '', selectedType: state.selectedType, isLoading: false);
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
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotifier(repo);
});
