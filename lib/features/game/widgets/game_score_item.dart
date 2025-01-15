import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../shared/utils/utils.dart';
import 'profile_photo.dart';

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
        SizedBox(
          height: 50,
          width: 50,
          child: Stack(
            children: [
              ProfilePhoto(
                  profilePhoto: profilePhoto, name: username, size: 50),
              if (action == "start") ...[
                const Positioned(
                  bottom: 0,
                  right: 0,
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
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          username,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // const SizedBox(
        //   height: 4,
        // ),
        SizedBox(
          child: Text(
            '$score',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 60,
                height: 1,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        // if (action != "") ...[
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
        // ],
        if (callMode != null) ...[
          const SizedBox(
            height: 4,
          ),
          Text(
            "${callMode!.capitalize} call",
            style: const TextStyle(
                fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }
}
