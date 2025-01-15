import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../../../shared/utils/utils.dart';
import '../../../theme/colors.dart';
import '../../game/models/match.dart';

class MatchArrowSignal extends StatelessWidget {
  final Match match;
  const MatchArrowSignal({super.key, required this.match});
  int get timeDelayEnd => match.time_created!.toInt + (2 * 60 * 1000);

  Widget arrowWidget(Color color) {
    return Container(
      height: 15,
      width: 15,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Transform.rotate(
        angle: 45,
        child: Icon(
          match.creator_id == myId ? Icons.arrow_upward : Icons.arrow_downward,
          color: Colors.white,
          size: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 15,
      width: 15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 15,
            width: 15,
            decoration: BoxDecoration(shape: BoxShape.circle, color: offtint),
          ),
          if (match.time_start == null && (timeDelayEnd > timeNow.toInt))
            FutureBuilder(
                future: Future.delayed(
                    Duration(milliseconds: timeDelayEnd - timeNow.toInt)),
                builder: (context, snapshot) {
                  final ended =
                      snapshot.connectionState == ConnectionState.done;
                  return arrowWidget(ended ? Colors.red : Colors.yellow);
                })
          else
            arrowWidget(match.time_end != null
                ? lighterTint
                : match.time_start == null
                    ? Colors.red
                    : primaryColor)
        ],
      ),
    );
  }
}
