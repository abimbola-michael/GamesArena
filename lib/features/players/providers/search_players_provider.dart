import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchPlayersNotifier extends StateNotifier<String> {
  SearchPlayersNotifier(super.state);

  void updateSearch(String text) {
    state = text;
  }
}

final searchPlayersProvider =
    StateNotifierProvider<SearchPlayersNotifier, String>(
  (ref) {
    return SearchPlayersNotifier("");
  },
);
