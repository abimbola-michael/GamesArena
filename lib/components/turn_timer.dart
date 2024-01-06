// import 'dart:async';

// import 'package:flutter/cupertino.dart';
// import 'package:gamesarena/utils/utils.dart';

// class TurnTimer extends StatefulWidget {
//   final StreamController<int> controller;
//   const TurnTimer({super.key, required this.controller});

//   @override
//   State<TurnTimer> createState() => _TurnTimerState();
// }

// class _TurnTimerState extends State<TurnTimer>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   int time = 30;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<Object>(
//         stream: widget.controller.stream,
//         builder: (context, snapshot) {
//           return Text(
//             "Your Turn - $playerTime",
//             style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//                 color: darkMode ? Colors.white : Colors.black),
//             textAlign: TextAlign.center,
//           );
//         });
//   }
// }
