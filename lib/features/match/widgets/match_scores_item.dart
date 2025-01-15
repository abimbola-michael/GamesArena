import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/utils.dart';
import '../../../theme/colors.dart';

class MatchScoresItem extends StatelessWidget {
  final Match match;
  final double fontSize;
  const MatchScoresItem({super.key, required this.match, this.fontSize = 14});

  int get timeDelayEnd => match.time_created!.toInt + (2 * 60 * 1000);

  Widget textWidget(BuildContext context, Color color, String action) {
    return Text(
      "${match.games!.toStringWithCommaandAnd((t) => t)}, $action",
      style: context.bodyMedium?.copyWith(fontSize: 11, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallOutcome = getMatchOverallOutcome(match);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(match.players!.length, (index) {
            final user = match.users?.get(index);
            final score = overallOutcome.scores.get(index);
            return Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.username ?? "",
                    style: context.bodyMedium?.copyWith(
                        fontSize: fontSize, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (score != -1) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "$score",
                        style: context.bodyMedium?.copyWith(
                            fontSize: fontSize, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                  ],
                  if (index != match.players!.length - 1)
                    Flexible(
                      child: Text(
                        " - ",
                        style: context.bodyMedium?.copyWith(fontSize: fontSize),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        if ((match.games ?? []).isNotEmpty)
          if (match.time_start == null && (timeDelayEnd > timeNow.toInt))
            FutureBuilder(
                future: Future.delayed(
                    Duration(milliseconds: timeDelayEnd - timeNow.toInt)),
                builder: (context, snapshot) {
                  final ended =
                      snapshot.connectionState == ConnectionState.done;
                  return textWidget(context, ended ? Colors.red : Colors.yellow,
                      ended ? "Missed" : "Awaiting");
                })
          else
            textWidget(
                context,
                match.time_end != null
                    ? lighterTint
                    : match.time_start == null
                        ? Colors.red
                        : primaryColor,
                match.time_end != null
                    ? getMatchOutcomeMessageFromScores(
                        overallOutcome.scores, match.players ?? [],
                        users: match.users)
                    : match.time_start == null
                        ? "Missed"
                        : "Live")
      ],
    );
  }
}
