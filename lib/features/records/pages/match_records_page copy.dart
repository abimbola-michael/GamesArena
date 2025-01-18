// import 'package:flutter/cupertino.dart';
// import 'package:flutter/widgets.dart';
// import 'package:gamesarena/features/game/utils.dart';
// import 'package:gamesarena/features/game/widgets/match_list_item.dart';
// import 'package:gamesarena/features/user/services.dart';
// import 'package:gamesarena/shared/extensions/extensions.dart';
// import 'package:flutter/material.dart';
// import 'package:gamesarena/shared/models/models.dart';
// import '../../../shared/widgets/action_button.dart';
// import '../../../shared/widgets/app_appbar.dart';
// import '../../user/widgets/user_item.dart';
// import '../../../shared/services.dart';
// import 'package:gamesarena/features/game/models/match.dart';
// import '../models/match_record.dart';
// import '../../user/models/user.dart';
// import '../../../theme/colors.dart';
// import '../../../shared/utils/utils.dart';

// class MatchRecordsPage extends StatefulWidget {
//   final Match match;

//   const MatchRecordsPage({
//     super.key,
//     required this.match,
//   });

//   @override
//   State<MatchRecordsPage> createState() => _MatchRecordsPageState();
// }

// class _MatchRecordsPageState extends State<MatchRecordsPage> {
//   String name = "";
//   late Match match;
//   List<User> users = [];
//   //List<String> players = [];
//   List<MatchRecord> matchRecords = [];
//   //List<List<int?>> allScores = [];
//   @override
//   void initState() {
//     super.initState();
//     match = widget.match;
//     getDetails();
//   }

//   Future<void> getDetails() async {
//     // final length = match.records!.length;

//     if (match.users == null && match.players != null) {
//       List<User> users = await playersToUsers(match.players!);
//       match.users = users;
//     }
//     users = match.users!;
//     matchRecords = getMatchRecords(match);
//     //allScores = getMatchOverallTotalScores(match);

//     if (!mounted) return;
//     setState(() {});

//     // if (update) {
//     //   final matchesBox = Hive.box<String>("matches");
//     //   matchesBox.put(game_id, toJson());
//     // }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const AppAppBar(title: "Match Records"),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           MatchListItem(matches: [match], position: 0, isMatchRecords: true),
//           if (matchRecords.isNotEmpty) ...[
//             SizedBox(
//               height: 100,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 50),
//                 child: Row(
//                   //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: List.generate(
//                     users.length,
//                     (index) {
//                       final user = users[index];
//                       return Expanded(
//                         child: Center(
//                           child:
//                               UserItem(user: user, type: "", onPressed: () {}),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: matchRecords.length,
//                 itemBuilder: (context, index) {
//                   final record = matchRecords[index];
//                   final rounds = record.rounds;
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         "Round ${index + 1}",
//                         style: context.bodyLarge
//                             ?.copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         getGameTime(record.time_start, record.time_end),
//                         style: context.bodySmall?.copyWith(color: lighterTint),
//                       ),
//                       ...List.generate(rounds.length, (index) {
//                         return Column(
//                           mainAxisSize: MainAxisSize.min,
//                         );
//                       }),
//                       if (index == 0 ||
//                           record.game != matchRecords[index - 1].game) ...[
//                         Padding(
//                           padding: const EdgeInsets.all(4.0),
//                           child: Text(
//                             record.game,
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: index == matchRecords.length
//                                   ? primaryColor
//                                   : tint,
//                             ),
//                           ),
//                         ),
//                       ],
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 8.0),
//                         child: Row(
//                           children: [
//                             Container(
//                               alignment: Alignment.center,
//                               width: 50,
//                               child: Text(
//                                 index == matchRecords.length
//                                     ? "="
//                                     : "${index + 1}.",
//                                 style: context.bodyLarge
//                                     ?.copyWith(color: lightTint),
//                               ),
//                             ),
//                             Expanded(
//                               child: Row(
//                                 // mainAxisAlignment:
//                                 //     MainAxisAlignment.spaceBetween,
//                                 children: List.generate(
//                                   users.length,
//                                   (index) {
//                                     //int? score = scores[index];
//                                     int? score = record?.scores["$index"];
//                                     return Expanded(
//                                       // width: context.screenWidth /
//                                       //     players.length,
//                                       child: Center(
//                                         child: Text(
//                                           score == null ? "-" : "$score",
//                                           textAlign: TextAlign.center,
//                                           style: const TextStyle(fontSize: 18),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                             Container(
//                               alignment: Alignment.center,
//                               width: 50,
//                               child: Text(
//                                 index == matchRecords.length
//                                     ? match.time_end?.time ?? "Live"
//                                     : record!.time_start.time,
//                                 style: context.bodySmall?.copyWith(
//                                   color: match.time_end != null
//                                       ? lighterTint
//                                       : Colors.red,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (index == matchRecords.length)
//                         Text(
//                           getWinnerMessage(
//                               allScores.last.map((e) => e!).toList(), users),
//                           style: context.bodyLarge
//                               ?.copyWith(fontWeight: FontWeight.bold),
//                         )
//                     ],
//                   );
//                 },
//               ),
//             ),
//             // Expanded(
//             //   child: ListView.builder(
//             //     itemCount: matchRecords.length + 1,
//             //     itemBuilder: (context, index) {
//             //       final record =
//             //           index == matchRecords.length ? null : matchRecords[index];
//             //       final rounds = record?.rounds;
//             //       //final scores = allScores[index];
//             //       return Column(
//             //         mainAxisSize: MainAxisSize.min,
//             //         children: [
//             //           if (index == matchRecords.length ||
//             //               index == 0 ||
//             //               record!.game != matchRecords[index - 1].game) ...[
//             //             Padding(
//             //               padding: const EdgeInsets.all(4.0),
//             //               child: Text(
//             //                 index == matchRecords.length
//             //                     ? "Total Score"
//             //                     : record!.game,
//             //                 style: TextStyle(
//             //                   fontSize: 16,
//             //                   fontWeight: FontWeight.bold,
//             //                   color: index == matchRecords.length
//             //                       ? primaryColor
//             //                       : tint,
//             //                 ),
//             //               ),
//             //             ),
//             //           ],
//             //           Padding(
//             //             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             //             child: Row(
//             //               children: [
//             //                 Container(
//             //                   alignment: Alignment.center,
//             //                   width: 50,
//             //                   child: Text(
//             //                     index == matchRecords.length
//             //                         ? "="
//             //                         : "${index + 1}.",
//             //                     style: context.bodyLarge
//             //                         ?.copyWith(color: lightTint),
//             //                   ),
//             //                 ),
//             //                 Expanded(
//             //                   child: Row(
//             //                     // mainAxisAlignment:
//             //                     //     MainAxisAlignment.spaceBetween,
//             //                     children: List.generate(
//             //                       users.length,
//             //                       (index) {
//             //                         //int? score = scores[index];
//             //                         int? score = record?.scores["$index"];
//             //                         return Expanded(
//             //                           // width: context.screenWidth /
//             //                           //     players.length,
//             //                           child: Center(
//             //                             child: Text(
//             //                               score == null ? "-" : "$score",
//             //                               textAlign: TextAlign.center,
//             //                               style: const TextStyle(fontSize: 18),
//             //                             ),
//             //                           ),
//             //                         );
//             //                       },
//             //                     ),
//             //                   ),
//             //                 ),
//             //                 Container(
//             //                   alignment: Alignment.center,
//             //                   width: 50,
//             //                   child: Text(
//             //                     index == matchRecords.length
//             //                         ? match.time_end?.time ?? "Live"
//             //                         : record!.time_start.time,
//             //                     style: context.bodySmall?.copyWith(
//             //                       color: match.time_end != null
//             //                           ? lighterTint
//             //                           : Colors.red,
//             //                     ),
//             //                   ),
//             //                 ),
//             //               ],
//             //             ),
//             //           ),
//             //           if (index == matchRecords.length)
//             //             Text(
//             //               getWinnerMessage(
//             //                   allScores.last.map((e) => e!).toList(), users),
//             //               style: context.bodyLarge
//             //                   ?.copyWith(fontWeight: FontWeight.bold),
//             //             )
//             //         ],
//             //       );
//             //     },
//             //   ),
//             // ),
//           ],
//         ],
//       ),
//       bottomNavigationBar: matchRecords.isEmpty
//           ? null
//           : AppButton(
//title:
//               "Watch",
//               onPressed: () {
//                 final game = matchRecords.first.game;
//                 gotoGamePage(context, game, match.game_id!, match.match_id!,
//                     match: match, isWatch: true, users: users);
//               },
//               height: 50,
//               color: Colors.blue,
//               wrapped: true,
//             ),
//     );
//   }
// }
