import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/game_list.dart';

class GameListNotifier extends StateNotifier<GameList?> {
  GameListNotifier(super.state);

  void updateGameList(GameList? gamelist) {
    state = gamelist;
  }
}

final gamelistProvider = StateNotifierProvider<GameListNotifier, GameList?>(
  (ref) {
    return GameListNotifier(null);
  },
);
