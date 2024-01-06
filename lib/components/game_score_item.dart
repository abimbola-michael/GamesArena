import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../blocs/firebase_service.dart';
import '../styles/colors.dart';
import '../utils/utils.dart';

class GameScoreItem extends StatefulWidget {
  final String username;
  final String action;
  final int score;

  const GameScoreItem(
      {super.key,
      required this.username,
      required this.score,
      required this.action});

  @override
  State<GameScoreItem> createState() => _GameScoreItemState();
}

class _GameScoreItemState extends State<GameScoreItem> {
  FirebaseService fs = FirebaseService();
  String myId = "";
  @override
  void initState() {
    super.initState();
    myId = fs.myId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: lightestWhite,
              child: Text(
                widget.username.firstChar ?? "",
                style: const TextStyle(fontSize: 30, color: Colors.blue),
              ),
            ),
            if (widget.action == "start") ...[
              const Positioned(
                bottom: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.check,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ],
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          widget.username,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          '${widget.score}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 60, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        if (widget.action != "") ...[
          const SizedBox(
            height: 4,
          ),
          Text(
            getActionString(widget.action).capitalize,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ]
      ],
    );
  }
}
