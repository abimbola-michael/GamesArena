import 'package:cached_network_image/cached_network_image.dart';
import 'package:gamesarena/features/match/widgets/match_summary_item.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../records/pages/match_records_page.dart';
import '../../user/services.dart';
import '../../game/utils.dart';
import 'match_arrow_signal.dart';
import '../../game/widgets/players_profile_photo.dart';

class MatchListItem extends StatelessWidget {
  final List<Match> matches;
  final int position;
  final bool isMatchRecords;
  final String? groupName;
  const MatchListItem(
      {super.key,
      required this.matches,
      required this.position,
      this.isMatchRecords = false,
      this.groupName});

  bool getDateVisibility() {
    if (position == 0) return true;

    return matches[position]
        .time_created!
        .datetime
        .showDate(matches[position - 1].time_created!.datetime);
  }

  Future<void> getDetails() async {
    final match = matches[position];

    if (match.users == null && match.players != null) {
      List<User> users = await playersToUsers(match.players!);
      match.users = users;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: getDetails(),
        builder: (context, snapshot) {
          final match = matches[position];
          if (match.users == null) return Container();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (getDateVisibility() && !isMatchRecords) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(match.time_created?.datetime.dateRange() ?? "",
                      style: TextStyle(fontSize: 14, color: lighterTint),
                      textAlign: TextAlign.center),
                ),
              ],
              InkWell(
                onTap: isMatchRecords
                    ? null
                    : () {
                        context.pushTo(
                          MatchRecordsPage(match: match, groupName: groupName),
                        );
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: Stack(
                          children: [
                            if (match.users != null)
                              PlayersProfilePhoto(
                                users: match.users!,
                                size: 55,
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: MatchArrowSignal(match: match),
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
                                    getPlayersVs(match.users ?? []),
                                    style: context.bodyMedium?.copyWith(
                                        color: tint,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  match.time_created?.time ?? "",
                                  style:
                                      TextStyle(fontSize: 12, color: lightTint),
                                )
                              ],
                            ),
                            //const SizedBox(height: 2),
                            MatchSummaryItem(match: match),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: Text(
                            //         getMatchRecordMessage(match),
                            //         style: TextStyle(
                            //           fontSize: 12,
                            //           color: match.creator_id != myId &&
                            //                   (match.time_start == "" ||
                            //                       match.time_start == null)
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
                            //     //     style: context.bodySmall?.copyWith(
                            //     //         color: duration == "live"
                            //     //             ? primaryColor
                            //     //             : lighterTint,
                            //     //         fontSize: 10),
                            //     //   ),
                            //     // ]
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }
}

// class MatchListItem extends StatefulWidget {
//   final Game? game;
//   final String gameId;
//   final List<Match> matches;
//   //final VoidCallback onPressed;
//   final List<User> users;
//   final int position;

//   const MatchListItem({
//     super.key,
//     required this.game,
//     required this.gameId,
//     required this.position,
//     required this.matches,
//     required this.users,
//   });

//   @override
//   State<MatchListItem> createState() => _MatchListItemState();
// }

// class _MatchListItemState extends State<MatchListItem> {
//   late Match match;
//   late int position;
//   String gameId = "";
//   List<Match> matches = [];
//   List<User> users = [];
//   String name = "";
//   String profilePhoto = "";
//   String matchMessage = "";
//   int duration = 0;
//   List<MatchRecord> matchRecords = [];
//   List<String> players = [];

//   @override
//   void initState() {
//     super.initState();
//     gameId = widget.gameId;
//     //users = widget.users;
//     matches = widget.matches;
//     position = widget.position;
//     match = matches[position];
//     if (match.players != null) {
//       players = match.players!;
//     }

//     getMatchDetails();
//   }

//   bool getDateVisibility() {
//     if (position == 0) return true;
//     return matches[position - 1]
//         .time_created!
//         .datetime
//         .showDate(match.time_created!.datetime);
//   }

//   void getMatchDetails() async {
//     List<String> usernames = [];
//     List<String> profilePhotos = [];
//     for (int i = 0; i < players.length; i++) {
//       final player = players[i];
//       final userBox = Hive.box<String>("users");
//       final userValue = userBox.get(player);
//       User? user = userValue == null ? null : User.fromJson(userValue);
//       user ??= await getUser(player);
//       if (user != null) {
//         users.add(user);
//         usernames.add(user.username);
//         profilePhotos.add(user.profile_photo ?? "");
//         userBox.put(player, user.toJson());
//       }
//       if (player == match.creator_id) {
//         name = match.creator_id == myId ? "Me" : user?.username ?? "";
//         profilePhoto = user?.profile_photo ?? "";
//       }
//     }
//     match.users = users;

//     // final userBox = Hive.box<String>("users");
//     // final userValue = userBox.get(match.creator_id);
//     // User? user = userValue == null ? null : User.fromJson(userValue);
//     // user ??= await getUser(match.creator_id!);
//     // name = match.creator_id == myId ? "Me" : user?.username ?? "";
//     // profilePhoto = user?.profile_photo ?? "";

//     if (match.time_start != null &&
//         match.time_start != "" &&
//         match.time_end != null &&
//         match.time_end != "") {
//       duration = int.parse(match.time_end!) - int.parse(match.time_start!);
//     }
//     if (match.time_start != null && match.time_start != "") {
//       if (match.records == null) {
//         matchRecords = [];
//       } else {
//         final length = match.records!.length;
//         for (int i = 0; i < length; i++) {
//           final value = match.records!["$i"];
//           if (value != null) {
//             matchRecords.add(MatchRecord.fromMap(value));
//           }
//         }
//       }
//       matchMessage = matchRecords.isEmpty
//           ? "0 game"
//           : "${matchRecords.last.game} - ${matchRecords.length} game${matchRecords.length == 1 ? "" : "s"}";
//     } else {
//       matchMessage = "Missed match";
//     }
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (getDateVisibility()) ...[
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               match.time_created?.datetime.dateRange() ?? "",
//               style: TextStyle(fontSize: 14, color: lighterTint),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//         // Container(
//         //   decoration: BoxDecoration(
//         //     borderRadius: BorderRadius.circular(20),
//         //     border: Border.all(
//         //       color: lightestTint,
//         //     ),
//         //   ),
//         //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         //   child: Column(
//         //     mainAxisSize: MainAxisSize.min,
//         //     children: [],
//         //   ),
//         // ),
//         InkWell(
//           onTap: () {
//             context.pushTo(
//               MatchRecordsPage(
//                 match: match,
//                 users: users,
//                 players: players,
//                 matchRecords: matchRecords,
//                 duration: duration,
//               ),
//             );
//           },
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               children: [
//                 Stack(
//                   children: [
//                     CircleAvatar(
//                       radius: 25,
//                       backgroundImage: profilePhoto.isNotEmpty
//                           ? CachedNetworkImageProvider(
//                               profilePhoto.contains(",")
//                                   ? profilePhoto.split(",").first
//                                   : profilePhoto)
//                           : null,
//                       backgroundColor: lightestWhite,
//                       child: profilePhoto.isNotEmpty
//                           ? null
//                           : Text(
//                               name.firstChar ?? "",
//                               style: const TextStyle(
//                                   fontSize: 30, color: Colors.blue),
//                             ),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: Container(
//                         height: 15,
//                         width: 15,
//                         decoration: BoxDecoration(
//                           // color: primaryColor,
//                           shape: BoxShape.circle,
//                           // border: Border.all(color: white),
//                           color: match.creator_id != myId &&
//                                   (match.time_start == "" ||
//                                       match.time_start == null)
//                               ? Colors.red
//                               : Colors.blue,
//                         ),
//                         child: Transform.rotate(
//                           angle: 45,
//                           child: Icon(
//                             match.creator_id == myId
//                                 ? Icons.arrow_upward
//                                 : Icons.arrow_downward,
//                             color: Colors.white,
//                             // color: match!.creator_id != myId &&
//                             //         (match!.time_start == "" ||
//                             //             match!.time_start == null)
//                             //     ? Colors.red
//                             //     : Colors.blue,
//                             size: 15,
//                           ),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               name,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: tint,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Text(
//                             match.time_created?.time ?? "",
//                             style: TextStyle(fontSize: 12, color: lightTint),
//                           )
//                         ],
//                       ),
//                       // const SizedBox(height: 2),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               matchMessage,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: match.creator_id != myId &&
//                                         (match.time_start == "" ||
//                                             match.time_start == null)
//                                     ? Colors.red
//                                     : lightTint,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // ListTile(
//         //   onTap: () {
//         //     Navigator.of(context).push(MaterialPageRoute(builder: (context) {
//         //       return MatchRecordsPage(
//         //         match: match,
//         //         users: users,
//         //         players: players,
//         //         matchRecords: matchRecords,
//         //         duration: duration,
//         //       );
//         //     }));
//         //   },
//         //   title: Row(
//         //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         //     children: [
//         //       Text(
//         //         match.creator_id != myId ? "Incoming" : "Outgoing",
//         //         style: TextStyle(
//         //             fontSize: 16,
//         //             color: darkMode ? Colors.white : Colors.black,
//         //             fontWeight: FontWeight.bold),
//         //       ),
//         //       Text(
//         //         match.time_created?.time ?? "",
//         //         style: TextStyle(
//         //             fontSize: 14,
//         //             color: darkMode
//         //                 ? Colors.white.withOpacity(0.7)
//         //                 : Colors.black.withOpacity(0.7)),
//         //       ),
//         //     ],
//         //   ),
//         //   subtitle: Row(
//         //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         //     children: [
//         //       Row(
//         //         mainAxisSize: MainAxisSize.min,
//         //         children: [
//         //           Icon(
//         //             match.creator_id == myId
//         //                 ? Icons.arrow_upward
//         //                 : Icons.arrow_downward,
//         //             color: match.creator_id != myId &&
//         //                     (match.time_start == "" || match.time_start == null)
//         //                 ? Colors.red
//         //                 : Colors.blue,
//         //             size: 15,
//         //           ),
//         //           const SizedBox(
//         //             width: 4,
//         //           ),
//         //           Text(
//         //             matchMessage,
//         //             style: TextStyle(
//         //                 fontSize: 16,
//         //                 color: match.creator_id != myId &&
//         //                         (match.time_start == "" ||
//         //                             match.time_start == null)
//         //                     ? Colors.red
//         //                     : darkMode
//         //                         ? Colors.white
//         //                         : Colors.black),
//         //           ),
//         //         ],
//         //       ),
//         //       if (duration != 0) ...[
//         //         Text(
//         //           duration.toDurationString(false),
//         //           style: TextStyle(
//         //               fontSize: 14,
//         //               color: darkMode
//         //                   ? Colors.white.withOpacity(0.6)
//         //                   : Colors.black.withOpacity(0.6)),
//         //         ),
//         //       ],
//         //     ],
//         //   ),
//         // ),
//       ],
//     );
//   }
// }
