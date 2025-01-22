// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/games/board/ludo/widgets/roll_dice_button.dart';
import 'package:gamesarena/features/games/board/ludo/widgets/ludo_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/utils/call_utils.dart';
import '../../../../game/models/game_action.dart';
import '../../../../game/pages/base_game_page.dart';

import '../../../../../shared/widgets/blinking_border_container.dart';
import '../widgets/ludo_dice.dart';
import '../widgets/ludo_triangle_paint.dart';
import '../models/ludo.dart';
import '../../../../../theme/colors.dart';
import '../../../../../shared/utils/utils.dart';

class LudoGamePage extends BaseGamePage {
  static const route = "/ludo";
  final Map<String, dynamic> args;
  final CallUtils callUtils;
  final void Function(GameAction gameAction) onActionPressed;
  const LudoGamePage(
    this.args,
    this.callUtils,
    this.onActionPressed, {
    super.key,
  }) : super(args, callUtils, onActionPressed);

  @override
  ConsumerState<LudoGamePage> createState() => _LudoGamePageState();
}

class _LudoGamePageState extends BaseGamePageState<LudoGamePage> {
  LudoDetails? prevDetails;
  double gridLength = 0, houseLength = 0, cellSize = 0;
  bool started = false;
  bool sixsix = false;

  List<LudoColor> ludoColors = [
    LudoColor.yellow,
    LudoColor.green,
    LudoColor.red,
    LudoColor.blue
  ];

  LudoTile? selectedLudoTile;
  Ludo? selectedLudo;
  //List<LudoColor> ludoColors = [];
  List<List<Ludo>> ludos = [], activeLudos = [];
  List<List<Ludo>> playersWonLudos = [];
  List<List<LudoTile>> ludoTiles = [];
  List<List<int>> playersHouseIndices = [];
  List<int> diceValues = [0, 0];
  //List<String> ludoIndices = [];

  bool showRollDice = true, roll = false;

  //int myPlayer = 0;

  Map<int, List<int>> hintPositions = {};
  bool hintHouse = false;
  bool hintRollDice = true;
  bool hintEnterHouse = false;
  int myLudoIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    cellSize = (minSize - 2) / 15;
    gridLength = cellSize * 3;
    houseLength = (((minSize - 2) - gridLength) / 2);
  }

  void resetDiceAndSelections() {
    diceValues = [0, 0];
    showRollDice = true;
    showMessage = false;
    selectedLudoTile = null;
    selectedLudo = null;
  }

  void changePlayerIfTimeOut() async {
    resetDiceAndSelections();
    changePlayer();
  }

  void playIfTimeOut() async {
    if (showRollDice) {
      rollDice();
    } else {
      if (diceValues[0] == 0 && diceValues[1] == 0) {
        changePlayerIfTimeOut();

        return;
      }
      if (hintPositions.isNotEmpty) {
        final housePositions = hintPositions.keys.toList();
        final selectedHouse =
            housePositions[Random().nextInt(housePositions.length)];
        final selectedPos = hintPositions[selectedHouse]!.first;
        playLudo(selectedHouse, selectedPos);
        if (hintPositions.isNotEmpty) {
          final housePositions = hintPositions.keys.toList();
          final selectedHouse =
              housePositions[Random().nextInt(housePositions.length)];
          final selectedPos = hintPositions[selectedHouse]!.first;
          playLudo(selectedHouse, selectedPos);
        } else {
          changePlayerIfTimeOut();
        }
      } else {
        final houseIndices = playersHouseIndices[currentPlayer];
        final housesWithLudos =
            houseIndices.where((index) => ludos[index].isNotEmpty).toList();
        if (housesWithLudos.isNotEmpty) {
          final selectedHouse =
              housesWithLudos[Random().nextInt(housesWithLudos.length)];
          final ludoIndices = ludos[selectedHouse];
          final selectedPos = Random().nextInt(ludoIndices.length);
          selectHouseLudo(selectedHouse, selectedPos);
          if (hintPositions.isNotEmpty) {
            final housePositions = hintPositions.keys.toList();
            final selectedHouse =
                housePositions[Random().nextInt(housePositions.length)];
            final selectedPos = hintPositions[selectedHouse]!.first;
            playLudo(selectedHouse, selectedPos);
          } else {
            changePlayerIfTimeOut();
          }
        } else {
          changePlayerIfTimeOut();
        }
      }
    }
  }

  List<Ludo> getLudos() {
    return List.generate(16, (index) {
      final i = index ~/ 4;
      final pos = index % 4;
      return Ludo("$index", -1, -1, -1, pos, i, i);
    });
  }

  void initLudos() {
    setInitialCount(0);

    selectedLudoTile = null;
    selectedLudo = null;
    showMessage = false;
    hintPositions.clear();
    ludoTiles.clear();
    ludos.clear();
    activeLudos.clear();
    playersWonLudos.clear();
    diceValues = [0, 0];
    activeLudos.clear();
    activeLudos = List.generate(playersSize, (index) => []);
    playersWonLudos = List.generate(4, (index) => []);
    List<Ludo> ludoList = getLudos();

    ludos = ludoList.groupListToList((ludo) => ludo.houseIndex);
    for (int i = 0; i < 4; i++) {
      ludoTiles.add(List.generate(18, (index) {
        final grids = convertToGrid(index, 6);
        final x = grids[0];
        final y = grids[1];
        return LudoTile(x, y, "$index", [], i);
      }));
    }

    if (playersSize == 2) {
      playersHouseIndices.add([0, 1]);
      playersHouseIndices.add([2, 3]);
    } else {
      for (int i = 0; i < playersSize; i++) {
        playersHouseIndices.add([i]);
      }
    }
    setState(() {});
  }

  Future updateDiceDetails(int dice1, int dice2) async {
    final details = LudoDetails(
      dice1: dice1,
      dice2: dice2,
    );

    await setDetail(details.toMap());
  }

  void updateEnterHouseDetails() async {
    final details = LudoDetails(
      enteredHouse: true,
      pos: selectedLudoTile!.id.toInt,
      housePos: selectedLudoTile!.houseIndex,
    );

    await setDetail(details.toMap());
  }

  Future updateDetails(
      int playHouseIndex, int playPos, bool selectedFromHouse) async {
    final startDetails = LudoDetails(
      pos: selectedFromHouse
          ? selectedLudo!.housePos
          : selectedLudoTile!.id.toInt,
      housePos: selectedFromHouse
          ? selectedLudo!.houseIndex
          : selectedLudoTile!.houseIndex,
      selectedFromHouse: selectedFromHouse,
    );

    final endDetails = LudoDetails(pos: playPos, housePos: playHouseIndex);

    await setDetails([startDetails.toMap(), endDetails.toMap()]);
  }

  Alignment getAlignment(int index) {
    if (index == 0) return Alignment.topLeft;
    if (index == 1) return Alignment.topRight;
    if (index == 2) return Alignment.bottomRight;
    if (index == 3) return Alignment.bottomLeft;
    return Alignment.topLeft;
  }

  List<int> getHouseIndices(int player) {
    if (playersSize == 2) {
      return player == 0 ? [0, 1] : [2, 3];
    } else {
      return [player];
    }
  }

  int getPlayerFromHouseIndex(int index) {
    return playersSize > 2
        ? index
        : index > 1
            ? 1
            : 0;
  }

  void updateDice(int dice1, int dice2, [bool isClick = true]) async {
    diceValues = [dice1, dice2];

    if (isClick) {
      updateDiceDetails(dice1, dice2);
    }
    showRollDice = false;
    showMessage = true;
    roll = false;
    if (dice1 == 6 || dice2 == 6) {
      sixsix = dice1 == 6 && dice2 == 6;
    }
    changePlayerAfterMoving();
    resetPlayerTime();
    setState(() {});
  }

  void rollDice([bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;

    if (roll) return;
    setState(() {
      roll = true;
    });
  }

  void enterHouse([bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;

    int dice1 = diceValues[0];
    int dice2 = diceValues[1];
    if (selectedLudoTile == null) return;
    final selectedLudo = selectedLudoTile!.ludos.first;
    int stepCount = 0;
    int totalStepCount = 56 - selectedLudo.step;
    //int totalStepCount = 6 - selX;
    if ((totalStepCount == dice1 ||
        totalStepCount == dice2 ||
        totalStepCount == (dice1 + dice2))) {
      if (totalStepCount == dice1) {
        stepCount = dice1;
      } else if (totalStepCount == dice2) {
        stepCount = dice2;
      } else if (totalStepCount == (dice1 + dice2)) {
        stepCount = dice1 + dice2;
      }
      if (stepCount == dice1) {
        dice1 = 0;
      } else if (stepCount == dice2) {
        dice2 = 0;
      } else if (stepCount == (dice1 + dice2)) {
        dice2 = 0;
        dice1 = 0;
      }
      selectedLudo.step += stepCount;
      selectedLudo.currentHouseIndex = selectedLudo.houseIndex;
      selectedLudo.x = -1;
      selectedLudo.y = -1;
      diceValues = [dice1, dice2];
      activeLudos[currentPlayer]
          .removeWhere((element) => element.id == selectedLudo.id);
      playersWonLudos[selectedLudo.houseIndex].add(selectedLudo);
      incrementCount(currentPlayer);

      if (isClick) {
        updateEnterHouseDetails();
      }

      hintEnterHouse = false;
      selectedLudoTile!.ludos.removeAt(0);
      selectedLudoTile = null;
      showPlayerToast(currentPlayer, "Entered House");
      checkWinGame();
      changePlayerAfterMoving();
      // if (diceValues[0] != 0 && diceValues[1] != 0) {
      //   showPossiblePlayPositions();
      // }
      setState(() {});
    } else {
      showPlayerToast(currentPlayer,
          "You can't enter house yet. you need $totalStepCount more steps to enter");
    }
  }

  void selectHouseLudo(int houseIndex, int index, [bool isClick = true]) {
    if (awaiting) return;
    int player = getPlayerFromHouseIndex(houseIndex);

    if (!itsMyTurnToPlay(isClick, player)) return;

    if (isClick && showRollDice) {
      showPlayerToast(currentPlayer, "Tap to roll dice first");
      return;
    }

    if (isClick && diceValues[0] != 6 && diceValues[1] != 6) return;

    if (player != currentPlayer && selectedLudo == null) {
      final houses = playersHouseIndices[currentPlayer];
      List<String> playerColors = [];
      for (int i = 0; i < houses.length; i++) {
        final house = houses[i];
        final color = ludoColors[house];
        playerColors.add(color.name);
      }
      showPlayerToast(currentPlayer,
          "This is not your ludo. Your ludo ${playerColors.length == 1 ? "color is ${playerColors.first}" : "colors are ${playerColors.first} and ${playerColors.second}"} ");
      return;
    }
    index = ludos[houseIndex].indexWhere((ludo) => index == ludo.housePos);
    final ludo = ludos[houseIndex][index];
    if (selectedLudoTile != null) selectedLudoTile = null;
    if (selectedLudo != null && selectedLudo == ludo) {
      selectedLudo = null;
      hintPositions.clear();
      showPossiblePlayPositions();
    } else {
      selectedLudo = ludo;
      getHintPositions(houseIndex, index);
    }
    setState(() {});
  }

  List<int> getHighestPosition(int houseIndex) {
    if (hintPositions[houseIndex] == null) {
      houseIndex = nextLudoHouseIndex(houseIndex);
    }
    while (hintPositions[houseIndex] != null) {
      houseIndex = nextLudoHouseIndex(houseIndex);
    }
    // final largestHouseIndex =
    //     hintPositions.keys.toList().sortedList((val) => val, false).last;
    // final largestPos =
    //     hintPositions[largestHouseIndex]!.sortedList((val) => val, false).last;
    // for(final entry in hintPositions.entries){
    //   final houseIndex = entry.key;
    //   final positions = entry.value;
    //   for(int i = 0; i < positions.length; i++){
    //     final pos = positions[i];
    //     f

    //   }
    // }
    return [houseIndex, hintPositions[houseIndex]!.last];
  }

  void getHintPositions(int houseIndex, int pos) {
    //if (!firstTime) return;
    hintPositions.clear();
    final coordinates = convertToGrid(pos, 6);
    final x = coordinates[0];
    final y = coordinates[1];
    int dice1 = diceValues[0];
    int dice2 = diceValues[1];
    //hintHouse = dice1 == 6 || dice2 == 6;

    final selectedLudo = this.selectedLudo != null
        ? null
        : ludoTiles[houseIndex][pos].ludos.first;

    if (this.selectedLudo != null) {
      final secondDice = dice1 == 6 ? dice2 : dice1;
      if (hintPositions[houseIndex] != null) {
        hintPositions[houseIndex]!.add(1);
      } else {
        hintPositions[houseIndex] = [1];
      }
      if (secondDice != 0) {
        if (secondDice > 4) {
          final remainder = secondDice - 4;
          final newPos = 18 - remainder;
          int nextHouse = nextLudoHouseIndex(houseIndex);
          if (hintPositions[nextHouse] != null) {
            hintPositions[nextHouse]!.add(newPos);
          } else {
            hintPositions[nextHouse] = [newPos];
          }
        } else {
          final newPos = secondDice + 1;
          if (hintPositions[houseIndex] != null) {
            hintPositions[houseIndex]!.add(newPos);
          } else {
            hintPositions[houseIndex] = [newPos];
          }
        }
      }
    } else {
      List<int> stepCounts = [];
      int totalSteps = dice1 + dice2;
      if (dice1 != 0) {
        stepCounts.add(dice1);
      }
      if (dice2 != 0) {
        stepCounts.add(dice2);
      }
      if (totalSteps != dice1 && totalSteps != dice2) {
        stepCounts.add(totalSteps);
      }
      for (int i = 0; i < stepCounts.length; i++) {
        final stepCount = stepCounts[i];
        int ludoStep = selectedLudo!.step;
        if (!hintEnterHouse && ludoStep + stepCount == 56) {
          hintEnterHouse = true;
        }
        final selCount = y == 0
            ? 5 - x
            : y == 1 && ludoStep >= 50
                ? 6 - x
                : (x + 5 + y);
        if (stepCount > selCount) {
          final remainder = stepCount - selCount;
          final nextHouse = nextLudoHouseIndex(houseIndex);
          if (selectedLudoTile != null &&
              selectedLudoTile!.houseIndex == selectedLudo.houseIndex &&
              selectedLudo.step >= 44) return;
          final newPos =
              getStepPosition(5, 2, remainder - 1, (ludoStep + stepCount) > 43);
          if (newPos != -1) {
            if (hintPositions[nextHouse] != null) {
              hintPositions[nextHouse]!.add(newPos);
            } else {
              hintPositions[nextHouse] = [newPos];
            }
          }
        } else {
          final newPos = getStepPosition(x, y, stepCount, ludoStep > 43);
          if (newPos != -1) {
            if (hintPositions[houseIndex] != null) {
              hintPositions[houseIndex]!.add(newPos);
            } else {
              hintPositions[houseIndex] = [newPos];
            }
          }
        }
      }
    }
    //getHintMessage();
    setState(() {});
  }

  int getStepPosition(int x, int y, int step, [bool enteringHouse = false]) {
    int newX = x;
    int newY = y;
    int newStep = step;

    if (y == 2) {
      if (newX - newStep >= 0) {
        newX -= newStep;
      } else {
        newStep = newStep - newX;
        newStep -= 1;
        newX = 0;
        newY = 1;
        if (newStep > 0) {
          if (!enteringHouse) {
            newStep -= 1;
            newY = 0;
          }
          if (newStep > 0) {
            if (newX + newStep > 5) {
              newX = 5;
              return -1;
            } else {
              newX += newStep;
              newStep = newStep - newX;
            }
          }
        }
      }
    } else {
      if (!enteringHouse && y == 1) {
        newStep -= 1;
        newY = 0;
      }
      if (newStep > 0) {
        if (newX + newStep > 5) {
          newX = 5;
          return -1;
        } else {
          newX += newStep;
        }
      }
    }
    return convertToPosition([newX, newY], 6);
  }

  void getHintMessage() {
    if (!firstTime) return;
    if (showRollDice) {
      hintMessage = "Tap to roll dice";
    } else {
      final hasSix = diceValues[0] == 6 || diceValues[1] == 6;
      if (hasSix) {
        hintMessage =
            "Tap on any ludo in house to bring out or play any active ludo";
      } else {
        hintMessage = "Tap on your ludo and count the dice step";
      }
    }

    message = hintMessage;
    setState(() {});
  }

  void showPossiblePlayPositions() {
    //if (!firstTime) return;
    hintPositions.clear();
    if (showRollDice) return;
    final playerLudos = activeLudos[currentPlayer];
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    hintHouse = dice1 == 6 || dice2 == 6;
    if (playerLudos.isNotEmpty) {
      for (int i = 0; i < playerLudos.length; i++) {
        final ludo = playerLudos[i];
        if ((dice1 != 0 && ludo.step + dice1 <= 56) ||
            (dice2 != 0 && ludo.step + dice2 <= 56)) {
          int pos = convertToPosition([ludo.x, ludo.y], 6);
          if (hintPositions[ludo.currentHouseIndex] != null) {
            hintPositions[ludo.currentHouseIndex]!.add(pos);
          } else {
            hintPositions[ludo.currentHouseIndex] = [pos];
          }
        }
      }
    }
    getHintMessage();
    setState(() {});
  }

  void switchLudo(int index, int pos) {
    LudoTile ludoTile = ludoTiles[index][pos];
    if (ludoTile.ludos.length < 2) {
      return;
    }
    int player = getPlayerFromHouseIndex(ludoTile.ludos.first.houseIndex);
    if (player != currentPlayer) {
      showPlayerToast(player,
          "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
      return;
    }
    final lastLudo = ludoTile.ludos.last;
    ludoTile.ludos[ludoTile.ludos.length - 1] =
        ludoTile.ludos[ludoTile.ludos.length - 2];
    ludoTile.ludos[ludoTile.ludos.length - 2] = lastLudo;
    showPlayerToast(currentPlayer, "Ludo switched");
    setState(() {});
  }

  void playLudo(int index, int pos, [bool isClick = true]) {
    if (!itsMyTurnToPlay(isClick)) return;

    LudoTile ludoTile = ludoTiles[index][pos];
    if (selectedLudoTile != null && selectedLudoTile == ludoTile) {
      selectedLudoTile = null;
      if (selectedLudo != null) selectedLudo = null;
      hintPositions.clear();
      showPossiblePlayPositions();
      setState(() {});
      return;
    }
    if (ludoTile.ludos.isNotEmpty) {
      int player = getPlayerFromHouseIndex(ludoTile.ludos.first.houseIndex);
      if (player != currentPlayer &&
          selectedLudoTile == null &&
          selectedLudo == null &&
          isClick) {
        final houses = playersHouseIndices[currentPlayer];
        List<String> playerColors = [];
        for (int i = 0; i < houses.length; i++) {
          final house = houses[i];
          final color = ludoColors[house];
          playerColors.add(color.name);
        }
        showPlayerToast(currentPlayer,
            "This is not your ludo. Your ludo ${playerColors.length == 1 ? "color is ${playerColors.first}" : "colors are ${playerColors.first} and ${playerColors.second}"} ");
        return;
      }
      if (showRollDice && player == currentPlayer) {
        showPlayerToast(currentPlayer, "Tap to roll dice first");
        return;
      }

      if (selectedLudoTile != null || selectedLudo != null) {
        moveLudo(ludoTile, index, pos, isClick);
        // if (selectedLudo != null) selectedLudo = null;
        // if (selectedLudoTile != null) selectedLudoTile = null;
      } else {
        selectedLudoTile = ludoTile;
        if (selectedLudo != null) selectedLudo = null;
        getHintPositions(index, pos);
        setState(() {});
      }
      //selectedLudo = null;
    } else {
      if (selectedLudoTile != null || selectedLudo != null) {
        moveLudo(ludoTile, index, pos, isClick);
      }
    }
  }

  bool canCapture(Ludo ludo, int stepCount) {
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    if (stepCount == (dice1 + dice2)) return true;
    if ((dice1 == 6 && dice2 == stepCount) ||
        (dice2 == 6 && dice1 == stepCount)) return true;
    if (dice1 == 0 || dice2 == 0) return true;
    if (activeLudos.isEmpty) return stepCount > 0;
    final playerLudos = activeLudos[currentPlayer]
        .where((element) => element.id != ludo.id)
        .toList();
    if (playerLudos.isEmpty) return false;
    final ludoStep = dice1 == stepCount ? dice2 : dice1;
    if (ludoStep == 6 && hasPlayerInHouse()) return true;
    final playableLudos = playerLudos
        .where((element) => (element.step + ludoStep) <= 56)
        .toList();
    if (playableLudos.isNotEmpty) {
      return true;
    }
    return false;
    //return (ludo.step + dice1 + dice2) > 56;
  }

  void moveLudo(LudoTile ludoTile, int houseIndex, int pos,
      [bool isClick = true]) async {
    // if (hintEnterHouse) {
    //   showPlayerToast(currentPlayer,
    //       "You are meant to enter your house now. Tap on the center");
    //   return;
    // }
    if (hintPositions[houseIndex] == null ||
        !hintPositions[houseIndex]!.contains(pos)) {
      changeSelectionIfAnother(ludoTile, pos);
      return;
    }
    int dice1 = diceValues[0];
    int dice2 = diceValues[1];

    int totalStepCount = 0;
    int stepCount = -1;

    final coordinates = convertToGrid(pos, 6);
    final x = coordinates[0];
    final y = coordinates[1];
    final selectedLudo = this.selectedLudo ?? selectedLudoTile!.ludos.first;
    final selectedHouseIndex =
        this.selectedLudo?.houseIndex ?? selectedLudoTile!.houseIndex;
    final selectedPos =
        this.selectedLudo != null ? 1 : int.parse(selectedLudoTile!.id);
    final prevCoordinates = convertToGrid(selectedPos, 6);
    final selX = prevCoordinates[0];
    final selY = prevCoordinates[1];

    final nextHouse = nextLudoHouseIndex(selectedHouseIndex);
    if (houseIndex == selectedHouseIndex) {
      final xDiff = (x - selX).abs();
      final yDiff = (y - selY).abs();
      final count = selY == y ? xDiff : (selX + x + yDiff);
      totalStepCount = count;
    } else if (houseIndex == nextHouse) {
      final selCount = selY == 0
          ? 5 - selX
          : selY == 1 && selectedLudo.step >= 50
              ? 6 - selX
              : (selX + 5 + selY);
      totalStepCount += selCount;
      final houseCount = y == 2 ? 6 - x : (x + 6 + (2 - y));
      totalStepCount += houseCount;
    }
    if (this.selectedLudo != null) {
      if (dice1 == 6) {
        dice1 = 0;
      } else if (dice2 == 6) {
        dice2 = 0;
      }
    }

    if (totalStepCount == 0) {
      stepCount = 0;
    } else if (dice1 != 0 && dice2 != 0 && totalStepCount == (dice1 + dice2)) {
      stepCount = dice1 + dice2;
      dice1 = 0;
      dice2 = 0;
    } else if (dice1 != 0 && totalStepCount == dice1) {
      stepCount = dice1;
      dice1 = 0;
    } else if (dice2 != 0 && totalStepCount == dice2) {
      stepCount = dice2;
      dice2 = 0;
    }
    if (stepCount != -1) {
      if (ludoTile.ludos.isNotEmpty &&
          getPlayerFromHouseIndex(selectedLudo.houseIndex) !=
              getPlayerFromHouseIndex(ludoTile.ludos.first.houseIndex)) {
        if (!canCapture(selectedLudo, totalStepCount)) {
          showPlayerToast(currentPlayer,
              "You have to play your total dice at once since you can't play another");
          return;
        }

        if (selectedLudo.step == -1) {
          selectedLudo.step = 0;
        }
        final ludo = ludoTile.ludos.first;
        ludo.step = -1;
        ludo.x = -1;
        ludo.y = -1;
        ludo.currentHouseIndex = ludo.houseIndex;
        ludos[ludo.houseIndex].add(ludo);
        ludoTile.ludos.removeAt(0);
        activeLudos[getPlayerFromHouseIndex(ludo.houseIndex)]
            .removeWhere((element) => element.id == ludo.id);

        selectedLudo.step = 56;
        selectedLudo.x = -1;
        selectedLudo.y = -1;
        selectedLudo.currentHouseIndex = selectedLudo.houseIndex;

        activeLudos[currentPlayer]
            .removeWhere((element) => element.id == selectedLudo.id);
        playersWonLudos[selectedLudo.houseIndex].add(selectedLudo);
        incrementCount(currentPlayer);
      } else {
        if (selectedLudo.step == -1) {
          selectedLudo.step = 0;
        }
        selectedLudo.step += stepCount;
        selectedLudo.currentHouseIndex = ludoTile.houseIndex;
        selectedLudo.x = ludoTile.x;
        selectedLudo.y = ludoTile.y;

        ludoTile.ludos.insert(0, selectedLudo);
        if (this.selectedLudo != null) {
          activeLudos[currentPlayer].add(selectedLudo);
        }
      }
      if (isClick) {
        updateDetails(houseIndex, pos, this.selectedLudo != null);
      }

      if (this.selectedLudo != null) {
        ludos[this.selectedLudo!.houseIndex]
            .removeWhere((element) => element.id == selectedLudo.id);
        this.selectedLudo = null;
        if (selectedLudoTile != null) selectedLudoTile = null;
      } else {
        selectedLudoTile!.ludos.removeAt(0);
        selectedLudoTile = null;
        if (this.selectedLudo != null) this.selectedLudo = null;
      }

      diceValues = [dice1, dice2];
      hintPositions.clear();
      checkWinGame();
      changePlayerAfterMoving();
      setState(() {});
    }
  }

  // void moveLudo(LudoTile ludoTile, int houseIndex, int pos,
  //     [bool isClick = true]) async {
  //   int dice1 = diceValues[0];
  //   int dice2 = diceValues[1];
  //   if (this.selectedLudo != null) {
  //     if (this.selectedLudo!.houseIndex != houseIndex &&
  //         houseIndex != prevIndex(4, this.selectedLudo!.houseIndex) &&
  //         (pos < 16)) {
  //       //checking if it is selected from and placed in the right the right house
  //       changeSelectionIfAnother(ludoTile, pos);
  //       return;
  //     }
  //     if (dice1 == 6) {
  //       dice1 = 0;
  //     } else if (dice2 == 6) {
  //       dice2 = 0;
  //     }
  //   }
  //   int totalStepCount = 0;
  //   final coordinates = convertToGrid(pos, 6);
  //   final x = coordinates[0];
  //   final y = coordinates[1];
  //   final selectedLudo = this.selectedLudo ?? selectedLudoTile!.ludos.first;
  //   final selectedHouseIndex =
  //       this.selectedLudo?.houseIndex ?? selectedLudoTile!.houseIndex;
  //   final selectedPos =
  //       this.selectedLudo != null ? 1 : int.parse(selectedLudoTile!.id);
  //   final prevCoordinates = convertToGrid(selectedPos, 6);
  //   final selX = prevCoordinates[0];
  //   final selY = prevCoordinates[1];
  //   if (y == 0 &&
  //       x == 0 &&
  //       houseIndex == selectedLudo.houseIndex &&
  //       selectedLudo.step == -1) {
  //     //checking if coming out and not starting from the first position
  //     changeSelectionIfAnother(ludoTile, pos);
  //     return;
  //   }
  //   if (y == 1 && x != 0 && houseIndex != selectedLudo.houseIndex) {
  //     //making sure that the ludo is not going to the wrong path and about to enter the house
  //     changeSelectionIfAnother(ludoTile, pos);
  //     return;
  //   }
  //   bool isBackMove = false;
  //   if (selectedHouseIndex == houseIndex) {
  //     if (y == selY) {
  //       isBackMove = (selY < 2 && x < selX) || (selY == 2 && x > selX);
  //     } else {
  //       isBackMove =
  //           (selY == 1 && selectedLudo.step >= 50 && (y == 0 || y == 2)) ||
  //               y > selY;
  //     }

  //     final xDiff = (x - selX).abs();
  //     final yDiff = (y - selY).abs();
  //     final count = selY == y ? xDiff : (selX + x + yDiff);
  //     totalStepCount += count;
  //   } else {
  //     final prevHouse = prevLudoHouseIndex(selectedHouseIndex);
  //     if (prevHouse == houseIndex ||
  //         prevLudoHouseIndex(prevHouse) == houseIndex) {
  //       //check for backward movement
  //       changeSelectionIfAnother(ludoTile, pos);
  //       return;
  //     }
  //     final nextHouse = nextLudoHouseIndex(selectedHouseIndex);
  //     if (houseIndex == nextHouse) {
  //       if (selectedHouseIndex == selectedLudo.houseIndex &&
  //           selectedLudo.step >= 44) {
  //         //checking for maximum length of possible next house movement
  //         changeSelectionIfAnother(ludoTile, pos);
  //         return;
  //       }
  //       final selCount = selY == 0
  //           ? 5 - selX
  //           : selY == 1 && selectedLudo.step >= 50
  //               ? 6 - selX
  //               : (selX + 5 + selY);
  //       totalStepCount += selCount;
  //       final houseCount = y == 2 ? 6 - x : (x + 6 + (2 - y));
  //       totalStepCount += houseCount;
  //     }
  //   }

  //   int stepCount = 0;
  //   if (!isBackMove &&
  //       (totalStepCount > 0 ||
  //           (totalStepCount == 0 && this.selectedLudo != null)) &&
  //       (totalStepCount == dice1 ||
  //           totalStepCount == dice2 ||
  //           totalStepCount == (dice1 + dice2))) {
  //     final step = selectedLudo.step;
  //     if (totalStepCount == dice1) {
  //       stepCount = dice1;
  //     } else if (totalStepCount == dice2) {
  //       stepCount = dice2;
  //     } else if (totalStepCount == (dice1 + dice2)) {
  //       stepCount = dice1 + dice2;
  //     }
  //     final finalStep = step + stepCount;
  //     if (selectedLudo.houseIndex == houseIndex &&
  //         ((finalStep >= 50 && finalStep <= 55 && y != 1) ||
  //             (finalStep >= 44 && finalStep <= 49 && y != 2) ||
  //             (finalStep >= 1 && finalStep <= 5 && y != 0))) {
  //       String msg = "";
  //       if (finalStep >= 50 && finalStep <= 55 && y != 1) {
  //         msg =
  //             "You are meant to enter your house now. Go through the center path";
  //       } else if (finalStep >= 44 && finalStep <= 49 && y != 2) {
  //         msg = "you are on the wrong path";
  //       } else if (finalStep >= 1 && finalStep <= 5 && y != 0) {
  //         msg = "You shoud follow the arrow path to start";
  //       }
  //       showPlayerToast(currentPlayer, msg);

  //       return;
  //     }

  //     if (ludoTile.ludos.isNotEmpty &&
  //         getPlayerFromHouseIndex(selectedLudo.houseIndex) !=
  //             getPlayerFromHouseIndex(ludoTile.ludos.first.houseIndex)) {
  //       if (!canCapture(selectedLudo, totalStepCount)) {
  //         showPlayerToast(currentPlayer,
  //             "You have to play your total dice at once since you can't play another");
  //         return;
  //       }
  //       if (isClick) {
  //         updatePlayPos(houseIndex, pos);
  //       }

  //       if (selectedLudo.step == -1 && this.selectedLudo != null) {
  //         selectedLudo.step = 0;
  //       }
  //       final ludo = ludoTile.ludos.first;
  //       ludo.step = -1;
  //       ludo.x = -1;
  //       ludo.y = -1;
  //       ludo.currentHouseIndex = ludo.houseIndex;
  //       ludos[ludo.houseIndex].add(ludo);
  //       ludoTile.ludos.removeAt(0);
  //       activeLudos[getPlayerFromHouseIndex(ludo.houseIndex)]
  //           .removeWhere((element) => element.id == ludo.id);

  //       selectedLudo.step = 56;
  //       selectedLudo.x = -1;
  //       selectedLudo.y = -1;
  //       selectedLudo.currentHouseIndex = selectedLudo.houseIndex;

  //       activeLudos[currentPlayer]
  //           .removeWhere((element) => element.id == selectedLudo.id);
  //       playersWonLudos[selectedLudo.houseIndex].add(selectedLudo);
  //     } else {
  //       if (isClick) {
  //         updatePlayPos(houseIndex, pos);
  //       }

  //       if (selectedLudo.step == -1 && this.selectedLudo != null) {
  //         selectedLudo.step = 0;
  //       }
  //       selectedLudo.step += stepCount;
  //       selectedLudo.currentHouseIndex = ludoTile.houseIndex;
  //       selectedLudo.x = ludoTile.x;
  //       selectedLudo.y = ludoTile.y;

  //       ludoTile.ludos.insert(0, selectedLudo);
  //       if (this.selectedLudo != null) {
  //         activeLudos[currentPlayer].add(selectedLudo);
  //       }
  //     }

  //     if (this.selectedLudo != null) {
  //       ludos[this.selectedLudo!.houseIndex]
  //           .removeWhere((element) => element.id == selectedLudo.id);
  //       this.selectedLudo = null;
  //     } else {
  //       selectedLudoTile!.ludos.removeAt(0);
  //     }

  //     if (stepCount == dice1) {
  //       dice1 = 0;
  //     } else if (stepCount == dice2) {
  //       dice2 = 0;
  //     } else if (stepCount == (dice1 + dice2)) {
  //       dice2 = 0;
  //       dice1 = 0;
  //     }
  //     diceValues = [dice1, dice2];
  //     selectedLudoTile = null;
  //     hintPositions.clear();
  //     checkWinGame();
  //     changePlayerAfterMoving();
  //     setState(() {});
  //   } else {
  //     changeSelectionIfAnother(ludoTile, pos);
  //     //Fluttertoast.showPlayerToast(msg: "Invalid Position. Recount");
  //   }
  // }

  void changeSelectionIfAnother(LudoTile ludoTile, int pos) {
    if (ludoTile.ludos.isNotEmpty) {
      int player = getPlayerFromHouseIndex(ludoTile.ludos.first.houseIndex);
      if (player != currentPlayer) {
        showPlayerToast(player,
            "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
        return;
      }
      selectedLudoTile = ludoTile;
      getHintPositions(ludoTile.houseIndex, pos);
      setState(() {});
    }
  }

  void resetIfCantEnterHouse() {
    final playerLudos = activeLudos[currentPlayer];
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    final hasSix = dice1 == 6 || dice2 == 6;
    if (dice1 == 0 && dice2 == 0) {
      showRollDice = true;
      showMessage = false;
      return;
    }
    if (playerLudos.isEmpty && (!hasSix || !hasPlayerInHouse())) {
      //diceValues = [0, 0];
      showRollDice = true;
      showMessage = false;
      return;
    }
    final ludosEnteringHouse =
        playerLudos.where((element) => element.step > 50).toList();
    if (ludosEnteringHouse.isNotEmpty &&
        ludosEnteringHouse.length == playerLudos.length) {
      int count = 0;
      for (int i = 0; i < ludosEnteringHouse.length; i++) {
        final ludo = ludosEnteringHouse[i];
        final value = dice1 == 0
            ? dice2
            : dice2 == 0
                ? dice1
                : dice1 < dice2
                    ? dice1
                    : dice2;
        if ((ludo.step + value) <= 56) {
          count++;
        }
      }
      if (count == 0 && (!hasSix || !hasPlayerInHouse())) {
        //diceValues = [0, 0];
        showRollDice = true;
        showMessage = false;
      }
    }
  }

  bool hasPlayerInHouse() {
    final houseIndices = playersHouseIndices[currentPlayer];
    int ludosCount = 0;
    for (int i = 0; i < houseIndices.length; i++) {
      final houseIndex = houseIndices[i];
      final playerHouseLudos = ludos[houseIndex];
      ludosCount += playerHouseLudos.length;
    }
    return ludosCount > 0;
  }

  void changePlayerAfterMoving() {
    hintHouse = false;
    hintEnterHouse = false;
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    resetPlayerTime();
    resetIfCantEnterHouse();
    if (showRollDice) {
      if (sixsix) {
        sixsix = false;
      } else {
        changePlayer();
      }
      setState(() {});
    } else {
      if (dice1 != 0 && dice2 != 0) {
        showPossiblePlayPositions();
      }
    }

    if (diceValues[0] != 0 || diceValues[1] != 0) {
      if (selectedLudoTile == null) {
        showPossiblePlayPositions();
      }
    }
  }

  void checkWinGame() async {
    final houseIndices = playersHouseIndices[currentPlayer];
    int ludosCount = 0;
    for (int i = 0; i < houseIndices.length; i++) {
      final houseIndex = houseIndices[i];
      final playerLudos = ludos[houseIndex];
      ludosCount += playerLudos.length;
    }
    if (ludosCount == 0 && activeLudos[currentPlayer].isEmpty) {
      updateWin(currentPlayer);
    }
  }

  int prevLudoHouseIndex(int selectedHouseIndex) {
    return selectedHouseIndex == 0 ? 3 : selectedHouseIndex - 1;
  }

  int nextLudoHouseIndex(int selectedHouseIndex) {
    return selectedHouseIndex == 3 ? 0 : selectedHouseIndex + 1;
  }

  Color convertToColor(LudoColor color) {
    if (color == LudoColor.blue) return Colors.blue;
    if (color == LudoColor.red) return Colors.red;
    if (color == LudoColor.yellow) return const Color(0xffF6BE00);
    if (color == LudoColor.green) return Colors.green;
    return const Color(0xffF6BE00);
  }

  @override
  int? maxGameTime;

  @override
  int? maxPlayerTime;
  @override
  void onConcede(int index) {
    resetDiceAndSelections();
  }

  @override
  Future onDetailsChange(Map<String, dynamic>? map) async {
    if (map != null) {
      final details = LudoDetails.fromMap(map);

      final pos = details.pos;
      final housePos = details.housePos;

      final selectedFromHouse = details.selectedFromHouse;
      final enteredHouse = details.enteredHouse;

      final dice1 = details.dice1;
      final dice2 = details.dice2;

      if (dice1 != null && dice2 != null) {
        updateDice(dice1, dice2, false);
      }
      if (pos != null && housePos != null) {
        if (selectedFromHouse == true) {
          selectHouseLudo(housePos, pos, false);
        } else {
          playLudo(housePos, pos, false);
        }
      }

      if (enteredHouse == true) {
        enterHouse(false);
      }

      // final startPos = details.startPos;
      // final endPos = details.endPos;
      // final startPosHouse = details.startPosHouse;
      // final endPosHouse = details.endPosHouse;

      // final selectedFromHouse = details.selectedFromHouse;
      // final enteredHouse = details.enteredHouse;

      // final dice1 = details.dice1;
      // final dice2 = details.dice2;

      // if (dice1 != null && dice2 != null) {
      //   updateDice(dice1, dice2, false);
      // }

      // if (startPos != null &&
      //     startPosHouse != null &&
      //     selectedFromHouse != null) {
      //   if (selectedFromHouse) {
      //     selectHouseLudo(startPosHouse, startPos, false);
      //   } else {
      //     playLudo(startPosHouse, startPos, false);
      //   }
      // }
      // if (endPos != null && endPosHouse != null) {
      //   if (!await allowNextMove) return;

      //   playLudo(endPosHouse, endPos, false);
      // }
      // if (enteredHouse == true) {
      //   enterHouse(false);
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
    resetDiceAndSelections();
  }

  @override
  void onPause() {
    // TODO: implement onPause
  }

  @override
  void onSpaceBarPressed() {
    if (!paused && showRollDice) {
      rollDice();
    }
  }

  @override
  void onInit() {}

  @override
  void onResume() {
    // TODO: implement onResume
  }

  @override
  void onStart() {
    initLudos();
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
  void onPlayerChange(int player) {
    hintPositions.clear();
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    // print("gameDetails = $gameDetails");
    if (!showRollDice || roll || index != currentPlayer) return Container();
    return StreamBuilder<int>(
        stream: timerController.stream,
        builder: (context, snapshot) {
          return RollDiceButton(
            blink: firstTime && hintRollDice && showRollDice,
            playerTime: playerTime,
            onPressed: rollDice,
          );
        });
  }

  @override
  Widget buildBody(BuildContext context) {
    // print("gameDetails = $gameDetails");
    return Center(
      child: AspectRatio(
          aspectRatio: 1 / 1,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
                border: Border.all(
                    color: darkMode ? Colors.white : Colors.black, width: 1)),
            child: Stack(
              children: List.generate(5, (index) {
                if (index == 4) {
                  return Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        enterHouse();
                      },
                      child: BlinkingBorderContainer(
                        blink: hintEnterHouse,
                        width: gridLength,
                        height: gridLength,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: darkMode ? Colors.white : Colors.black,
                                width: 1)),
                        child: roll
                            ? RollingDice(
                                onStart: () {},
                                onUpdate: (dice1, dice2) {},
                                onComplete: (dice1, dice2) {
                                  updateDice(dice1, dice2);
                                },
                                size: gridLength ~/ 4,
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  diceValues.isEmpty || diceValues[0] == 0
                                      ? Container()
                                      : Dice(
                                          value: diceValues[0],
                                          size: gridLength ~/ 4,
                                        ),
                                  diceValues.isEmpty ||
                                          (diceValues[0] == 0 &&
                                              diceValues[1] == 0)
                                      ? Container()
                                      : const SizedBox(
                                          width: 8,
                                        ),
                                  diceValues.isEmpty || diceValues[1] == 0
                                      ? Container()
                                      : Dice(
                                          value: diceValues[1],
                                          size: gridLength ~/ 4,
                                        ),
                                ],
                              ),
                      ),
                    ),
                  );
                } else {
                  return Align(
                    alignment: getAlignment(index),
                    child: SizedBox(
                      child: RotatedBox(
                        quarterTurns: index,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: houseLength,
                              width: houseLength,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: darkMode
                                          ? Colors.white
                                          : Colors.black,
                                      width: 1),
                                  color: convertToColor(ludoColors[index])),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: houseLength,
                                    height: houseLength,
                                    child: GridView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2),
                                      children: List.generate(4,
                                          // playersWonLudos[index].length,
                                          (lindex) {
                                        return Container(
                                          key: Key(lindex.toString()),
                                          width: houseLength / 2,
                                          height: houseLength / 2,
                                          margin: const EdgeInsets.all(8),
                                          alignment: lindex == 0
                                              ? Alignment.topLeft
                                              : lindex == 1
                                                  ? Alignment.topRight
                                                  : lindex == 2
                                                      ? Alignment.bottomLeft
                                                      : Alignment.bottomRight,
                                          child: playersWonLudos.isNotEmpty &&
                                                  lindex <
                                                      playersWonLudos[index]
                                                          .length
                                              ? LudoDisc(
                                                  size:
                                                      cellSize.percentValue(60),
                                                  color: convertToColor(
                                                      ludoColors[index]))
                                              : null,
                                        );
                                      }),
                                    ),
                                  ),
                                  Container(
                                    width: gridLength,
                                    height: gridLength,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: tint, width: 2),
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(
                                            gridLength / 2)
                                        // color:
                                        //     convertToColor(ludoColors[index]),
                                        ),
                                    child: GridView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2),
                                      children: List.generate(4,
                                          //ludos[index].length,
                                          (lindex) {
                                        final ludoIndex = ludos
                                                .get(index)
                                                ?.indexWhere((ludo) =>
                                                    lindex == ludo.housePos) ??
                                            -1;
                                        if (ludoIndex == -1) {
                                          return SizedBox(
                                            width: cellSize,
                                            height: cellSize,
                                          );
                                        }

                                        final ludo = ludos[index][ludoIndex];

                                        return GestureDetector(
                                          key: Key(ludo.id),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            selectHouseLudo(index, lindex);
                                          },
                                          child: BlinkingBorderContainer(
                                            blink: firstTime &&
                                                hintHouse &&
                                                playersHouseIndices[
                                                        currentPlayer]
                                                    .contains(index),
                                            width: cellSize,
                                            height: cellSize,
                                            decoration: BoxDecoration(
                                              color: selectedLudo == ludo
                                                  ? primaryColor
                                                  : null,
                                              shape: BoxShape.circle,
                                              // borderRadius:
                                              //     BorderRadius.circular(
                                              //         cellSize / 2),
                                            ),
                                            alignment: Alignment.center,
                                            child: LudoDisc(
                                                size: cellSize.percentValue(60),
                                                color: convertToColor(
                                                    ludoColors[index])),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                    width: houseLength,
                                    height: gridLength,
                                    child: Column(
                                      children: List.generate(3, (colindex) {
                                        return Expanded(
                                          key: ValueKey(colindex),
                                          child: Row(
                                            children:
                                                List.generate(6, (rowindex) {
                                              final lindex = convertToPosition(
                                                  [rowindex, colindex], 6);
                                              final ludoTile = ludoTiles
                                                  .get(index)
                                                  ?.get(lindex);
                                              return LudoTileWidget(
                                                blink: hintPositions
                                                        .containsKey(index) &&
                                                    hintPositions[index]!
                                                        .contains(lindex),
                                                key: Key(
                                                    ludoTile?.id ?? "$lindex"),
                                                ludoTile: ludoTile,
                                                colors: ludoColors,
                                                size: cellSize,
                                                pos: lindex,
                                                highLight: selectedLudoTile ==
                                                    ludoTile,
                                                onDoubleTap: () {},
                                                onPressed: () {
                                                  playLudo(index, lindex);
                                                },
                                                color: ludoColors[index],
                                              );
                                            }),
                                          ),
                                        );
                                      }),
                                    )),
                                CustomPaint(
                                    size: Size(
                                        ((minSize - 2) / 2) - houseLength,
                                        gridLength),
                                    painter: LudoTrianglePainter(
                                        color:
                                            convertToColor(ludoColors[index]))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }),
            ),
          )),
    );
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
