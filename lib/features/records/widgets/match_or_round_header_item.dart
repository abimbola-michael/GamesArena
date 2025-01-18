import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/utils/utils.dart';
import '../../../theme/colors.dart';

class MatchOrRoundHeaderItem extends StatelessWidget {
  final String? title;
  final bool isRecord;
  final String? timeCreated;

  final String? timeStart;
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
      this.timeCreated,
      this.timeEnd,
      required this.duration,
      required this.game,
      required this.players,
      required this.outcome,
      this.index = 0,
      required this.onWatchPressed});

  String getGameTime() {
    return timeStart == null
        ? ""
        : "${timeStart!.time} - ${timeEnd != null && timeStart!.date != timeEnd!.date ? "${timeEnd!.date} " : ""}${timeEnd?.time ?? "Live"}";
  }

  String getGameDuration() {
    return duration?.toInt().toDurationString() ?? "";
  }

  int get timeDelayEnd =>
      timeCreated == null ? 0 : timeCreated!.toInt + (2 * 60 * 1000);

  Widget textWidget(BuildContext context, Color color, String action) {
    return Text(
      "${players.length} players, $game, $action",
      style: context.bodySmall?.copyWith(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onWatchPressed,
            child: Icon(
              timeStart == null
                  ? EvaIcons.refresh_outline
                  : EvaIcons.play_circle_outline,
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
                        child: timeCreated != null &&
                                (timeStart == null &&
                                    timeEnd == null &&
                                    (timeDelayEnd > timeNow.toInt))
                            ? FutureBuilder(
                                future: Future.delayed(Duration(
                                    milliseconds:
                                        timeDelayEnd - timeNow.toInt)),
                                builder: (context, snapshot) {
                                  final ended = snapshot.connectionState ==
                                      ConnectionState.done;
                                  return textWidget(
                                      context,
                                      ended ? Colors.red : Colors.yellow,
                                      ended ? "Missed" : "Awaiting");
                                })
                            : textWidget(
                                context,
                                timeStart == null
                                    ? Colors.red
                                    : timeEnd != null
                                        ? lighterTint
                                        : primaryColor,
                                timeStart == null
                                    ? "Missed"
                                    : timeEnd != null
                                        ? outcome
                                        : "Live")),
                    if (timeStart != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        getGameDuration(),
                        style: context.bodySmall?.copyWith(color: lighterTint),
                      )
                    ],
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
