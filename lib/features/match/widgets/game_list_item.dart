import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/game/widgets/players_profile_photo.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../user/services.dart';
import '../../game/services.dart';
import 'match_arrow_signal.dart';
import 'match_summary_item.dart';

class GameListItem extends StatelessWidget {
  final GameList gameList;
  final VoidCallback onPressed;
  const GameListItem(
      {super.key, required this.gameList, required this.onPressed});

  Future<void> getDetails() async {
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
                    width: 55,
                    height: 55,
                    child: Stack(
                      children: [
                        if (gameList.game?.users != null)
                          PlayersProfilePhoto(
                            users: gameList.game!.users!,
                            withoutMyId: true,
                            size: 55,
                          )
                        else if ((gameList.game?.groupName ?? "").isNotEmpty)
                          ProfilePhoto(
                            profilePhoto: gameList.game!.profilePhoto ?? "",
                            name: gameList.game!.groupName!,
                            size: 55,
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: gameList.match == null ||
                                  gameList.time_end != null
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
                                style: context.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                        Row(
                          children: [
                            Expanded(
                                child: gameList.time_end != null
                                    ? Text(
                                        "You ${gameList.game?.groupName != null ? "left" : "blocked"}",
                                        style: context.bodySmall)
                                    : gameList.match != null
                                        ? MatchSummaryItem(
                                            match: gameList.match!)
                                        : Container()),
                            if ((gameList.unseen ?? 0) != 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                // padding: const EdgeInsets.symmetric(
                                //     horizontal: 8, vertical: 4),
                                constraints: const BoxConstraints(
                                    minWidth: 24, minHeight: 24, maxHeight: 24),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${gameList.unseen}",
                                  style:
                                      context.bodySmall?.copyWith(color: white),
                                ),
                              ),
                            ]
                          ],
                        ),
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
