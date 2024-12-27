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
import 'match_arrow_signal.dart';
import 'match_scores_item.dart';

class GameListItem extends StatelessWidget {
  final GameList gameList;
  final VoidCallback onPressed;
  const GameListItem(
      {super.key, required this.gameList, required this.onPressed});

  Future<void> getDetails() async {
    //final matchesBox = Hive.box<String>("matches");
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
      //Hive.box<String>("gamelists").put(gameList.game_id, gameList.toJson());
    }
    // if (update) {
    //   final gameListsBox = Hive.box<String>("gamelists");
    //   gameListsBox.put(gameList.game_id, gameList.toJson());
    // }
  }

  @override
  Widget build(BuildContext context) {
    //final duration = getMatchDuration(gameList.match);
    // print("gameList = $gameList");
    return FutureBuilder<void>(
        future: getDetails(),
        builder: (context, snapshot) {
          //print("gameListAfter = $gameList");

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
                              : MatchArrowSignal(
                                  match: gameList.match!,
                                ),
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

// class GameListItem extends StatefulWidget {
//   final GameList gameList;
//   final VoidCallback onPressed;

//   const GameListItem(
//       {super.key, required this.gameList, required this.onPressed});

//   @override
//   State<GameListItem> createState() => _GameListItemState();
// }

// class _GameListItemState extends State<GameListItem> {
//   late GameList gameList;
//   User? user;
//   List<User> users = [];
//   Group? group;
//   Match? match;
//   Game? game;
//   String game_id = "", type = "";
//   String name = "";
//   String profilePhoto = "";
//   String lastSeen = "";
//   String matchMessage = "";
//   List<String> players = [];
//   List<MatchRecord> matchRecords = [];
//   int missedMatchesCount = 0;
//   @override
//   void initState() {
//     super.initState();
//     gameList = widget.gameList;
//     game_id = gameList.game_id;
//     getGameDetails();
//   }

//   void getGameDetails() async {
//     //final game = await getGame(game_id);
//     final game = gameList.game;
//     this.game = game;
//     if (game != null) {
//       if (game.profilePhoto != null) {
//         profilePhoto = game.profilePhoto!;
//       }
//       if (game.groupName != null) {
//         name = game.groupName!;
//         if (name.contains(",")) {
//           name = name.split(",").toStringWithCommaandAnd((t) => t);
//         }
//       } else if (game.players != null) {
//         List<String> ids = game.players!;
//         users = await playersToUsers(ids);
//         final opponentUsers =
//             users.where((element) => element.user_id != myId).toList();
//         name = opponentUsers.toStringWithCommaandAnd((user) => user.username);
//         profilePhoto =
//             opponentUsers.map((e) => e.profile_photo ?? "").join(",");
//       }

//       setState(() {});
//     }
//     //final matches = await getMatches(game_id);
//     //final match = matches.isNotEmpty ? matches.last : null;
//     final match = gameList.match;
//     this.match = match;
//     if (match != null) {
//       if (match.time_start != null && match.time_start != "") {
//         if (match.records == null) {
//           matchRecords = [];
//         } else {
//           final length = match.records!.length;
//           for (int i = 0; i < length; i++) {
//             final value = match.records!["$i"];
//             if (value != null) {
//               matchRecords.add(MatchRecord.fromMap(value));
//             }
//           }
//         }
//         //matchRecords = await getMatchRecords(game_id, match.match_id!);
//         matchMessage = matchRecords.isEmpty
//             ? "0 games"
//             : "${matchRecords.last.game} - ${matchRecords.length} game${matchRecords.length == 1 ? "" : "s"}";
//       } else {
//         matchMessage = "Missed match";
//         // getMissedMatchCount(matches);
//         // matchMessage =
//         //     "$missedMatchesCount Missed match${missedMatchesCount == 1 ? "" : "es"}";
//       }
//     }
//     setState(() {});
//   }

//   void getMissedMatchCount(List<Match> matches) {
//     for (int i = matches.length - 1; i >= 0; i--) {
//       final match = matches[i];
//       if (match.time_start == "" || match.time_start == null) {
//         missedMatchesCount++;
//       } else {
//         return;
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     gameList = widget.gameList;
//     print("gameListItem = ${gameList}");

//     return InkWell(
//       onTap: widget.onPressed,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         child: Row(
//           children: [
//             Stack(
//               children: [
//                 CircleAvatar(
//                   radius: 25,
//                   backgroundImage: profilePhoto.isNotEmpty
//                       ? CachedNetworkImageProvider(profilePhoto.contains(",")
//                           ? profilePhoto.split(",").first
//                           : profilePhoto)
//                       : null,
//                   backgroundColor: lightestWhite,
//                   child: profilePhoto.isNotEmpty
//                       ? null
//                       : Text(
//                           name.firstChar ?? "",
//                           style:
//                               const TextStyle(fontSize: 30, color: Colors.blue),
//                         ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: Container(
//                     height: 15,
//                     width: 15,
//                     decoration: BoxDecoration(
//                       // color: primaryColor,
//                       shape: BoxShape.circle,
//                       // border: Border.all(color: white),
//                       color: match?.creator_id != myId &&
//                               (match?.time_start == "" ||
//                                   match?.time_start == null)
//                           ? Colors.red
//                           : Colors.blue,
//                     ),
//                     child: Transform.rotate(
//                       angle: 45,
//                       child: Icon(
//                         match?.creator_id == myId
//                             ? Icons.arrow_upward
//                             : Icons.arrow_downward,
//                         color: Colors.white,
//                         // color: match!.creator_id != myId &&
//                         //         (match!.time_start == "" ||
//                         //             match!.time_start == null)
//                         //     ? Colors.red
//                         //     : Colors.blue,
//                         size: 15,
//                       ),
//                     ),
//                   ),
//                 )
//               ],
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           name,
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: tint,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Text(
//                         match?.time_created?.datetime.timeRange() ?? "",
//                         style: TextStyle(fontSize: 12, color: lightTint),
//                       )
//                     ],
//                   ),
//                   if (match != null) ...[
//                     // const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             matchMessage,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: match!.creator_id != myId &&
//                                       (match!.time_start == "" ||
//                                           match!.time_start == null)
//                                   ? Colors.red
//                                   : lightTint,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                             maxLines: 1,
//                           ),
//                         ),
//                         if ((gameList.unseen ?? 0) != 0) ...[
//                           const SizedBox(width: 10),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 10, vertical: 5),
//                             decoration: BoxDecoration(
//                               color: primaryColor,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               "${gameList.unseen}",
//                               style: context.bodySmall?.copyWith(color: white),
//                             ),
//                           ),
//                         ]
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
    // return ListTile(
    //   contentPadding: const EdgeInsets.all(8),
    //   onTap: widget.onPressed,
    //   leading: Stack(
    //     children: [
    //       CircleAvatar(
    //         backgroundColor: darkMode ? lightestWhite : lightestBlack,
    //         radius: 30,
    //         child: Text(
    //           name.firstChar ?? "",
    //           style: const TextStyle(fontSize: 30, color: Colors.blue),
    //         ),
    //       ),
    //       // if (lastSeen == "") ...[
    //       //   const Positioned(
    //       //     bottom: 4,
    //       //     right: 4,
    //       //     child: CircleAvatar(
    //       //       radius: 4,
    //       //       backgroundColor: Colors.green,
    //       //     ),
    //       //   )
    //       // ],
    //     ],
    //   ),
    //   // trailing: match == null
    //   //     ? null
    //   //     : Text(
    //   //         match!.time_created?.datetime.timeRange() ?? "",
    //   //         style: TextStyle(fontSize: 14, color: lightTint),
    //   //       ),
    //   title: Row(
    //     children: [
    //       Expanded(
    //         child: Text(
    //           name,
    //           style: TextStyle(
    //             fontSize: 16,
    //             color: darkMode ? Colors.white : Colors.black,
    //             fontWeight: FontWeight.bold,
    //           ),
    //           overflow: TextOverflow.ellipsis,
    //           maxLines: 1,
    //         ),
    //       ),
    //       const SizedBox(width: 10),
    //       Text(
    //         match?.time_created?.datetime.timeRange() ?? "",
    //         style: TextStyle(fontSize: 14, color: lightTint),
    //       )
    //     ],
    //   ),
    //   subtitle: match == null
    //       ? null
    //       : Row(
    //           children: [
    //             Transform.rotate(
    //               angle: 45,
    //               child: Icon(
    //                 match!.creator_id == myId
    //                     ? Icons.arrow_upward
    //                     : Icons.arrow_downward,
    //                 color: match!.creator_id != myId &&
    //                         (match!.time_start == "" ||
    //                             match!.time_start == null)
    //                     ? Colors.red
    //                     : Colors.blue,
    //                 size: 15,
    //               ),
    //             ),
    //             const SizedBox(
    //               width: 4,
    //             ),
    //             Expanded(
    //               child: Text(
    //                 matchMessage,
    //                 style: TextStyle(
    //                   fontSize: 16,
    //                   color: match!.creator_id != myId &&
    //                           (match!.time_start == "" ||
    //                               match!.time_start == null)
    //                       ? Colors.red
    //                       : tint,
    //                 ),
    //                 overflow: TextOverflow.ellipsis,
    //                 maxLines: 1,
    //               ),
    //             ),
    //             if ((gameList.unseen ?? 0) != 0) ...[
    //               const SizedBox(width: 10),
    //               Container(
    //                 decoration:
    //                     BoxDecoration(borderRadius: BorderRadius.circular(10)),
    //                 child: Text(
    //                   "${gameList.unseen}",
    //                   style: context.bodySmall?.copyWith(color: white),
    //                 ),
    //               ),
    //             ]
    //           ],
    //         ),
    // );
//   }
// }
