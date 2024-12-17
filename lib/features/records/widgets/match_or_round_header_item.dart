import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../theme/colors.dart';

class MatchOrRoundHeaderItem extends StatelessWidget {
  final bool isRecord;
  final String timeStart;
  final String? timeEnd;
  final List<String> players;
  final String outcome;
  final int index;
  final VoidCallback onWatchPressed;
  const MatchOrRoundHeaderItem(
      {super.key,
      required this.isRecord,
      required this.timeStart,
      this.timeEnd,
      required this.players,
      required this.outcome,
      required this.index,
      required this.onWatchPressed});

  String getGameTime() {
    return "${timeStart.time} - ${timeEnd?.time ?? "Live"}";
  }

  String getGameDuration() {
    return timeEnd != null
        ? ((timeEnd!.toInt - timeStart.toInt) ~/ 1000).toDurationString()
        : "";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onWatchPressed,
            child: const Icon(
              EvaIcons.play_circle_outline,
              size: 30,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${isRecord ? "Record" : "Round"} ${index + 1}",
                        style: context.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isRecord ? 16 : 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      getGameTime(),
                      style: context.bodySmall?.copyWith(color: lightTint),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${players.length} players, $outcome",
                        style: context.bodySmall?.copyWith(color: lightTint),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      getGameDuration(),
                      style: context.bodySmall?.copyWith(color: lighterTint),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
