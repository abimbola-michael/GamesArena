import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/match.dart';

class MatchNotifier extends StateNotifier<Match?> {
  MatchNotifier(super.state);

  void updateMatch(Match? match) {
    state = match;
  }
}

final matchProvider = StateNotifierProvider<MatchNotifier, Match?>(
  (ref) {
    return MatchNotifier(null);
  },
);
