import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/records/widgets/match_or_record_player_score_item.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../theme/colors.dart';
import '../models/match_record.dart';
import '../../game/models/match.dart';
import 'match_or_round_header_item.dart';

class MatchOverallRecordItem extends StatelessWidget {
  final Match match;
  final VoidCallback? onPressed;
  final VoidCallback onWatchPressed;
  final bool showPlayers;
  const MatchOverallRecordItem(
      {super.key,
      required this.match,
      this.onPressed,
      required this.onWatchPressed,
      this.showPlayers = true});

  @override
  Widget build(BuildContext context) {
    final overallOutcome = getMatchOverallOutcome(match);
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MatchOrRoundHeaderItem(
                title: "Overall Record",
                game: match.games?.join(", ") ?? "",
                timeStart: match.time_start ?? "",
                timeEnd: match.time_end,
                duration: getMatchDuration(match),
                players: match.players!,
                outcome: getMatchOutcomeMessageFromScores(
                    overallOutcome.scores.toList().cast(), match.players!,
                    users: match.users),
                onWatchPressed: onWatchPressed),
            if (showPlayers)
              ...List.generate(
                match.players!.length,
                (index) {
                  final player = match.players![index];
                  final score = overallOutcome.scores[index];
                  final games = overallOutcome.games[index];
                  final matchOutcome = getMatchOutcome(
                      overallOutcome.scores.toList().cast(), match.players!);
                  return MatchOrRecordPlayerScoreItem(
                    users: match.users ?? [],
                    playerId: player,
                    score: score,
                    winners: matchOutcome.winners,
                    message: getGamesWonMessage(games),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
