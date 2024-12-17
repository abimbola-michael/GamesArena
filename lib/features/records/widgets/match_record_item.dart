import 'package:flutter/material.dart';
import 'package:gamesarena/features/records/widgets/match_or_record_player_score_item.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../theme/colors.dart';
import '../models/match_record.dart';
import '../../game/models/match.dart';
import 'match_or_round_header_item.dart';

class MatchRecordItem extends StatelessWidget {
  final Match match;
  final MatchRecord record;
  final int index;
  final VoidCallback? onPressed;
  final VoidCallback onWatchPressed;
  final bool showPlayers;
  const MatchRecordItem(
      {super.key,
      required this.match,
      required this.record,
      required this.index,
      this.onPressed,
      required this.onWatchPressed,
      this.showPlayers = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MatchOrRoundHeaderItem(
                isRecord: true,
                timeStart: record.time_start,
                timeEnd: record.time_end,
                players: record.players,
                outcome: getMatchOutcomeMessageFromScores(
                    record.scores.toList().cast(), record.players,
                    users: match.users),
                index: index,
                onWatchPressed: onWatchPressed),
            if (showPlayers)
              ...List.generate(
                record.players.length,
                (index) {
                  final player = record.players[index];
                  final score = record.scores["$index"];
                  final matchOutcome = getMatchOutcome(
                      record.scores.toList().cast(), record.players);
                  return MatchOrRecordPlayerScoreItem(
                    users: match.users ?? [],
                    playerId: player,
                    score: score,
                    winners: matchOutcome.winners,
                  );
                },
              )
          ],
        ),
      ),
    );
  }
}
