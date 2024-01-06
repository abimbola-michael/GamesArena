import 'dart:async';

import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class GameTimer extends StatefulWidget {
  final Stream<int> timerStream;
  const GameTimer({super.key, required this.timerStream});

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget.timerStream,
        builder: (context, snapshot) {
          final time = snapshot.data ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: darkMode ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(20)),
            child: Text(time.toDurationString(),
                style:
                    TextStyle(color: darkMode ? Colors.black : Colors.white)),
          );
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
