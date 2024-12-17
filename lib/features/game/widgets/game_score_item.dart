import 'package:cached_network_image/cached_network_image.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';

class GameScoreItem extends StatelessWidget {
  final String username;
  final String? profilePhoto;

  final String action;
  final String? callMode;
  final int score;

  const GameScoreItem(
      {super.key,
      required this.username,
      required this.score,
      required this.action,
      this.callMode,
      this.profilePhoto});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: profilePhoto != null
                  ? CachedNetworkImageProvider(profilePhoto!)
                  : null,
              backgroundColor: lightestWhite,
              child: profilePhoto != null
                  ? null
                  : Text(
                      username.firstChar ?? "",
                      style: const TextStyle(fontSize: 30, color: Colors.blue),
                    ),
            ),
            if (action == "start") ...[
              const Positioned(
                bottom: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    EvaIcons.checkmark,
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
          username,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          '$score',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 60, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        if (action != "") ...[
          // const SizedBox(
          //   height: 4,
          // ),
          Text(
            getActionString(action).capitalize,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (callMode != null) ...[
          const SizedBox(
            height: 4,
          ),
          Text(
            "${callMode!.capitalize} call",
            style: const TextStyle(
                fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ]
      ],
    );
  }
}
