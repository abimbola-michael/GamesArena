// import 'package:gamesarena/blocs/firebase_service.dart';
// import 'package:gamesarena/extensions/extensions.dart';
// import 'package:gamesarena/pages/new_offline_game_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../../components/components.dart';
// import '../../components/game_item.dart';
// import '../../utils/utils.dart';
// import '../pages.dart';

// class GamesPage extends StatefulWidget {
//   final bool isTab;
//   final List<String>? players;
//   final int? playersSize;
//   final bool isCallback;
//   //final void Function(String game)? gameCallback;
//   const GamesPage({
//     super.key,
//     this.isTab = false,
//     this.isCallback = false,
//     this.players,
//     this.playersSize,
//     //this.gameCallback
//   });

//   @override
//   State<GamesPage> createState() => _GamesPageState();
// }

// class _GamesPageState extends State<GamesPage> {
//   int mode = -1;
//   int game = -1;
//   String current = "game";
//   List<String>? players;
//   FirebaseService fs = FirebaseService();
//   bool creating = false;
//   int? playersSize;
//   int gridSize = 2;
//   //void Function(String game)? gameCallback;

//   @override
//   void initState() {
//     super.initState();
//     players = widget.players;
//     playersSize = widget.playersSize;
//     //gameCallback = widget.gameCallback;
//     if (players != null && players!.isNotEmpty) {
//       mode = 0;
//     } else if (playersSize != null) {
//       mode = 1;
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     // TODO: implement didChangeDependencies
//     super.didChangeDependencies();
//     gridSize = context.isPortrait ? 2 : 4;
//   }

//   int getListLength() {
//     return current == "game" ? games.length : modes.length;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (creating) return false;
//         if (current == "game") {
//           return true;
//         } else {
//           game = -1;
//           current = "game";
//           setState(() {});
//           return false;
//         }
//       },
//       child: Scaffold(
//         appBar: widget.isTab
//             ? null
//             : AppBar(
//                 title: Text(
//                     "${players?.isEmpty ?? true ? "Select" : "Create"} Game"),
//               ),
//         body: creating
//             ? const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(),
//                     Padding(
//                       padding: EdgeInsets.all(8.0),
//                       child: Text(
//                         "Creating game...",
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                         textAlign: TextAlign.center,
//                       ),
//                     )
//                   ],
//                 ),
//               )
//             : Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Center(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (game != -1) ...[
//                           Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Text(
//                               games[game],
//                               style: const TextStyle(
//                                   fontSize: 24, fontWeight: FontWeight.bold),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ],
//                         Wrap(
//                           direction: Axis.horizontal,
//                           children: List.generate(getListLength(), (index) {
//                             if (current == "game") {
//                               final game = games[index];
//                               return SizedBox(
//                                 width: (context.screenWidth - 32) / gridSize,
//                                 child: GameItemWidget(
//                                   game: game,
//                                   onPressed: () {
//                                     this.game = index;
//                                     if (widget.isCallback) {
//                                       Navigator.of(context).pop(games[index]);
//                                     } else {
//                                       if (widget.isTab) {
//                                         setState(() {
//                                           current = "mode";
//                                         });
//                                       } else {
//                                         if (players != null &&
//                                             players!.isNotEmpty) {
//                                           createGame();
//                                         } else if (widget.playersSize != null) {
//                                           gotoGamePage();
//                                         } else {
//                                           gotoOfflineGame();
//                                         }
//                                       }
//                                     }
//                                   },
//                                 ),
//                               );
//                             } else {
//                               String mode = modes[index];
//                               return SizedBox(
//                                 width: (context.screenWidth - 32) / gridSize,
//                                 child: CardWidget(
//                                     text: mode,
//                                     icon: Icons.gamepad_rounded,
//                                     onPressed: () {
//                                       if (index == 1) {
//                                         gotoOfflineGame();
//                                       } else {
//                                         gotoSelectPlayers();
//                                       }
//                                     }),
//                               );
//                             }
//                           }),
//                         ),
//                         // ...List.generate(
//                         //     current == "mode"
//                         //         ? 1
//                         //         : (getListLength() / gridSize).ceil(),
//                         //     (colindex) {
//                         //   final colSize = (getListLength() / gridSize).ceil();
//                         //   final remainder = getListLength() % gridSize;
//                         //   return SingleChildScrollView(
//                         //     scrollDirection: Axis.horizontal,
//                         //     child: Row(
//                         //         mainAxisAlignment: current == "mode"
//                         //             ? MainAxisAlignment.center
//                         //             : MainAxisAlignment.start,
//                         //         children: List.generate(
//                         //             current == "mode"
//                         //                 ? 2
//                         //                 : colindex == colSize - 1 &&
//                         //                         remainder > 0
//                         //                     ? remainder
//                         //                     : gridSize, (rowindex) {
//                         //           final index = convertToPosition(
//                         //               [rowindex, colindex],
//                         //               current == "mode" ? 2 : gridSize);
//                         //           if (current == "game") {
//                         //             final game = games[index];
//                         //             return SizedBox(
//                         //               width:
//                         //                   (context.screenWidth - 32) / gridSize,
//                         //               child: GameItemWidget(
//                         //                 game: game,
//                         //                 onPressed: () {
//                         //                   this.game = index;
//                         //                   if (widget.isCallback) {
//                         //                     Navigator.of(context)
//                         //                         .pop(games[index]);
//                         //                   } else {
//                         //                     if (widget.isTab) {
//                         //                       setState(() {
//                         //                         current = "mode";
//                         //                       });
//                         //                     } else {
//                         //                       if (players != null &&
//                         //                           players!.isNotEmpty) {
//                         //                         createGame();
//                         //                       } else if (widget.playersSize !=
//                         //                           null) {
//                         //                         gotoGamePage();
//                         //                       } else {
//                         //                         gotoOfflineGame();
//                         //                       }
//                         //                     }
//                         //                   }
//                         //                 },
//                         //               ),
//                         //             );
//                         //           } else {
//                         //             String mode = modes[index];
//                         //             return SizedBox(
//                         //               width:
//                         //                   (context.screenWidth - 32) / gridSize,
//                         //               child: CardWidget(
//                         //                   text: mode,
//                         //                   icon: Icons.gamepad_rounded,
//                         //                   onPressed: () {
//                         //                     if (index == 1) {
//                         //                       gotoOfflineGame();
//                         //                     } else {
//                         //                       gotoSelectPlayers();
//                         //                     }
//                         //                   }),
//                         //             );
//                         //           }
//                         //         })),
//                         //   );
//                         // }),
//                         // GridView.builder(
//                         //     shrinkWrap: true,
//                         //     itemCount: getListLength(),
//                         //     padding: const EdgeInsets.all(20.0),
//                         //     gridDelegate:
//                         //         const SliverGridDelegateWithFixedCrossAxisCount(
//                         //             crossAxisCount: 2),
//                         //     itemBuilder: (context, index) {
//                         //       if (current == "game") {
//                         //         final game = games[index];
//                         //         return GameItemWidget(
//                         //           game: game,
//                         //           onPressed: () {
//                         //             this.game = index;
//                         //             if (widget.isCallback) {
//                         //               Navigator.of(context).pop(games[index]);
//                         //             }
//                         //             if (widget.isTab) {
//                         //               setState(() {
//                         //                 current = "mode";
//                         //               });
//                         //             } else {
//                         //               if (players != null && players!.isNotEmpty) {
//                         //                 createGame();
//                         //               } else if (widget.playersSize != null) {
//                         //                 gotoGamePage();
//                         //               } else {
//                         //                 gotoOfflineGame();
//                         //               }
//                         //             }
//                         //           },
//                         //         );
//                         //       } else {
//                         //         String mode = modes[index];
//                         //         return CardWidget(
//                         //             text: mode,
//                         //             icon: Icons.gamepad_rounded,
//                         //             onPressed: () {
//                         //               if (index == 1) {
//                         //                 gotoOfflineGame();
//                         //               } else {
//                         //                 gotoSelectPlayers();
//                         //               }
//                         //             });
//                         //       }
//                         //     }),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   void createGame() async {
//     setState(() {
//       creating = true;
//     });
//     final request = await fs.createGame(games[game], "", players!);
//     setState(() {
//       players!.clear();
//       players = null;
//       creating = false;
//     });
//     if (request == null) return;
//     // Fluttertoast.showToast(msg: "indices = ${request.indices}");
//     final users = await fs.getPlayersFromGame(request.game_id);
//     String indices = "";
//     if (games[game] == "Ludo") {
//       indices = await fs.getLudoIndices(request.game_id, request.match_id);
//     } else if (games[game] == "Whot") {
//       indices = await fs.getWhotIndices(request.game_id, request.match_id);
//     }

//     if (!widget.isTab) {
//       Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//               builder: (context) => NewOnlineGamePage(
//                     indices: indices,
//                     playing: request.playing,
//                     users: users,
//                     game: request.game,
//                     groupId: request.group_id,
//                     matchId: request.match_id,
//                     gameId: request.game_id,
//                     creatorId: request.creator_id,
//                   )),
//           result: true);
//     } else {
//       Navigator.of(context).push(MaterialPageRoute(
//           builder: (context) => NewOnlineGamePage(
//                 indices: indices,
//                 playing: request.playing,
//                 users: users,
//                 game: request.game,
//                 groupId: request.group_id,
//                 matchId: request.match_id,
//                 gameId: request.game_id,
//                 creatorId: request.creator_id,
//               )));
//     }
//   }

//   void gotoOfflineGame() async {
//     if (!widget.isTab) {
//       Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//               builder: (context) => NewOfflineGamePage(game: games[game])),
//           result: true);
//     } else {
//       Navigator.of(context).push(MaterialPageRoute(
//           builder: (context) => NewOfflineGamePage(game: games[game])));
//     }
//   }

//   void gotoSelectPlayers() async {
//     final players = (await Navigator.of(context).push(MaterialPageRoute(
//         builder: (context) => FirebaseAuth.instance.currentUser == null
//             ? const LoginPage(login: true)
//             : OnlinePlayersSelectionPage(
//                 type: "",
//                 game: games[game],
//                 group_id: "",
//               ))) as List<String>?);
//     if (players != null) {
//       this.players = players;
//       createGame();
//     }
//   }

//   void gotoGamePage() {
//     Widget widget = const BatballGamePage();
//     final game = games[this.game];
//     if (game == "Bat Ball") {
//       widget = const BatballGamePage();
//     } else if (game == "Whot") {
//       widget = WhotGamePage(
//         playersSize: playersSize,
//       );
//     } else if (game == "Ludo") {
//       widget = LudoGamePage(
//         playersSize: playersSize,
//       );
//     } else if (game == "Draught") {
//       widget = const DraughtGamePage();
//     } else if (game == "Chess") {
//       widget = const ChessGamePage();
//     } else if (game == "X and O") {
//       widget = const XandOGamePage();
//     }
//     Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: ((context) => widget)),
//         result: true);
//   }
//   // void gotoGamePage() {
//   //   String game = games[this.game];
//   //   Widget widget = const BatballGamePage();
//   //   if (game == "Bat Ball") {
//   //     widget = BatballGamePage(
//   //       matchId: matchId,
//   //       gameId: gameId,
//   //       users: users,
//   //     );
//   //   } else if (game == "Whot") {
//   //     widget = WhotGamePage(
//   //       matchId: matchId,
//   //       gameId: gameId,
//   //       users: users,
//   //     );
//   //   } else if (game == "Ludo") {
//   //     widget = LudoGamePage(
//   //       matchId: matchId,
//   //       gameId: gameId,
//   //       users: users,
//   //     );
//   //   } else if (game == "Draught") {
//   //     widget = DraughtGamePage(
//   //       matchId: matchId,
//   //       gameId: gameId,
//   //       users: users,
//   //     );
//   //   } else if (game == "Chess") {
//   //     widget = ChessGamePage(
//   //       matchId: matchId,
//   //       gameId: gameId,
//   //       users: users,
//   //     );
//   //   } else if (game == "X and O") {
//   //     widget = XandOGamePage(
//   //       matchId: matchId,
//   //       gameId: gameId,
//   //       users: users,
//   //     );
//   //   }
//   //   Navigator.of(context)
//   //       .pushReplacement(MaterialPageRoute(builder: ((context) => widget)));
//   // }
//   // void gotoNewGamePage(int playersSize) {
//   //   Navigator.of(context).push(MaterialPageRoute(
//   //       builder: ((context) =>
//   //           NewOfflineGamePage(game: games[game], playersSize: playersSize))));
//   // }
// }
