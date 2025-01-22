import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/utils.dart';
import '../../../theme/colors.dart';

class MatchSummaryItem extends StatelessWidget {
  final Match match;
  final double fontSize;
  const MatchSummaryItem({super.key, required this.match, this.fontSize = 14});

  int get timeDelayEnd => match.time_created!.toInt + (2 * 60 * 1000);

  Widget textWidget(BuildContext context, Color color, String action) {
    return Text(
      "$action, ${match.games!.toStringWithCommaandAnd((t) => t)}",
      style: context.bodyMedium?.copyWith(fontSize: 11, color: color),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
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
                  Flexible(
                    child: Text(
                      user?.username ?? "",
                      style: context.bodyMedium?.copyWith(
                          fontSize: fontSize, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (score != -1) ...[
                    const SizedBox(width: 4),
                    Text(
                      "$score",
                      style: context.bodyMedium?.copyWith(
                          fontSize: fontSize, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  ],
                  if (index != match.players!.length - 1)
                    Text(
                      " - ",
                      style: context.bodyMedium?.copyWith(fontSize: fontSize),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            );
          }),
        ),
        if ((match.games ?? []).isNotEmpty)
          if (match.time_start == null &&
              match.time_end == null &&
              (timeDelayEnd > timeNow.toInt))
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
                match.time_start == null
                    ? Colors.red
                    : match.time_end != null
                        ? lighterTint
                        : primaryColor,
                match.time_start == null
                    ? "Missed"
                    : match.time_end != null
                        ? getMatchOutcomeMessageFromScores(
                            overallOutcome.scores, match.players ?? [],
                            users: match.users)
                        : "Live")
      ],
    );
  }
}
