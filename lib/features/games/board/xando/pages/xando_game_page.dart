import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/pages/base_game_page.dart';
import 'package:gamesarena/features/games/board/xando/widgets/xando_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/utils/call_utils.dart';
import '../../../../game/models/game_action.dart';
import '../widgets/xando_line_paint.dart';
import '../models/xando.dart';
import '../../../../../shared/utils/utils.dart';

class XandOGamePage extends BaseGamePage {
  static const route = "/xando";
  final Map<String, dynamic> args;
  final CallUtils callUtils;
  final void Function(GameAction gameAction) onActionPressed;
  const XandOGamePage(
    this.args,
    this.callUtils,
    this.onActionPressed, {
    super.key,
  }) : super(args, callUtils, onActionPressed);

  @override
  ConsumerState<XandOGamePage> createState() => _XandOGamePageState();
}

class _XandOGamePageState extends BaseGamePageState<XandOGamePage> {
  bool played = false;
  int gridSize = 3;
  List<List<XandOTile>> xandoTiles = [];

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

  void updateDetails(int playPos) async {
    final details = XandODetails(playPos: playPos);
    await setDetail(details.toMap());
  }

  void playChar(int index, [int? playerIndex, bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;

    final coordinates = convertToGrid(index, gridSize);
    final rowindex = coordinates[0];
    final colindex = coordinates[1];
    final xando = xandoTiles.get(colindex)?.get(rowindex);
    if (xando != null && xando.char == null) {
      if (isClick) updateDetails(index);
      xandoTiles[colindex][rowindex].char =
          getChar(playerIndex ?? currentPlayer);
      checkIfMatch(xando);
      //getHintMessage();
      setState(() {});
    }
  }

  void playIfTimeOut() {
    List<int> unplayedPositions = [];
    for (int i = 0; i < xandoTiles.length; i++) {
      for (int j = 0; j < xandoTiles[i].length; j++) {
        final xandO = xandoTiles[i][j];
        if (xandO.char == null) {
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

  void checkIfMatch(XandOTile xando) async {
    // if (awaiting) return;
    final x = xando.x;
    final y = xando.y;
    final char = xando.char;
    int vertCount = 0, horCount = 0, lowerDiagCount = 0, upperDiagCount = 0;
    bool foundMatch = false;

    for (int i = 0; i < 3; i++) {
      final vertXandO = xandoTiles[i][x];
      if (vertXandO.char == char) {
        vertCount++;
      }
      if (vertCount == 3) {
        winIndex = x;
        winDirection = LineDirection.vertical;
        foundMatch = true;
        break;
      }

      final horXandO = xandoTiles[y][i];
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
          final lowerdiagXandO = xandoTiles[2 - i][i];
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
          final upperdiagXandO = xandoTiles[i][i];
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
    message = "Play";

    if (foundMatch || playedCount == (gridSize * gridSize)) {
      if (foundMatch) {
        winChar = xando.char;
        message = "You Won";
        incrementCount(currentPlayer);
        // playersScores[currentPlayer]++;
        // updateMatchRecord();
        // toastWinner(winChar!.index);
        //updateWin(currentPlayer);
      }
      awaiting = true;
      changePlayer();
      setState(() {});
      if (!seeking) {
        await Future.delayed(const Duration(seconds: 2));
      }

      initGrids();
    } else {
      changePlayer();
      setState(() {});
    }
  }

  // Future resetChars() async {
  //   playedCount = 0;

  //   playerTime = maxPlayerTime;
  //   awaiting = false;
  //   xandoTiles.clear();
  //   winDirection = null;
  //   winChar = null;
  //   winIndex = -1;
  //   message = "Play";
  //   initGrids();

  //   setState(() {});
  // }

  // void resetScores() {
  //   playersScores = List.generate(2, (index) => 0);
  // }

  void initGrids() {
    playedCount = 0;
    awaiting = false;
    winDirection = null;
    winChar = null;
    winIndex = -1;
    message = "Play";
    resetPlayerTime();

    xandoTiles = List.generate(
        gridSize,
        (colindex) => List.generate(gridSize, (rowindex) {
              final index = convertToPosition([rowindex, colindex], gridSize);
              return XandOTile(null, rowindex, colindex, "$index");
            }));
    setState(() {});
  }

  @override
  int? maxGameTime = 15.minToSec;

  @override
  int? maxPlayerTime;

  @override
  void onConcede(int index) {
    // TODO: implement onConcede
  }

  @override
  Future onDetailsChange(Map<String, dynamic>? map) async {
    if (map != null) {
      final details = XandODetails.fromMap(map);
      final playerIndex = getPlayerIndex(map["id"]);

      final playPos = details.playPos;
      if (playPos != -1) {
        playChar(playPos, playerIndex, false);
      } else {
        changePlayer();
      }
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
  void onInit() {}

  @override
  void onResume() {
    // TODO: implement onResume
  }

  @override
  void onStart() {
    setInitialCount(0);
    initGrids();
  }

  @override
  void onPlayerTimeEnd() {
    playIfTimeOut();
  }

  @override
  void onTimeEnd() {
    updateWinForPlayerWithHighestCount();
  }

  @override
  void onPlayerChange(int player) {
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
                      xandOChar: winChar!),
              child: GridView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize),
                children: List.generate(gridSize * gridSize, (index) {
                  final coordinates = convertToGrid(index, gridSize);
                  final rowindex = coordinates[0];
                  final colindex = coordinates[1];
                  final xandoTile = xandoTiles.get(colindex)?.get(rowindex);
                  return XandOTileWidget(
                    key: Key(xandoTile?.id ?? "$index"),
                    blink: firstTime &&
                        xandoTile != null &&
                        xandoTile.char == null,
                    xandOTile: xandoTile,
                    onPressed: () {
                      playChar(index);
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

  @override
  void onDispose() {
    // TODO: implement onDispose
  }

  @override
  void onInitState() {
    // TODO: implement onInitState
  }
}
