import 'dart:async';
import 'dart:math';
import 'package:gamesarena/core/base/base_game_page.dart';
import 'package:gamesarena/features/games/xando/widgets/xando_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/services.dart';

import '../services.dart';
import '../widgets/xando_line_paint.dart';
import '../models/xando.dart';
import '../../../../shared/utils/constants.dart';
import '../../../../shared/utils/utils.dart';

class XandOGamePage extends BaseGamePage {
  static const route = "/xando";

  const XandOGamePage({
    super.key,
  });

  @override
  State<XandOGamePage> createState() => _XandOGamePageState();
}

class _XandOGamePageState extends BaseGamePageState<XandOGamePage> {
  bool played = false;
  //XandODetails? prevDetails;
  int gridSize = 3;
  List<List<XandO>> xandos = [];

  LineDirection? winDirection;
  XandOChar? winChar;
  int winIndex = -1;
  int playedCount = 0;

  List<LineDirection> directions = [
    LineDirection.vertical,
    LineDirection.horizontal,
    LineDirection.lowerDiagonal,
    LineDirection.upperDiagonal
  ];
  String pauseId = "";
  String updatePlayerId = "";
  int currentPlayerIndex = 0;

  XandOChar getChar(int index) => index == 0 ? XandOChar.x : XandOChar.o;

  // void updateDetails(int playPos) {
  //   if (matchId != "" && gameId != "" && users != null) {
  //     if (played) return;
  //     played = true;
  //     final details = XandODetails(playPos: playPos, currentPlayerId: myId);
  //     setXandODetails(
  //       gameId,
  //       details,
  //       prevDetails,
  //     );
  //     prevDetails = details;
  //   }
  // }

  void playChar(int index, [bool isClick = true]) async {
    if (awaiting) return;
    if (isClick && gameId.isNotEmpty && currentPlayerId != myId) {
      showToast(currentPlayer, "Its ${getUsername(currentPlayerId)}'s turn");
      return;
    }

    final coordinates = convertToGrid(index, gridSize);
    final rowindex = coordinates[0];
    final colindex = coordinates[1];
    final xando = xandos[colindex][rowindex];
    if (xando.char == XandOChar.empty) {
      if (isClick && gameId.isNotEmpty && currentPlayerId == myId) {
        awaiting = true;
        final details = XandODetails(playPos: index, currentPlayerId: myId);
        await setGameDetails(gameId, details.toMap());
        awaiting = false;
      }
      xandos[colindex][rowindex].char = getChar(currentPlayer);
      checkIfMatch(xando);
      //getHintMessage();
      setState(() {});
    }
  }

  void playIfTimeOut() {
    List<int> unplayedPositions = [];
    for (int i = 0; i < xandos.length; i++) {
      for (int j = 0; j < xandos[i].length; j++) {
        final xandO = xandos[i][j];
        if (xandO.char == XandOChar.empty) {
          unplayedPositions
              .add(convertToPosition([xandO.x, xandO.y], gridSize));
        }
      }
    }
    if (unplayedPositions.isNotEmpty) {
      playChar(unplayedPositions[Random().nextInt(unplayedPositions.length)]);
    }
    // changePlayer();
  }

  void checkIfMatch(XandO xando) {
    // if (awaiting) return;
    final x = xando.x;
    final y = xando.y;
    final char = xando.char;
    int vertCount = 0, horCount = 0, lowerDiagCount = 0, upperDiagCount = 0;
    bool foundMatch = false;

    for (int i = 0; i < 3; i++) {
      final vertXandO = xandos[i][x];
      if (vertXandO.char == char) {
        vertCount++;
      }
      if (vertCount == 3) {
        winIndex = x;
        winDirection = LineDirection.vertical;
        foundMatch = true;
        break;
      }

      final horXandO = xandos[y][i];
      if (horXandO.char == char) {
        horCount++;
      }
      if (horCount == 3) {
        winIndex = y;
        winDirection = LineDirection.horizontal;
        foundMatch = true;
        break;
      }
    }
    if ((x + y).isEven) {
      for (int i = 0; i < 3; i++) {
        if ((x + y) == 2) {
          final lowerdiagXandO = xandos[2 - i][i];
          if (lowerdiagXandO.char == char) {
            lowerDiagCount++;
          }
          if (lowerDiagCount == 3) {
            winIndex = 0;
            winDirection = LineDirection.lowerDiagonal;
            foundMatch = true;
            break;
          }
        }
        if (x == y) {
          final upperdiagXandO = xandos[i][i];
          if (upperdiagXandO.char == char) {
            upperDiagCount++;
          }
          if (upperDiagCount == 3) {
            winIndex = 1;
            winDirection = LineDirection.upperDiagonal;
            foundMatch = true;
            break;
          }
        }
      }
    }
    playedCount++;
    message = "Your Turn";

    if (foundMatch || playedCount == (gridSize * gridSize)) {
      if (foundMatch) {
        winChar = xando.char;
        message = "You Won";
        //Fluttertoast.showToast(msg: "Player ${xando.char.name.capitalize} Won");
        // playersScores[currentPlayer]++;
        // updateMatchRecord();
        // toastWinner(winChar!.index);
        //updateWin(currentPlayer);
      }
      awaiting = true;
      Future.delayed(const Duration(seconds: 1)).then((value) {
        playedCount = 0;
        resetChars();
      });
    }
    changePlayer();
    setState(() {});
  }

  Future resetChars() async {
    playerTime = maxPlayerTime;
    awaiting = false;
    xandos.clear();
    winDirection = null;
    winChar = null;
    winIndex = -1;
    message = "Your Turn";
    setState(() {
      initGrids();
    });
  }

  void resetScores() {
    playersScores = List.generate(2, (index) => 0);
  }

  void initGrids() {
    pausePlayerTime = false;
    finishedRound = false;
    xandos = List.generate(
        gridSize,
        (colindex) => List.generate(gridSize, (rowindex) {
              final index = convertToPosition([rowindex, colindex], gridSize);
              return XandO(XandOChar.empty, rowindex, colindex, "$index");
            }));
  }

  // @override
  // Widget build(BuildContext context) {
  //   super.build(context);
  //   return PopScope(
  //     canPop: false,
  //     onPopInvoked: (pop) async {
  //       if (!paused) {
  //         pauseGame();
  //       }
  //     },
  //     child: Scaffold(
  //       body: RotatedBox(
  //         quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
  //         child: Stack(
  //           children: [
  //             ...List.generate(2, (index) {
  //               return Positioned(
  //                   top: landScape || index == 0 ? 0 : null,
  //                   bottom: landScape || index == 1 ? 0 : null,
  //                   left: !landScape || index == 0 ? 0 : null,
  //                   right: !landScape || index == 1 ? 0 : null,
  //                   child: Container(
  //                       width: landScape ? padding : minSize,
  //                       height: landScape ? minSize : padding,
  //                       padding: const EdgeInsets.all(4),
  //                       child: RotatedBox(
  //                         quarterTurns: index == 0 ? 2 : 0,
  //                         child: Column(
  //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                           children: [
  //                             if (landScape) ...[
  //                               Expanded(
  //                                 child: Container(),
  //                               ),
  //                             ],
  //                             Expanded(
  //                               child: Column(
  //                                 mainAxisAlignment:
  //                                     MainAxisAlignment.spaceBetween,
  //                                 children: [
  //                                   RotatedBox(
  //                                     quarterTurns:
  //                                         gameId != "" && myPlayer != index
  //                                             ? 2
  //                                             : 0,
  //                                     child: Column(
  //                                       mainAxisSize: MainAxisSize.min,
  //                                       children: [
  //                                         SizedBox(
  //                                           height: 70,
  //                                           child: Text(
  //                                             '${playersScores[index]}',
  //                                             style: TextStyle(
  //                                                 fontWeight: FontWeight.bold,
  //                                                 fontSize: 60,
  //                                                 color: darkMode
  //                                                     ? Colors.white
  //                                                         .withOpacity(0.5)
  //                                                     : Colors.black
  //                                                         .withOpacity(0.5)),
  //                                             textAlign: TextAlign.center,
  //                                           ),
  //                                         ),
  //                                         GameTimer(
  //                                           timerStream: timerController.stream,
  //                                         ),
  //                                         if (currentPlayer == index) ...[
  //                                           const SizedBox(
  //                                             height: 4,
  //                                           ),
  //                                           StreamBuilder<int>(
  //                                               stream: timerController.stream,
  //                                               builder: (context, snapshot) {
  //                                                 return Text(
  //                                                   "$message - $playerTime",
  //                                                   style: TextStyle(
  //                                                       fontWeight:
  //                                                           FontWeight.bold,
  //                                                       fontSize: 20,
  //                                                       color: darkMode
  //                                                           ? Colors.white
  //                                                           : Colors.black),
  //                                                   textAlign: TextAlign.center,
  //                                                 );
  //                                               }),
  //                                         ],
  //                                       ],
  //                                     ),
  //                                   ),
  //                                   Column(
  //                                     mainAxisSize: MainAxisSize.min,
  //                                     children: [
  //                                       RotatedBox(
  //                                         quarterTurns:
  //                                             gameId != "" && myPlayer != index
  //                                                 ? 2
  //                                                 : 0,
  //                                         child: Text(
  //                                           users != null
  //                                               ? users![index]?.username ?? ""
  //                                               : "Player ${index + 1}",
  //                                           style: TextStyle(
  //                                               fontSize: 20,
  //                                               color: currentPlayer == index
  //                                                   ? Colors.blue
  //                                                   : darkMode
  //                                                       ? Colors.white
  //                                                       : Colors.black),
  //                                           textAlign: TextAlign.center,
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       )));
  //             }),
  //             Center(
  //               child: AspectRatio(
  //                 aspectRatio: 1 / 1,
  //                 child: CustomPaint(
  //                   foregroundPainter: winDirection == null
  //                       ? null
  //                       : XandOLinePainter(
  //                           direction: winDirection!,
  //                           index: winIndex,
  //                           color: winChar! == XandOChar.x
  //                               ? Colors.blue
  //                               : Colors.red,
  //                           thickness: 3),
  //                   child: GridView(
  //                     physics: const NeverScrollableScrollPhysics(),
  //                     padding: EdgeInsets.zero,
  //                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //                         crossAxisCount: gridSize),
  //                     children: List.generate(gridSize * gridSize, (index) {
  //                       final coordinates = convertToGrid(index, gridSize);
  //                       final rowindex = coordinates[0];
  //                       final colindex = coordinates[1];
  //                       final xando = xandos[colindex][rowindex];
  //                       return XandOTile(
  //                         key: Key(xando.id),
  //                         blink: firstTime && xando.char == XandOChar.empty,
  //                         xando: xando,
  //                         onPressed: () {
  //                           if (gameId != "" && currentPlayerId != myId) {
  //                             showToast(1,
  //                                 "Its ${getUsername(currentPlayerId)}'s turn");
  //                             return;
  //                           }
  //                           if (gameId != "") {
  //                             updateDetails(index);
  //                           } else {
  //                             playChar(index);
  //                           }
  //                         },
  //                       );
  //                     }),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             if (firstTime && !paused && !seenFirstHint) ...[
  //               RotatedBox(
  //                 quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
  //                 child: Container(
  //                   height: double.infinity,
  //                   width: double.infinity,
  //                   color: lighterBlack,
  //                   alignment: Alignment.center,
  //                   child: GestureDetector(
  //                     behavior: HitTestBehavior.opaque,
  //                     child: const Center(
  //                       child: Text(
  //                           "Tap on any part of the grid\nTap till you get a three matching pattern\nPattern can be vertically or diagonally",
  //                           style: TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 18,
  //                           ),
  //                           textAlign: TextAlign.center),
  //                     ),
  //                     onTap: () {
  //                       setState(() {
  //                         seenFirstHint = true;
  //                       });
  //                     },
  //                   ),
  //                 ),
  //               )
  //             ],
  //             if (paused) ...[
  //               RotatedBox(
  //                 quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
  //                 child: PausedGamePage(
  //                   context: context,
  //                   readAboutGame: readAboutGame,
  //                   game: "X and O",
  //                   playersScores: playersScores,
  //                   users: users,
  //                   playersSize: 2,
  //                   finishedRound: finishedRound,
  //                   startingRound: gameTime == maxGameTime,
  //                   onStart: startGame,
  //                   onRestart: restartGame,
  //                   onChange: selectNewGame,
  //                   onLeave: leaveGame,
  //                   onReadAboutGame: () {
  //                     if (readAboutGame) {
  //                       setState(() {
  //                         readAboutGame = false;
  //                       });
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ],
  //             if (playersToasts[0] != "") ...[
  //               Align(
  //                 alignment: Alignment.topCenter,
  //                 child: RotatedBox(
  //                   quarterTurns: 2,
  //                   child: AppToast(
  //                     message: playersToasts[0],
  //                     onComplete: () {
  //                       playersToasts[0] = "";
  //                       setState(() {});
  //                     },
  //                   ),
  //                 ),
  //               ),
  //             ],
  //             if (playersToasts[1] != "") ...[
  //               Align(
  //                 alignment: Alignment.bottomCenter,
  //                 child: AppToast(
  //                   message: playersToasts[1],
  //                   onComplete: () {
  //                     playersToasts[1] = "";
  //                     setState(() {});
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  String gameName = xandoGame;

  @override
  int maxGameTime = 20.minToSec;

  @override
  void onConcede(int index) {
    // TODO: implement onConcede
  }

  @override
  void onDetailsChange(Map<String, dynamic>? map) {
    if (map != null) {
      final details = XandODetails.fromMap(map);

      // played = false;
      // pausePlayerTime = false;
      // if (details.currentPlayerId == updatePlayerId) {
      //   return;
      // }
      // updatePlayerId = details.currentPlayerId;
      final playPos = details.playPos;
      if (playPos != -1) {
        playChar(playPos, false);
      } else {
        changePlayer();
      }
      pausePlayerTime = false;
      setState(() {});
    }
  }

  @override
  void onKeyEvent(KeyEvent event) {
    // TODO: implement onKeyEvent
  }

  @override
  void onLeave(int index) {
    // TODO: implement onLeave
  }

  @override
  void onPause() {
    // TODO: implement onPause
  }

  @override
  void onSpaceBarPressed() {
    // TODO: implement onSpaceBarPressed
  }

  @override
  void onStart() {
    initGrids();
  }

  @override
  void onPlayerTimeEnd() {
    playIfTimeOut();
  }

  @override
  void onTimeEnd() {
    // TODO: implement onTimeEnd
  }

  @override
  void onPlayerChange() {
    // TODO: implement onPlayerChange
  }
  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: CustomPaint(
              foregroundPainter: winDirection == null
                  ? null
                  : XandOLinePainter(
                      direction: winDirection!,
                      index: winIndex,
                      color: winChar! == XandOChar.x ? Colors.blue : Colors.red,
                      thickness: 3),
              child: GridView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize),
                children: List.generate(gridSize * gridSize, (index) {
                  final coordinates = convertToGrid(index, gridSize);
                  final rowindex = coordinates[0];
                  final colindex = coordinates[1];
                  final xando = xandos[colindex][rowindex];
                  return XandOTile(
                    key: Key(xando.id),
                    blink: firstTime && xando.char == XandOChar.empty,
                    xando: xando,
                    onPressed: () {
                      playChar(index);
                      // if (gameId != "" && currentPlayerId != myId) {
                      //   showToast(
                      //       1, "Its ${getUsername(currentPlayerId)}'s turn");
                      //   return;
                      // }
                      // if (gameId != "") {
                      //   updateDetails(index);
                      // } else {
                      //   playChar(index);
                      // }
                    },
                  );
                }),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    return Container();
  }
}
