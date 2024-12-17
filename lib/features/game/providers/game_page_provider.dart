import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_action.dart';

class GamePageNotifier extends StateNotifier<String> {
  GamePageNotifier(super.state);

  void updateGamePage(String page) {
    state = page;
  }

  @override
  void dispose() {
    state = "";
    super.dispose();
  }
}

final gamePageProvider = StateNotifierProvider<GamePageNotifier, String>(
  (ref) {
    return GamePageNotifier("");
  },
);
