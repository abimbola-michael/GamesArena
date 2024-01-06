import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameTimerNotifier extends StateNotifier<int> {
  GameTimerNotifier(super.state);
  void changeTime(int time) {
    state = time;
  }
}

final gameTimerProvider = StateNotifierProvider<GameTimerNotifier, int>((ref) {
  return GameTimerNotifier(30);
});
