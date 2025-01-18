import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/records/widgets/match_or_round_header_item.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import '../../../theme/colors.dart';
import '../../game/models/match.dart';

import '../models/match_round.dart';
import 'match_or_record_player_score_item.dart';

class MatchRoundItem extends StatelessWidget {
  final Match match;
  final MatchRound round;
  final int index;
  final VoidCallback onWatchPressed;
  const MatchRoundItem(
      {super.key,
      required this.match,
      required this.round,
      required this.index,
      required this.onWatchPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MatchOrRoundHeaderItem(
            isRecord: false,
            game: round.game,
            timeCreated: match.time_created,
            timeStart: round.time_start,
            timeEnd: round.time_end,
            duration: round.duration,
            players: round.players,
            outcome: getMatchOutcomeMessageFromWinners(
                round.winners, round.players,
                users: match.users),
            index: index,
            onWatchPressed: onWatchPressed,
          ),
          ...List.generate(
            round.players.length,
            (index) {
              final player = round.players[index];
              final score = round.scores["$index"];
              final winners =
                  round.winners?.map((e) => round.players[e]).toList();
              return MatchOrRecordPlayerScoreItem(
                  users: match.users ?? [],
                  playerId: player,
                  score: score,
                  winners: winners);
            },
          )
        ],
      ),
    );
  }
}
