import 'dart:async';

import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class GameTimer extends StatefulWidget {
  final Stream<int> timerStream;
  final int? time;
  const GameTimer({super.key, required this.timerStream, this.time});

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  @override
  Widget build(BuildContext context) {
    Widget buildChild(int time) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        // padding: const EdgeInsets.symmetric(vertical: 8),
        // alignment: Alignment.center,
        //width: 50,
        decoration: BoxDecoration(
            color: darkMode ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(20)),
        child: Text(time.toDurationString(),
            style: TextStyle(
                color: darkMode ? Colors.black : Colors.white, fontSize: 12)),
      );
    }

    if (widget.time != null) return buildChild(widget.time!);
    return StreamBuilder(
        stream: widget.timerStream,
        builder: (context, snapshot) {
          final time = snapshot.data ?? 0;
          return buildChild(time);
        });
  }
}
// class TimerNotifier extends ChangeNotifier {
//   int time = 0, time2 = 0;
//   void updateTimer(int time) {
//     this.time = time;
//     notifyListeners();
//   }

//   void updateSecondTimer(int time2) {
//     this.time2 = time2;
//     notifyListeners();
//   }
// }
