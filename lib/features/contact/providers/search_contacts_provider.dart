import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchContactsNotifier extends StateNotifier<String> {
  SearchContactsNotifier(super.state);

  void updateSearch(String text) {
    state = text;
  }
}

final searchContactsProvider =
    StateNotifierProvider<SearchContactsNotifier, String>(
  (ref) {
    return SearchContactsNotifier("");
  },
);
