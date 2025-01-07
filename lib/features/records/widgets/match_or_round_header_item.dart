import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../theme/colors.dart';

class MatchOrRoundHeaderItem extends StatelessWidget {
  final String? title;
  final bool isRecord;
  final String timeStart;
  final String? timeEnd;
  final double? duration;
  final List<String> players;
  final String game;
  final String outcome;
  final int index;
  final VoidCallback onWatchPressed;
  const MatchOrRoundHeaderItem(
      {super.key,
      this.title,
      this.isRecord = false,
      required this.timeStart,
      this.timeEnd,
      required this.duration,
      required this.game,
      required this.players,
      required this.outcome,
      this.index = 0,
      required this.onWatchPressed});

  String getGameTime() {
    return "${timeStart.time} - ${timeEnd != null && timeStart.date != timeEnd!.date ? "${timeEnd!.date} " : ""}${timeEnd?.time ?? "Live"}";
  }

  String getGameDuration() {
    return duration?.toInt().toDurationString() ?? "";
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
                        title ??
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
                        "${players.length} players, $outcome, $game",
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
