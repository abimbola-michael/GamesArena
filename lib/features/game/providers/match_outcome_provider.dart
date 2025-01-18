import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/models/match_outcome.dart';

class MatchOutcomeNotifier extends StateNotifier<MatchOutcome?> {
  MatchOutcomeNotifier(super.state);

  void updateMatchOutcome(MatchOutcome matchOutcome) {
    state = matchOutcome;
  }
}

final matchOutcomeProvider =
    StateNotifierProvider<MatchOutcomeNotifier, MatchOutcome?>(
  (ref) {
    return MatchOutcomeNotifier(null);
  },
);
