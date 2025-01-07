import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchGamesNotifier extends StateNotifier<String> {
  SearchGamesNotifier(super.state);

  void updateSearch(String text) {
    if (state == text) return;
    state = text;
  }
}

final searchGamesProvider = StateNotifierProvider<SearchGamesNotifier, String>(
  (ref) {
    return SearchGamesNotifier("");
  },
);
