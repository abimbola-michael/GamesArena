import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchMatchesNotifier extends StateNotifier<String> {
  SearchMatchesNotifier(super.state);

  void updateSearch(String text) {
    if (state == text) return;
    state = text;
  }
}

final searchMatchesProvider =
    StateNotifierProvider<SearchMatchesNotifier, String>(
  (ref) {
    return SearchMatchesNotifier("");
  },
);
