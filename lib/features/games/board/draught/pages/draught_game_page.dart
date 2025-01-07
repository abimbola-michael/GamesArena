import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/games/board/draught/widgets/draught_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../../game/models/game_action.dart';
import '../../../../game/pages/base_game_page.dart';

import '../../../../../shared/services.dart';
import '../../../../../shared/widgets/custom_grid.dart';
import '../models/draught.dart';
import '../../../../../theme/colors.dart';
import '../../../../../shared/utils/constants.dart';
import '../../../../../shared/utils/utils.dart';

class DraughtGamePage extends BaseGamePage {
  static const route = "/draught";
  final Map<String, dynamic> args;
  final void Function(GameAction gameAction) onActionPressed;
  const DraughtGamePage(
    this.args,
    this.onActionPressed, {
    super.key,
  }) : super(args, onActionPressed);

  @override
  ConsumerState<DraughtGamePage> createState() => _DraughtGamePageState();
}

class _DraughtGamePageState extends BaseGamePageState<DraughtGamePage> {
  bool played = false;
  // DraughtDetails? prevDetails;
  bool? iWin;
  int gridSize = 10;
  double size = 0;
  //double messagePadding = 0, wonDraughtsPadding = 60;
  DraughtTile? selectedDraughtTile;
  List<DraughtTile> draughtTiles = [];
  List<List<Draught>> playersDraughts = [];
  List<List<Draught>> playersWonDraughts = [];

  List<String> gamePatterns = [];

  Map<int, List<int>> hintPositions = {};
  List<int> movePositions = [];

  String pauseId = "";
  String updatePlayerId = "";

  int currentPlayerIndex = 0;
  int drawMoveCount = 0;
  int maxDrawMoveCount = 25;

  List<int> playPositions = [];
  bool multiSelect = false;
  bool mustcapture = false;
  ScrollController scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = minSize / 8;
  }

  void initDraughtGrids() {
    setInitialCount(0);
    clearPattern();
    selectedDraughtTile = null;

    drawMoveCount = 0;
    mustcapture = false;
    hintPositions.clear();
    movePositions.clear();

    playersDraughts.clear();
    playersWonDraughts.clear();
    draughtTiles.clear();
    for (int i = 0; i < 2; i++) {
      playersDraughts.add([]);
      playersWonDraughts.add([]);
    }
    draughtTiles = List.generate(gridSize * gridSize, (index) {
      Draught? draught;
      final coordinates = convertToGrid(index, gridSize);
      final x = coordinates[0];
      final y = coordinates[1];
      if (y != (gridSize / 2) && y != (gridSize / 2) - 1) {
        if ((x.isEven && y.isOdd) || (y.isEven && x.isOdd)) {
          if (y < (gridSize / 2) - 1) {
            draught = Draught(x, y, "$index", 0, false);
            playersDraughts[0].add(draught);
          } else if (y > (gridSize / 2)) {
            draught = Draught(x, y, "$index", 1, false);
            playersDraughts[1].add(draught);
          }
        }
      }
      return DraughtTile(x, y, "$index", draught);
    });
    showPossiblePlayPositions();
    setState(() {});
  }

  Future updateDetails(int pos) async {
    await setDetails([
      DraughtDetails(
        pos: selectedDraughtTile!.id.toInt,
      ).toMap(),
      DraughtDetails(pos: pos).toMap()
    ]);
  }

  int convertPos(int pos, String userId) {
    if (userId == myId) return pos;
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    // return convertToPosition([x, (gridSize - 1) - y], gridSize);
    return convertToPosition(
        [(gridSize - 1) - x, (gridSize - 1) - y], gridSize);
  }

  bool checkSelection(int x, int y, DraughtDirection capDirection,
      [Draught? capdraught]) {
    List<DraughtDirection> directions = [
      DraughtDirection.topRight,
      DraughtDirection.topLeft,
      DraughtDirection.bottomRight,
      DraughtDirection.bottomLeft,
    ];
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    final draught = capdraught ?? draughtTile.draught;
    if (draught == null) return false;
    int player = draught.player;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      if (direction == getOppositeDirection(capDirection)) continue;
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);
      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) {
        return true;
      }
    }
    return false;
  }

  List<int> getPositions(int from, int to) {
    List<int> foundDraughtPositions = [];
    final selectedDraught = selectedDraughtTile!.draught!;
    final coordinates = convertToGrid(to, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    final fromcoordinates = convertToGrid(from, gridSize);
    final selX = fromcoordinates[0];
    final selY = fromcoordinates[1];
    final diffX = (x - selX).abs();
    final diffY = (y - selY).abs();
    final direction = getDraughtDirection(x - selX, y - selY);
    if (diffX == diffY) {
      int foundPos = -1;
      if (diffX >= 2) {
        for (int i = 1; i < diffX + 1; i++) {
          final middleX = getX(direction, selX, i);
          final middleY = getY(direction, selY, i);
          final middleDraughtPos =
              convertToPosition([middleX, middleY], gridSize);
          final middleDraughtTile = draughtTiles[middleDraughtPos];

          if (middleDraughtTile.draught != null) {
            if (middleDraughtTile.draught!.player != selectedDraught.player) {
              if (foundPos != -1) {
                return [];
              } else {
                foundPos = middleDraughtPos;
              }
            } else {
              return [];
            }
          } else {
            if (foundPos != -1) {
              foundDraughtPositions.add(foundPos);
              foundPos = -1;
            } else {
              if (!selectedDraught.king) {
                return [];
              }
            }
          }
        }
      }
    }
    return foundDraughtPositions;
  }

  bool isValidMovement(int from, int to) {
    final coordinates = convertToGrid(to, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    final fromcoordinates = convertToGrid(from, gridSize);
    final selX = fromcoordinates[0];
    final selY = fromcoordinates[1];
    final diffX = (x - selX).abs();
    final diffY = (y - selY).abs();
    final direction = getDraughtDirection(x - selX, y - selY);
    if (diffX == diffY) {
      for (int i = 1; i < diffX + 1; i++) {
        final middleX = getX(direction, selX, i);
        final middleY = getY(direction, selY, i);
        final middleDraughtPos =
            convertToPosition([middleX, middleY], gridSize);
        final middleDraughtTile = draughtTiles[middleDraughtPos];
        if (middleDraughtTile.draught != null) {
          return false;
        }
      }
    }
    return true;
  }

  void showPossiblePlayPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    movePositions.clear();

    final playerDraughts = playersDraughts[currentPlayer];
    for (int i = 0; i < playerDraughts.length; i++) {
      final draught = playerDraughts[i];
      int pos = convertToPosition([draught.x, draught.y], gridSize);
      //hintPositions.add(pos);
      hintPositions[pos] = [];
    }
    //getHintMessage(true);
    setState(() {});
  }

  void selectDraught(int pos) {
    int lastPos = -1;
    if (selectedDraughtTile == null) return;
    if (playPositions.isNotEmpty) {
      if (playPositions.contains(pos)) {
        final index = playPositions.indexWhere((element) => element == pos);
        playPositions.removeRange(index, playPositions.length);
      } else {
        lastPos = playPositions.last;
        final positions = getPositions(lastPos, pos);
        if (positions.isNotEmpty) {
          playPositions.add(pos);
        }
      }
    } else {
      lastPos = int.parse(selectedDraughtTile!.id);
      final positions = getPositions(lastPos, pos);
      if (positions.isNotEmpty) {
        playPositions.add(pos);
      }
    }
    if (playPositions.isNotEmpty) {
      if (!multiSelect) multiSelect = true;
    } else {
      multiSelect = false;
    }
    setState(() {});
  }

  void playDraught(int pos, [bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;

    final draughtTile = draughtTiles[pos];
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];

    if (draughtTile.draught != null) {
      if (draughtTile.draught!.player != currentPlayer) {
        final color = currentPlayer == 0 ? "Brown" : "Yellow";
        showPlayerToast(currentPlayer,
            "This is not your draught piece. Your draught piece color is $color");
        return;
      }
      if (selectedDraughtTile != null && selectedDraughtTile == draughtTile) {
        if (playPositions.isNotEmpty) {
          multiSelect = false;
          playPositions.clear();
        }
        hintPositions.clear();
        movePositions.clear();
        selectedDraughtTile = null;
        showPossiblePlayPositions();
      } else {
        if (mustcapture && !canCapture(x, y)) {
          showPlayerToast(currentPlayer, "You must capture your opponent");
          return;
        }
        selectedDraughtTile = draughtTile;
        getHintPositions(pos);
        // print("hintPositions = $hintPositions");
      }
      setState(() {});
    } else {
      if (selectedDraughtTile != null) {
        moveDraught(pos, isClick);
      }
    }
  }

  // void playDraught(int pos, [bool isClick = true]) async {
  //   if (awaiting) return;
  //   if (isClick && gameId.isNotEmpty && currentPlayerId != myId) {
  //     showPlayerToast(myPlayer, "Its ${getUsername(currentPlayerId)}'s turn");
  //     return;
  //   }
  //   final draughtTile = draughtTiles[pos];
  //   final coordinates = convertToGrid(pos, gridSize);
  //   final x = coordinates[0];
  //   final y = coordinates[1];

  //   if (draughtTile.draught != null) {
  //     if (draughtTile.draught!.player != currentPlayer) {
  //       final color = currentPlayer == 0 ? "Brown" : "Yellow";
  //       showPlayerToast(currentPlayer,
  //           "This is not your draught piece. Your draught piece color is $color");
  //       return;
  //     }
  //     if (selectedDraughtTile != null && selectedDraughtTile == draughtTile) {
  //       if (playPositions.isNotEmpty) {
  //         multiSelect = false;
  //         playPositions.clear();
  //       }
  //       hintPositions.clear();
  //       selectedDraughtTile = null;
  //       showPossiblePlayPositions();
  //     } else {
  //       if (mustcapture && !canCapture(x, y)) {
  //         showPlayerToast(currentPlayer, "You must capture your opponent");
  //         return;
  //       }
  //       selectedDraughtTile = draughtTile;
  //       getHintPositions(pos);
  //     }
  //     setState(() {});
  //   } else {
  //     if (selectedDraughtTile != null) {
  //       if (mustcapture) {
  //         DraughtDirection? direction;
  //         if (playPositions.isEmpty) {
  //           final selPos = convertToPosition(
  //               [selectedDraughtTile!.x, selectedDraughtTile!.y], gridSize);
  //           direction = getDirection(selPos, pos);
  //         } else {
  //           direction = getDirection(playPositions.last, pos);
  //         }
  //         final can =
  //             checkSelection(x, y, direction, selectedDraughtTile!.draught);
  //         if (can || playPositions.contains(pos)) {
  //           selectDraught(pos);
  //         } else {
  //           awaiting = true;

  //           if (playPositions.isNotEmpty) {
  //             playPositions.add(pos);

  //             moveMultipleDraughts(isClick);
  //           } else {
  //             moveDraught(pos, isClick);
  //           }
  //           awaiting = false;
  //         }
  //       } else {
  //         moveDraught(pos, isClick);
  //       }
  //     }
  //   }
  // }

  // void moveMultipleDraughts([bool isClick = true]) async {
  //   if (isClick) {
  //     await updateDetails(playPositions);
  //   }

  //   for (int i = 0; i < playPositions.length; i++) {
  //     final index = playPositions[i];
  //     moveDraught(index, false);
  //     if (i != playPositions.length - 1) {
  //       await Future.delayed(const Duration(milliseconds: 500));
  //     }
  //   }
  //   awaiting = false;
  //   multiSelect = false;
  //   playPositions.clear();
  //   hintPositions.clear();
  //   changePlayer();
  //   selectedDraughtTile = null;
  //   showPossiblePlayPositions();
  //   setState(() {});
  // }

  DraughtDirection getDirection(int lastPos, int newPos) {
    final lastCoordinates = convertToGrid(lastPos, gridSize);
    final lastX = lastCoordinates[0];
    final lastY = lastCoordinates[1];
    final newCoordinates = convertToGrid(newPos, gridSize);
    final newX = newCoordinates[0];
    final newY = newCoordinates[1];
    return getDraughtDirection(newX - lastX, newY - lastY);
  }

  void moveDraught(int pos, [bool isClick = true]) async {
    int endPos = pos;
    if (selectedDraughtTile == null) {
      return;
    }
    var capturePositions = hintPositions[pos];
    // print(
    //     "hintPositions = $hintPositions, capturePositions = $capturePositions");
    if (capturePositions == null || capturePositions.isEmpty) {
      capturePositions = [pos];
    }
    for (int i = 0; i < capturePositions.length; i++) {
      final pos = capturePositions[i];

      final draughtTile = draughtTiles[pos];
      final coordinates = convertToGrid(pos, gridSize);
      final x = coordinates[0];
      final y = coordinates[1];
      if (selectedDraughtTile == null) return;
      final selX = selectedDraughtTile!.x;
      final selY = selectedDraughtTile!.y;
      final selPos = convertToPosition([selX, selY], gridSize);
      final xDiff = (x - selX).abs();
      final yDiff = (y - selY).abs();
      final selectedDraught = selectedDraughtTile!.draught!;

      if (xDiff != yDiff) return;

      final foundPositions = getPositions(selPos, pos);

      if (foundPositions.isNotEmpty) {
        for (int i = 0; i < foundPositions.length; i++) {
          final foundPos = foundPositions[i];
          final foundDraughtTile = draughtTiles[foundPos];
          final foundDraught = foundDraughtTile.draught!;
          final opponentIndex = foundDraught.player;
          final playerIndex = selectedDraught.player;
          final playerDraughts = playersDraughts[opponentIndex];
          final playerWonDraughts = playersWonDraughts[playerIndex];
          playerWonDraughts.add(foundDraught);
          updateCount(playerIndex, playerWonDraughts.length);

          playerDraughts
              .removeWhere((element) => element.id == foundDraught.id);
          foundDraughtTile.draught = null;
        }
        drawMoveCount = 0;
        clearPattern();
      } else {
        if (!isValidMovement(selPos, pos)) return;

        if (!selectedDraught.king &&
            ((yDiff > 1 || !(y - selY).isNegative && currentPlayer == 1) ||
                ((y - selY).isNegative && currentPlayer == 0))) {
          return;
        }
        if (mustcapture) {
          showPlayerToast(currentPlayer, "You must capture your opponent");
          return;
        }
        savePattern();
        if (selectedDraught.king) {
          drawMoveCount++;
        } else {
          drawMoveCount = 0;
        }
      }

      if ((y == 0 && currentPlayer == 1) ||
          (y == gridSize - 1 && currentPlayer == 0)) {
        selectedDraughtTile!.draught!.king = true;
      }
      selectedDraughtTile!.draught!.x = x;
      selectedDraughtTile!.draught!.y = y;
      draughtTile.draught = selectedDraughtTile!.draught;
      selectedDraughtTile!.draught = null;
      checkWingame();
      if (i == 0 && isClick) {
        updateDetails(endPos);
      }
      if (i != capturePositions.length - 1) {
        selectedDraughtTile = draughtTile;
      } else {
        selectedDraughtTile = null;
        changePlayer();
        hintPositions.clear();
        showPossiblePlayPositions();
      }

      setState(() {});
      if (!seeking && i != capturePositions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    // if (isClick) {
    //   updateDetails(selectedPos, pos);
    // }
  }

  // void moveDraught(int pos, [bool isClick = true]) async {
  //   if (isClick) {
  //     await updateDetails([pos]);
  //   }

  //   final draughtTile = draughtTiles[pos];
  //   final coordinates = convertToGrid(pos, gridSize);
  //   final x = coordinates[0];
  //   final y = coordinates[1];
  //   final selX = selectedDraughtTile!.x;
  //   final selY = selectedDraughtTile!.y;
  //   final selPos = convertToPosition([selX, selY], gridSize);
  //   final xDiff = (x - selX).abs();
  //   final yDiff = (y - selY).abs();
  //   final selectedDraught = selectedDraughtTile!.draught!;
  //   if (xDiff != yDiff) return;

  //   final foundPositions = getPositions(selPos, pos);
  //   if (foundPositions.isNotEmpty) {
  //     for (int i = 0; i < foundPositions.length; i++) {
  //       final foundPos = foundPositions[i];
  //       final foundDraughtTile = draughtTiles[foundPos];
  //       final foundDraught = foundDraughtTile.draught!;
  //       final opponentIndex = foundDraught.player;
  //       final playerIndex = selectedDraught.player;
  //       final playerDraughts = playersDraughts[opponentIndex];
  //       final playerWonDraughts = playersWonDraughts[playerIndex];
  //       playerWonDraughts.add(foundDraught);
  //       updateCount(playerIndex, playerWonDraughts.length);

  //       playerDraughts.removeWhere((element) => element.id == foundDraught.id);
  //       foundDraughtTile.draught = null;
  //     }
  //     drawMoveCount = 0;
  //     clearPattern();
  //   } else {
  //     if (!isValidMovement(selPos, pos)) return;

  //     if (!selectedDraught.king &&
  //         ((yDiff > 1 || !(y - selY).isNegative && currentPlayer == 1) ||
  //             ((y - selY).isNegative && currentPlayer == 0))) {
  //       return;
  //     }
  //     if (mustcapture) {
  //       showPlayerToast(currentPlayer, "You must capture your opponent");
  //       return;
  //     }
  //     savePattern();
  //     if (selectedDraught.king) {
  //       drawMoveCount++;
  //     } else {
  //       drawMoveCount = 0;
  //     }
  //   }
  //   if ((y == 0 && currentPlayer == 1) ||
  //       (y == gridSize - 1 && currentPlayer == 0)) {
  //     selectedDraughtTile!.draught!.king = true;
  //   }
  //   selectedDraughtTile!.draught!.x = x;
  //   selectedDraughtTile!.draught!.y = y;
  //   draughtTile.draught = selectedDraughtTile!.draught;
  //   selectedDraughtTile!.draught = null;
  //   checkWingame();
  //   if (multiSelect) {
  //     selectedDraughtTile = draughtTile;
  //   } else {
  //     selectedDraughtTile = null;
  //     changePlayer();
  //     hintPositions.clear();
  //     showPossiblePlayPositions();
  //   }

  //   setState(() {});
  // }

  List<DraughtDirection> getCaptureDirections(
      int x, int y, DraughtDirection capDirection, Draught capdraught) {
    List<DraughtDirection> captureDirections = [];
    List<DraughtDirection> directions = [
      DraughtDirection.topRight,
      DraughtDirection.topLeft,
      DraughtDirection.bottomRight,
      DraughtDirection.bottomLeft,
    ];
    directions.remove(capDirection);
    if (exceedRange(x, y)) return [];
    //final pos = convertToPosition([x, y], gridSize);
    final draught = capdraught;
    int player = draught.player;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      if (direction == getOppositeDirection(capDirection)) continue;
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);
      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) captureDirections.add(direction);
    }
    return captureDirections;
  }

  // void getMoveHintPositions(int pos) {
  //   //final pos = convertToPosition([x, y], gridSize);
  //   final grids = convertToGrid(pos, gridSize);
  //   int x = grids[0];
  //   int y = grids[1];
  //   final draughtTile = draughtTiles[pos];
  //   if (draughtTile.draught == null) return;
  //   int player = draughtTile.draught!.player;
  //   List<DraughtDirection> directions = [];
  //   if (player == 0) {
  //     directions = [DraughtDirection.bottomLeft, DraughtDirection.bottomRight];
  //   } else {
  //     directions = [DraughtDirection.topLeft, DraughtDirection.topRight];
  //   }
  //   for (int i = 0; i < directions.length; i++) {
  //     final direction = directions[i];
  //     final newX = getX(direction, x, 1);
  //     final newY = getY(direction, y, 1);
  //     if (exceedRange(newX, newY)) continue;
  //     final pos = convertToPosition([newX, newY], gridSize);
  //     final draughtTile = draughtTiles[pos];
  //     if (draughtTile.draught == null) {
  //       hintPositions.add(pos);
  //     }
  //   }

  //   setState(() {});
  // }

  DraughtDirection getEquivalentDirection(DraughtDirection direction) {
    if (direction == DraughtDirection.topLeft) {
      return DraughtDirection.topRight;
    } else if (direction == DraughtDirection.topRight) {
      return DraughtDirection.topLeft;
    } else if (direction == DraughtDirection.bottomLeft) {
      return DraughtDirection.bottomRight;
    } else if (direction == DraughtDirection.bottomRight) {
      return DraughtDirection.bottomLeft;
    }
    return DraughtDirection.bottomLeft;
  }

  DraughtDirection getOppositeDirection(DraughtDirection direction) {
    if (direction == DraughtDirection.topLeft) {
      return DraughtDirection.bottomRight;
    } else if (direction == DraughtDirection.topRight) {
      return DraughtDirection.bottomLeft;
    } else if (direction == DraughtDirection.bottomLeft) {
      return DraughtDirection.topRight;
    } else if (direction == DraughtDirection.bottomRight) {
      return DraughtDirection.topLeft;
    }
    return DraughtDirection.bottomLeft;
  }

  // void getHintPositions(int pos,
  //     [Draught? capdraught, DraughtDirection? capDirection]) {
  //   if (capdraught == null) {
  //     hintPositions.clear();
  //   }
  //   List<DraughtDirection> directions = capDirection != null
  //       ? [capDirection]
  //       : [
  //           DraughtDirection.topRight,
  //           DraughtDirection.topLeft,
  //           DraughtDirection.bottomRight,
  //           DraughtDirection.bottomLeft,
  //         ];

  //   final grids = convertToGrid(pos, gridSize);
  //   int x = grids[0];
  //   int y = grids[1];

  //   //final capture = capdraught == null ? canCapture(x, y) : true;
  //   final draughtTile = draughtTiles[pos];
  //   final draught = capdraught ?? draughtTile.draught;
  //   if (draught == null) return;
  //   final isKing = draught.king;
  //   int player = draught.player;

  //   for (int i = 0; i < directions.length; i++) {
  //     final direction = directions[i];
  //     int foundPlayersCount = 0;
  //     int emptySpacesCount = 0;
  //     final capture = canCapture(x, y, draught, direction);
  //     if (mustcapture && !capture) continue;
  //     bool found = false, hasFoundAPlayer = false;
  //     for (int j = 1; j < gridSize; j++) {
  //       final newX = getX(direction, x, j);
  //       final newY = getY(direction, y, j);
  //       if (exceedRange(newX, newY)) {
  //         if (emptySpacesCount > 0 && capture && foundPlayersCount == 0) {
  //           removeMovePositions(emptySpacesCount);
  //         }
  //         break;
  //       }
  //       final pos = convertToPosition([newX, newY], gridSize);
  //       final draughtTile = draughtTiles[pos];
  //       if (draughtTile.draught != null) {
  //         final foundDraught = draughtTile.draught!;
  //         if (emptySpacesCount > 0 && foundPlayersCount == 0 && !isKing) {
  //           if (capture) {
  //             removeMovePositions(emptySpacesCount);
  //           }
  //           break;
  //         }
  //         if (foundDraught.player != player) {
  //           if (!found) {
  //             found = true;
  //             hasFoundAPlayer = true;
  //           } else {
  //             if (emptySpacesCount > 0 &&
  //                 foundPlayersCount == 0 &&
  //                 isKing &&
  //                 capture) {
  //               removeMovePositions(emptySpacesCount);
  //             }
  //             break;
  //           }
  //         } else {
  //           if (emptySpacesCount > 0 &&
  //               foundPlayersCount == 0 &&
  //               isKing &&
  //               capture) {
  //             removeMovePositions(emptySpacesCount);
  //           }
  //           break;
  //         }
  //         //emptySpacesCount = 0;
  //       } else {
  //         if (!isKing && !found) {
  //           if ((player == 0 &&
  //                   (direction == DraughtDirection.topLeft ||
  //                       direction == DraughtDirection.topRight)) ||
  //               (player == 1 &&
  //                   (direction == DraughtDirection.bottomLeft ||
  //                       direction == DraughtDirection.bottomRight))) {
  //             break;
  //           }
  //         }
  //         if (emptySpacesCount > 0 && !found && !isKing) {
  //           if (capture && foundPlayersCount == 0) {
  //             removeMovePositions(emptySpacesCount);
  //           }
  //           break;
  //         }
  //         if (hasFoundAPlayer) {
  //           final captureDirections =
  //               direction == DraughtDirection.bottomLeft ||
  //                       direction == DraughtDirection.topRight
  //                   ? [DraughtDirection.topLeft, DraughtDirection.bottomRight]
  //                   : [DraughtDirection.bottomLeft, DraughtDirection.topRight];

  //           for (int i = 0; i < captureDirections.length; i++) {
  //             getHintPositions(pos, draught, captureDirections[i]);
  //           }
  //         }
  //         if (found) {
  //           foundPlayersCount++;
  //           found = false;
  //           emptySpacesCount = 0;
  //         }
  //         emptySpacesCount++;
  //         hintPositions.add(pos);
  //       }
  //     }
  //   }
  //   setState(() {});
  // }

  void getHintPositions(int pos,
      [Draught? capdraught,
      DraughtDirection? capDirection,
      List<int>? prevCapturePositions]) {
    if (capdraught == null) {
      hintPositions.clear();
      movePositions.clear();
    }

    List<DraughtDirection> directions = capDirection != null
        ? [capDirection]
        : [
            DraughtDirection.topRight,
            DraughtDirection.topLeft,
            DraughtDirection.bottomRight,
            DraughtDirection.bottomLeft,
          ];

    final grids = convertToGrid(pos, gridSize);
    int x = grids[0];
    int y = grids[1];

    //final capture = capdraught == null ? canCapture(x, y) : true;
    final draughtTile = draughtTiles[pos];
    final draught = capdraught ?? draughtTile.draught;
    if (draught == null) return;
    final isKing = draught.king;
    int player = draught.player;

    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      int foundPlayersCount = 0;
      int emptySpacesCount = 0;
      final capture = canCapture(x, y, draught, direction);
      if (mustcapture && !capture) continue;
      bool found = false, hasFoundAPlayer = false;

      for (int j = 1; j < gridSize; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) {
          if (emptySpacesCount > 0 && capture && foundPlayersCount == 0) {
            removeMovePositions(movePositions, emptySpacesCount);
          }
          break;
        }
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          final foundDraught = draughtTile.draught!;
          if (emptySpacesCount > 0 && foundPlayersCount == 0 && !isKing) {
            if (capture) {
              removeMovePositions(movePositions, emptySpacesCount);
            }
            break;
          }
          if (foundDraught.player != player) {
            if (!found) {
              found = true;
              hasFoundAPlayer = true;
            } else {
              if (emptySpacesCount > 0 &&
                  foundPlayersCount == 0 &&
                  isKing &&
                  capture) {
                removeMovePositions(movePositions, emptySpacesCount);
              }
              break;
            }
          } else {
            if (emptySpacesCount > 0 &&
                foundPlayersCount == 0 &&
                isKing &&
                capture) {
              removeMovePositions(movePositions, emptySpacesCount);
            }
            break;
          }
          //emptySpacesCount = 0;
        } else {
          if (!isKing && !found) {
            if ((player == 0 &&
                    (direction == DraughtDirection.topLeft ||
                        direction == DraughtDirection.topRight)) ||
                (player == 1 &&
                    (direction == DraughtDirection.bottomLeft ||
                        direction == DraughtDirection.bottomRight))) {
              break;
            }
          }
          if (emptySpacesCount > 0 && !found && !isKing) {
            if (capture && foundPlayersCount == 0) {
              removeMovePositions(movePositions, emptySpacesCount);
            }
            break;
          }
          List<int> capturePositions = [...(prevCapturePositions ?? []), pos];
          hintPositions[pos] = capturePositions;

          if (hasFoundAPlayer) {
            final captureDirections =
                direction == DraughtDirection.bottomLeft ||
                        direction == DraughtDirection.topRight
                    ? [DraughtDirection.topLeft, DraughtDirection.bottomRight]
                    : [DraughtDirection.bottomLeft, DraughtDirection.topRight];

            for (int i = 0; i < captureDirections.length; i++) {
              getHintPositions(
                  pos, draught, captureDirections[i], capturePositions);
            }
          }
          if (found) {
            foundPlayersCount++;
            found = false;
            emptySpacesCount = 0;
          }
          emptySpacesCount++;
          movePositions.add(pos);
        }
      }
    }
    setState(() {});
  }

  void getHintMessage(bool played, [bool king = false]) {
    if (played) {
      hintMessage =
          "Tap on ${currentPlayer == 0 ? "Brown" : "Yellow"} piece to make your move";
    } else {
      if (king) {
        hintMessage =
            "A King can move 1 or multiple steps diagonally going above opponent to capture and can make multiple captures at different directions";
      } else {
        hintMessage =
            "A normal piece can move 1 step and 2 steps diagonally going above opponent to capture and can make multiple captures at different directions";
      }
    }
    message = hintMessage;
    setState(() {});
  }

  void removeMovePositions(List<int> movePositions, int count) {
    for (int i = 0; i < count; i++) {
      if (movePositions.isNotEmpty) {
        hintPositions.remove(movePositions.last);
        movePositions.removeLast();
      }
    }
  }

  bool canMove(int x, int y) {
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    if (draughtTile.draught == null) return false;
    int player = draughtTile.draught!.player;
    List<DraughtDirection> directions = [];
    if (player == 0) {
      directions = [DraughtDirection.bottomLeft, DraughtDirection.bottomRight];
    } else {
      directions = [DraughtDirection.topLeft, DraughtDirection.topRight];
    }
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      final newX = getX(direction, x, 1);
      final newY = getY(direction, y, 1);
      if (exceedRange(newX, newY)) continue;
      final pos = convertToPosition([newX, newY], gridSize);
      final draughtTile = draughtTiles[pos];
      if (draughtTile.draught == null) return true;
    }
    return false;
  }

  bool canCapture(int x, int y,
      [Draught? capdraught,
      DraughtDirection? capDirection,
      DraughtDirection? comingDirection]) {
    List<DraughtDirection> directions = capDirection != null
        ? [capDirection]
        : [
            DraughtDirection.topRight,
            DraughtDirection.topLeft,
            DraughtDirection.bottomRight,
            DraughtDirection.bottomLeft,
          ];
    if (comingDirection != null &&
        directions.contains(getOppositeDirection(comingDirection))) {
      directions.remove(comingDirection);
    }
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    final draught = capdraught ?? draughtTile.draught;
    if (draught == null) return false;
    int player = draught.player;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        } else {
          foundPos = -1;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);
      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) return true;
    }
    return false;
  }

  bool hasMultipleCapture(int x, int y) {
    List<DraughtDirection> directions = [
      DraughtDirection.topRight,
      DraughtDirection.topLeft,
      DraughtDirection.bottomRight,
      DraughtDirection.bottomLeft,
    ];
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    if (draughtTile.draught == null) return false;
    int player = draughtTile.draught!.player;
    final draught = draughtTile.draught!;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);

      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) {
        int end = draught.king ? gridSize : 2;
        for (int i = 0; i < directions.length; i++) {
          final direction = directions[i];
          int foundPos = -1;
          for (int j = 1; j < end; j++) {
            final newX = getX(direction, lastX, j);
            final newY = getY(direction, lastY, j);
            if (exceedRange(newX, newY)) break;
            final pos = convertToPosition([newX, newY], gridSize);
            final draughtTile = draughtTiles[pos];
            if (draughtTile.draught != null) {
              if (draughtTile.draught!.player == player) {
                foundPos = -1;
              } else {
                foundPos = j;
              }
              break;
            }
          }
          if (foundPos == -1) continue;
          final last2X = getX(direction, lastX, foundPos + 1);
          final last2Y = getY(direction, lastY, foundPos + 1);

          if (exceedRange(last2X, last2Y)) continue;
          final last2Pos = convertToPosition([last2X, last2Y], gridSize);
          final last2DraughtTile = draughtTiles[last2Pos];
          if (last2DraughtTile.draught == null) {
            return true;
          } else {
            continue;
          }
        }
      }
    }
    return false;
  }

  String getPattern(int player, List<Draught> draughts) {
    String pattern = "";
    for (int i = 0; i < draughts.length; i++) {
      final draught = draughts[i];
      final x = draught.x;
      final y = draught.y;
      pattern += "$player$x$y, ";
    }
    return pattern;
  }

  void savePattern() {
    String pattern = "";
    pattern += getPattern(0, playersDraughts[0]);
    pattern += getPattern(1, playersDraughts[1]);
    gamePatterns.add(pattern);
    checkPattern();
  }

  void clearPattern() {
    gamePatterns.clear();
  }

  void checkPattern() {
    if (gamePatterns.isNotEmpty) {
      Map<String, int> patternsMap = {};
      for (int i = 0; i < gamePatterns.length; i++) {
        final pattern = gamePatterns[i];
        if (patternsMap.isNotEmpty && patternsMap[pattern] != null) {
          patternsMap[pattern] = patternsMap[pattern]! + 1;
          if (patternsMap[pattern]! == 3) {
            reason = "3 same game pattern";
            updateDraw();
          }
        } else {
          patternsMap[pattern] = 1;
        }
      }
    }
  }

  void checkForDraw() {
    if (drawMoveCount == maxDrawMoveCount) {
      reason = "25 moves without capturing";
      updateDraw();
    }
  }

  void checkIfCanMove() {
    mustcapture = false;
    //final next = nextIndex(2, currentPlayer);
    final next = getNextPlayerIndex();
    final nextPlayerDraughts = playersDraughts[next];
    int captureCount = 0;
    int moveCount = 0;
    if (nextPlayerDraughts.isNotEmpty) {
      for (int i = 0; i < nextPlayerDraughts.length; i++) {
        final draught = nextPlayerDraughts[i];
        final x = draught.x;
        final y = draught.y;
        if (canCapture(x, y)) {
          captureCount++;
        }
        if (canMove(x, y)) {
          moveCount++;
        }
      }
      mustcapture = captureCount > 0;
      if (moveCount == 0 && captureCount == 0) {
        reason = "no possible movement";
        updateDraw();
      }
    }
  }

  void updateWingame(bool isTimer) {
    updateWin(currentPlayer);
  }

  void checkWingame() {
    final playerDraughts = playersDraughts[nextIndex(2, currentPlayer)];
    if (playerDraughts.isEmpty) {
      reason = "capturing all pieces";
      updateWin(currentPlayer);
      //updateWingame(false);
    }
  }

  bool isDown(DraughtDirection direction) {
    return direction == DraughtDirection.bottomLeft ||
        direction == DraughtDirection.bottomRight;
  }

  DraughtDirection getDraughtDirection(int x, int y) {
    DraughtDirection direction = DraughtDirection.bottomLeft;
    if (x < 0 && y < 0) {
      direction = DraughtDirection.topLeft;
    } else if (x > 0 && y > 0) {
      direction = DraughtDirection.bottomRight;
    } else if (x < 0 && y > 0) {
      direction = DraughtDirection.bottomLeft;
    } else if (x > 0 && y < 0) {
      direction = DraughtDirection.topRight;
    }
    return direction;
  }

  int getX(DraughtDirection direction, int x, int step) {
    int newX = 0;
    if (direction == DraughtDirection.topRight ||
        direction == DraughtDirection.bottomRight) {
      newX = x + step;
    } else if (direction == DraughtDirection.topLeft ||
        direction == DraughtDirection.bottomLeft) {
      newX = x - step;
    }
    return newX;
  }

  int getY(DraughtDirection direction, int y, int step) {
    int newY = 0;
    if (direction == DraughtDirection.bottomRight ||
        direction == DraughtDirection.bottomLeft) {
      newY = y + step;
    } else if (direction == DraughtDirection.topRight ||
        direction == DraughtDirection.topLeft) {
      newY = y - step;
    }
    return newY;
  }

  bool exceedRange(int x, int y) =>
      x > gridSize - 1 || x < 0 || y > gridSize - 1 || y < 0;

  @override
  int? maxGameTime;

  @override
  int? maxPlayerTime = 10.minToSec;

  @override
  void onConcede(int index) {}

  @override
  Future onDetailsChange(Map<String, dynamic>? map) async {
    if (map != null) {
      final details = DraughtDetails.fromMap(map);
      final pos = details.pos;

      if (pos != -1) {
        playDraught(pos, false);
      } else {
        changePlayer();
      }
      // final startPos = details.startPos;
      // final endPos = details.endPos;

      // if (endPos != -1) {
      //   playDraught(startPos, false);

      //   playDraught(endPos, false);
      // } else {
      //   changePlayer();
      // }

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
  void onPause() {}

  @override
  void onSpaceBarPressed() {}

  @override
  void onInit() {}

  @override
  void onResume() {
    // TODO: implement onResume
  }
  @override
  void onStart() {
    initDraughtGrids();
  }

  @override
  void onPlayerTimeEnd() {
    // TODO: implement onTimeChange
  }

  @override
  void onTimeEnd() {
    // TODO: implement onTimeEnd
  }
  @override
  void onPlayerChange(int player) {
    checkIfCanMove();
    checkForDraw();
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    if (playersWonDraughts.isEmpty) return Container();

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final size = width / gridSize;
      return CustomGrid(
          height: size * 2,
          width: width,
          crossAxisAlignment: CrossAxisAlignment.start,
          items: playersWonDraughts[index],
          gridSize: gridSize,
          itemBuilder: (pindex) {
            final draughts = playersWonDraughts[index];
            final draught = draughts[pindex];
            return Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: darkMode ? lightestWhite : lightestBlack,
                borderRadius: BorderRadius.only(
                  topLeft:
                      pindex == 0 ? const Radius.circular(10) : Radius.zero,
                  bottomLeft:
                      (pindex == 0 && draughts.length <= 10) || pindex == 10
                          ? const Radius.circular(10)
                          : Radius.zero,
                  topRight: pindex == 9 ||
                          (pindex == draughts.length - 1 &&
                              draughts.length <= 10)
                      ? const Radius.circular(10)
                      : Radius.zero,
                  bottomRight: pindex == draughts.length - 1 || pindex == 9
                      ? const Radius.circular(10)
                      : Radius.zero,
                ),
              ),
              child: DraughtWidget(draught: draught, size: size / 1.5),
            );
          });
    });
  }

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Scrollbar(
            thumbVisibility: false,
            controller: scrollController,
            child: GridView(
              controller: scrollController,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize),
              children: List.generate(gridSize * gridSize, (index) {
                final coordinates = convertToGrid(index, gridSize);
                final x = coordinates[0];
                final y = coordinates[1];
                final draughtTile = draughtTiles.get(index);
                return DraughtTileWidget(
                    blink: hintPositions.containsKey(index),
                    gameId: gameId,
                    key: Key(draughtTile?.id ?? "$index"),
                    myPlayer: myPlayer,
                    x: x,
                    y: y,
                    highLight: selectedDraughtTile == draughtTile ||
                        (playPositions.isNotEmpty &&
                            playPositions.contains(index)),
                    draughtTile: draughtTile,
                    onPressed: () {
                      playDraught(index);
                    },
                    size: size);
              }),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onDispose() {
    scrollController.dispose();
  }

  @override
  void onInitState() {
    // TODO: implement onInitState
  }
}
