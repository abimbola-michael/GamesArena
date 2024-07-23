import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerTimerNotifier extends StateNotifier<int> {
  PlayerTimerNotifier(super.state);
  void updateTime(int time) {
    state = time;
  }
}

final playerTimerProvider =
    StateNotifierProvider<PlayerTimerNotifier, int>((ref) {
  return PlayerTimerNotifier(30);
});
