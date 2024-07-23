import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/game/pages/new_offline_game_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../shared/widgets/game_card.dart';
import '../../game/services.dart';
import '../../game/widgets/game_item.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../games/pages.dart';

class GamesPage extends StatefulWidget {
  final bool isTab;
  final List<String>? players;
  final int? playersSize;
  final bool isCallback;
  final bool isChangeGame;
  final VoidCallback? onBackPressed;
  final void Function(String game)? gameCallback;
  final String? currentGame;
  const GamesPage({
    super.key,
    this.isTab = false,
    this.isCallback = false,
    this.isChangeGame = false,
    this.players,
    this.playersSize,
    this.gameCallback,
    this.onBackPressed,
    this.currentGame,
  });

  @override
  State<GamesPage> createState() => GamesPageState();
}

class GamesPageState extends State<GamesPage> {
  // int mode = -1;
  int game = -1;
  String current = "game";
  List<String>? players;
  bool creating = false;
  int playersSize = 2;
  int gridSize = 2;
  List<String> games = [];
  void Function(String game)? gameCallback;

  @override
  void initState() {
    super.initState();

    players = widget.players;
    playersSize = widget.playersSize ?? 2;
    gameCallback = widget.gameCallback;
    // if (players != null && players!.isNotEmpty) {
    //   mode = 0;
    // } else if (playersSize != null) {
    //   mode = 1;
    // }
    if (playersSize > 2) {
      games.add(ludoGame);
      games.add(whotGame);
    } else {
      games.addAll(allGames);
    }
    if (widget.currentGame != null) {
      games.remove(widget.currentGame);
    }
  }

  int getListLength() {
    return current == "game" ? games.length : modes.length;
  }

  @override
  Widget build(BuildContext context) {
    gridSize = context.screenWidth < context.screenHeight ? 2 : 4;
    return WillPopScope(
      onWillPop: () async {
        if (current == "game") {
          return true;
        } else {
          goBackToGames();
          return false;
        }
      },
      child: Scaffold(
        appBar: widget.isTab
            ? null
            : AppBar(
                titleSpacing: 20,
                centerTitle: true,
                leading: IconButton(
                  onPressed: widget.onBackPressed ?? context.pop(),
                  icon: const Icon(
                    EvaIcons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  "${players?.isEmpty ?? true ? "Select" : "Create"} Game",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        body: creating
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Creating game...",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: SingleChildScrollView(
                    primary: true,
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (game != -1 && current == "mode") ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              games[game],
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        Wrap(
                          direction: Axis.horizontal,
                          children: List.generate(getListLength(), (index) {
                            if (current == "game") {
                              final game = games[index];
                              return GameItemWidget(
                                width: (context.screenWidth - 32) / gridSize,
                                game: game,
                                onPressed: () {
                                  if (gameCallback != null) {
                                    gameCallback!(game);
                                    if (widget.isChangeGame) {
                                      return;
                                    }
                                  }
                                  this.game = index;
                                  if (widget.isCallback) {
                                    Navigator.of(context).pop(games[index]);
                                  } else {
                                    if (widget.isTab) {
                                      setState(() {
                                        current = "mode";
                                      });
                                      // if (!kIsWeb ||
                                      //     (defaultTargetPlatform ==
                                      //             TargetPlatform.android ||
                                      //         defaultTargetPlatform ==
                                      //             TargetPlatform.iOS)) {
                                      //   setState(() {
                                      //     current = "mode";
                                      //   });
                                      // } else {
                                      //   if (players != null &&
                                      //       players!.isNotEmpty) {
                                      //     createNewGame();
                                      //   } else {
                                      //     gotoSelectPlayers();
                                      //   }
                                      // }
                                    } else {
                                      if (players != null &&
                                          players!.isNotEmpty) {
                                        createNewGame();
                                      } else if (widget.playersSize != null) {
                                        gotoGame();
                                      } else {
                                        gotoOfflineGame();
                                      }
                                    }
                                  }
                                },
                              );
                            } else {
                              String mode = modes[index];
                              return SizedBox(
                                width: (context.screenWidth - 32) / gridSize,
                                child: GameCard(
                                    text: mode,
                                    icon: Icons.gamepad_rounded,
                                    onPressed: () {
                                      if (index == 1) {
                                        gotoOfflineGame();
                                      } else {
                                        gotoSelectPlayers();
                                      }
                                    }),
                              );
                            }
                          }),
                        ),
                        // ...List.generate(
                        //     current == "mode"
                        //         ? 1
                        //         : (getListLength() / gridSize).ceil(),
                        //     (colindex) {
                        //   final colSize = (getListLength() / gridSize).ceil();
                        //   final remainder = getListLength() % gridSize;
                        //   return Row(
                        //       mainAxisAlignment: current == "mode"
                        //           ? MainAxisAlignment.center
                        //           : MainAxisAlignment.start,
                        //       children: List.generate(
                        //           current == "mode"
                        //               ? 2
                        //               : colindex == colSize - 1 && remainder > 0
                        //                   ? remainder
                        //                   : gridSize, (rowindex) {
                        //         final index = convertToPosition(
                        //             [rowindex, colindex],
                        //             current == "mode" ? 2 : gridSize);
                        //         if (current == "game") {
                        //           final game = games[index];
                        //           return Expanded(
                        //             child: GameItemWidget(
                        //               width:
                        //                   (context.screenWidth - 32) / gridSize,
                        //               game: game,
                        //               onPressed: () {
                        //                 if (gameCallback != null) {
                        //                   gameCallback!(game);
                        //                 }
                        //                 this.game = index;
                        //                 if (widget.isCallback) {
                        //                   Navigator.of(context)
                        //                       .pop(games[index]);
                        //                 } else {
                        //                   if (widget.isTab) {
                        //                     if (!kIsWeb ||
                        //                         (defaultTargetPlatform ==
                        //                                 TargetPlatform
                        //                                     .android ||
                        //                             defaultTargetPlatform ==
                        //                                 TargetPlatform.iOS)) {
                        //                       setState(() {
                        //                         current = "mode";
                        //                       });
                        //                     } else {
                        //                       if (players != null &&
                        //                           players!.isNotEmpty) {
                        //                         createNewGame();
                        //                       } else {
                        //                         gotoSelectPlayers();
                        //                       }
                        //                     }
                        //                   } else {
                        //                     if (players != null &&
                        //                         players!.isNotEmpty) {
                        //                       createNewGame();
                        //                     } else if (widget.playersSize !=
                        //                         null) {
                        //                       gotoGame();
                        //                     } else {
                        //                       gotoOfflineGame();
                        //                     }
                        //                   }
                        //                 }
                        //               },
                        //             ),
                        //           );
                        //         } else {
                        //           String mode = modes[index];
                        //           return SizedBox(
                        //             width:
                        //                 (context.screenWidth - 32) / gridSize,
                        //             child: GameCard(
                        //                 text: mode,
                        //                 icon: Icons.gamepad_rounded,
                        //                 onPressed: () {
                        //                   if (index == 1) {
                        //                     gotoOfflineGame();
                        //                   } else {
                        //                     gotoSelectPlayers();
                        //                   }
                        //                 }),
                        //           );
                        //         }
                        //       }));
                        // }),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void goBackToGames() {
    if (creating) return;
    if (gameCallback != null) {
      gameCallback!("");
    }
    game = -1;
    current = "game";
    setState(() {});
  }

  void createNewGame() async {
    if (creating) return;
    setState(() {
      creating = true;
    });
    await createGame(games[game], "", players!);
    setState(() {
      players!.clear();
      players = null;
      creating = false;
    });
  }

  void gotoOfflineGame() async {
    if (!widget.isTab) {
      await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => NewOfflineGamePage(game: games[game])),
          result: true);
    } else {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NewOfflineGamePage(game: games[game])));
      setState(() {
        current = "game";
      });
    }
  }

  void gotoSelectPlayers() async {
    final players = (await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FirebaseAuth.instance.currentUser == null
            ? const LoginPage(login: true)
            : OnlinePlayersSelectionPage(
                type: "",
                game: games[game],
                group_id: "",
              ))) as List<String>?);
    if (players != null) {
      this.players = players;
      if (creating) return;
      createNewGame();
    }
  }

  void gotoGame() {
    final game = games[this.game];
    gotoGamePage(context, game, "", "", null, playersSize, null, 0,
        result: true);
    // Widget widget = const BatballGamePage();
    // if (game == "Bat Ball") {
    //   widget = const BatballGamePage();
    // } else if (game == "Whot") {
    //   widget = WhotGamePage(
    //     playersSize: playersSize,
    //   );
    // } else if (game == "Ludo") {
    //   widget = LudoGamePage(
    //     playersSize: playersSize,
    //   );
    // } else if (game == "Draught") {
    //   widget = const DraughtGamePage();
    // } else if (game == "Chess") {
    //   widget = const ChessGamePage();
    // } else if (game == "X and O") {
    //   widget = const XandOGamePage();
    // }
    // Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: ((context) => widget)),
    //     result: true);
  }
  // void gotoGame() {
  //   String game = games[this.game];
  //   Widget widget = const BatballGamePage();
  //   if (game == "Bat Ball") {
  //     widget = BatballGamePage(
  //       matchId: matchId,
  //       gameId: gameId,
  //       users: users,
  //     );
  //   } else if (game == "Whot") {
  //     widget = WhotGamePage(
  //       matchId: matchId,
  //       gameId: gameId,
  //       users: users,
  //     );
  //   } else if (game == "Ludo") {
  //     widget = LudoGamePage(
  //       matchId: matchId,
  //       gameId: gameId,
  //       users: users,
  //     );
  //   } else if (game == "Draught") {
  //     widget = DraughtGamePage(
  //       matchId: matchId,
  //       gameId: gameId,
  //       users: users,
  //     );
  //   } else if (game == "Chess") {
  //     widget = ChessGamePage(
  //       matchId: matchId,
  //       gameId: gameId,
  //       users: users,
  //     );
  //   } else if (game == "X and O") {
  //     widget = XandOGamePage(
  //       matchId: matchId,
  //       gameId: gameId,
  //       users: users,
  //     );
  //   }
  //   Navigator.of(context)
  //       .pushReplacement(MaterialPageRoute(builder: ((context) => widget)));
  // }
  // void gotoNewGamePage(int playersSize) {
  //   Navigator.of(context).push(MaterialPageRoute(
  //       builder: ((context) =>
  //           NewOfflineGamePage(game: games[game], playersSize: playersSize))));
  // }
}
