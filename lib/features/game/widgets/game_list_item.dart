import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/game/widgets/players_profile_photo.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../user/services.dart';
import '../services.dart';
import 'match_arrow_signal.dart';
import 'match_scores_item.dart';

class GameListItem extends StatelessWidget {
  final GameList gameList;
  final VoidCallback onPressed;
  const GameListItem(
      {super.key, required this.gameList, required this.onPressed});

  Future<void> getDetails() async {
    //final matchesBox = Hive.box<String>("matches");
    gameList.game ??= await getGame(gameList.game_id);

    if (gameList.game != null &&
        gameList.game!.groupName == null &&
        gameList.game!.players != null &&
        gameList.game!.users == null) {
      final players = gameList.game!.players!;

      List<User> users = await playersToUsers(players);
      gameList.game!.users = users;
    }
    if (gameList.match != null &&
        gameList.match!.users == null &&
        gameList.match!.players != null) {
      List<User> users = await playersToUsers(gameList.match!.players!);
      gameList.match!.users = users;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: getDetails(),
        builder: (context, snapshot) {
          return InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      children: [
                        if (gameList.game?.users != null)
                          PlayersProfilePhoto(
                            users: gameList.game!.users!,
                            withoutMyId: true,
                          )
                        else if ((gameList.game?.groupName ?? "").isNotEmpty)
                          ProfilePhoto(
                            profilePhoto: gameList.game!.profilePhoto ?? "",
                            name: gameList.game!.groupName!,
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: gameList.match == null
                              ? Container()
                              : MatchArrowSignal(match: gameList.match!),
                        )
                      ],
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
                                gameList.game?.users != null
                                    ? getOtherPlayersUsernames(
                                        gameList.game!.users!)
                                    : gameList.game?.groupName != null
                                        ? gameList.game!.groupName!
                                        : "",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: tint,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              gameList.match?.time_created?.datetime
                                      .timeRange() ??
                                  "",
                              style: TextStyle(fontSize: 12, color: lightTint),
                            )
                          ],
                        ),
                        if (gameList.match != null) ...[
                          MatchScoresItem(match: gameList.match!),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: Text(
                          //         getPlayersVs(gameList.match!.users ?? []),
                          //         style:
                          //             context.bodyMedium?.copyWith(color: tint),
                          //       ),
                          //     ),
                          //     if ((gameList.unseen ?? 0) != 0) ...[
                          //       const SizedBox(width: 10),
                          //       Container(
                          //         padding: const EdgeInsets.symmetric(
                          //             horizontal: 10, vertical: 5),
                          //         decoration: BoxDecoration(
                          //           color: primaryColor,
                          //           borderRadius: BorderRadius.circular(20),
                          //         ),
                          //         child: Text(
                          //           "${gameList.unseen}",
                          //           style: context.bodySmall
                          //               ?.copyWith(color: white),
                          //         ),
                          //       ),
                          //     ]
                          //   ],
                          // ),
                          // //const SizedBox(height: 2),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: Text(
                          //         getMatchRecordMessage(gameList.match!),
                          //         style: TextStyle(
                          //           fontSize: 12,
                          //           color: gameList.match!.creator_id != myId &&
                          //                   (gameList.match!.time_start == "" ||
                          //                       gameList.match!.time_start ==
                          //                           null)
                          //               ? Colors.red
                          //               : lighterTint,
                          //         ),
                          //         // overflow: TextOverflow.ellipsis,
                          //         // maxLines: 1,
                          //       ),
                          //     ),
                          //     // if (duration.isNotEmpty) ...[
                          //     //   const SizedBox(width: 10),
                          //     //   Text(
                          //     //     duration,
                          //     //     style: context.bodyMedium?.copyWith(
                          //     //         color: duration == "live"
                          //     //             ? primaryColor
                          //     //             : lightTint),
                          //     //   ),
                          //     // ]
                          //   ],
                          // ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
