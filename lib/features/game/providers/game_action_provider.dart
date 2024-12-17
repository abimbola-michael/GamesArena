import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_action.dart';

class GameActionNotifier extends StateNotifier<GameAction?> {
  GameActionNotifier(super.state);

  void updateGameAction(GameAction? gameAction) {
    state = gameAction;
  }
}

final gameActionProvider =
    StateNotifierProvider<GameActionNotifier, GameAction?>(
  (ref) {
    return GameActionNotifier(null);
  },
);
