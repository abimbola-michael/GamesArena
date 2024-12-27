import 'package:flutter/cupertino.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../../../shared/models/models.dart';

class MatchScoresItem extends StatelessWidget {
  final Match match;
  final double fontSize;
  const MatchScoresItem({super.key, required this.match, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final overallOutcome = getMatchOverallOutcome(match);
    return Row(
      children: List.generate(match.players!.length, (index) {
        final user = match.users?[index];
        final score = overallOutcome.scores[index];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user?.username ?? "",
              style: context.bodyMedium?.copyWith(fontSize: fontSize),
            ),
            if (score != -1) ...[
              const SizedBox(width: 4),
              Text(
                "$score",
                style: context.bodyMedium
                    ?.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
              )
            ],
            if (index != match.players!.length - 1)
              Text(
                " - ",
                style: context.bodyMedium?.copyWith(fontSize: fontSize),
              ),
          ],
        );
      }),
    );
  }
}
