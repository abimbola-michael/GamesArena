import 'package:flutter_riverpod/flutter_riverpod.dart';

class InternetConnectionNotifier extends StateNotifier<bool?> {
  InternetConnectionNotifier(super.state);
  void updateConnection(bool connected) {
    if (state == connected) return;
    state = connected;
  }
}

final internetConnectionProvider =
    StateNotifierProvider<InternetConnectionNotifier, bool?>((ref) {
  return InternetConnectionNotifier(null);
});
