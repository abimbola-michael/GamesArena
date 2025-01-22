// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/pages/base_game_page.dart';

import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/card/whot/models/whot.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../shared/extensions/special_context_extensions.dart';
import '../../../../../shared/utils/call_utils.dart';
import '../../../../../shared/widgets/custom_grid.dart';
import '../../../../../theme/colors.dart';
import '../../../../game/models/game_action.dart';
import '../widgets/whot_card.dart';
import '../../../../../enums/emums.dart';

List<WhotCardShape> whotCardShapes = [
  WhotCardShape.circle,
  WhotCardShape.triangle,
  WhotCardShape.cross,
  WhotCardShape.square,
  WhotCardShape.star,
  WhotCardShape.whot
];

class WhotGamePage extends BaseGamePage {
  static const route = "/whot";
  final Map<String, dynamic> args;
  final CallUtils callUtils;
  final void Function(GameAction gameAction) onActionPressed;
  const WhotGamePage(
    this.args,
    this.callUtils,
    this.onActionPressed, {
    super.key,
  }) : super(args, callUtils, onActionPressed);

  @override
  ConsumerState<WhotGamePage> createState() => _WhotGamePageState();
}

class _WhotGamePageState extends BaseGamePageState<WhotGamePage> {
  WhotDetails? prevDetails;
  List<Whot> whots = [], playedWhots = [], newWhots = [];
  List<List<Whot>> playersWhots = [];
  List<WhotCardVisibility> cardVisibilities = [];
  List<String> whotIndices = [];

  int startCards = 6;
  List<int>? deckPoses;
  int needShapeCardIndex = -1;

  int pickCount = 1;
  int pickPlayer = -1;

  String updatePlayerId = "";
  int currentPlayerIndex = 0;

  bool hastLastCard = false;

  List<int> hintPositions = [];
  bool hintGeneralMarket = false;

  bool isLastCard = false;
  bool isSemiLastCard = false;
  bool isHoldOn = false;

  void playIfTimeOut() {
    if (playedWhots.isNotEmpty &&
        playedWhots.first.number == 20 &&
        playedWhots.first.shape == 5) {
      playShape(Random().nextInt(5));
    } else {
      pickWhot();
    }
  }

  void showPossiblePlayPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    if (cardVisibilities[currentPlayer] == WhotCardVisibility.visible) return;
    final playerWhots = playersWhots[currentPlayer];
    for (int i = 0; i < playerWhots.length; i++) {
      hintPositions.add(i);
    }
    //getHintMessage(true);
    setState(() {});
  }

  void getHintPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    final playerWhots = playersWhots[currentPlayer];
    if (needShapeCardIndex != -1) {
      for (int i = 0; i < playerWhots.length; i++) {
        final whot = playerWhots[i];
        if (!hintPositions.contains(whot.shape)) {
          hintPositions.add(whot.shape);
        }
      }
    } else {
      final currentWhot = playedWhots.first;
      if (((currentWhot.number == 14 && pickPlayer != currentPlayer) ||
              (currentWhot.number == 2 && pickPlayer == currentPlayer)) &&
          pickPlayer != -1) {
        setState(() {
          hintGeneralMarket = true;
        });
        return;
      }
      bool containsOther = false;
      for (int i = 0; i < playerWhots.length; i++) {
        final whot = playerWhots[i];
        if (whot.number == 20 ||
            (currentWhot.number == 20 &&
                currentWhot.shape != 5 &&
                whot.shape == currentWhot.shape)) {
          hintPositions.add(i);
        } else {
          if (!containsOther &&
              (currentWhot.number == whot.number ||
                  currentWhot.shape == whot.shape)) {
            containsOther = true;
          }
          if (whot.number == 20 ||
              currentWhot.number == whot.number ||
              currentWhot.shape == whot.shape ||
              whot.number == 20) {
            hintPositions.add(i);
          }
        }
      }
      hintGeneralMarket = hintPositions.isEmpty || !containsOther;
    }
    // getHintMessage(false);
    setState(() {});
  }

  void getHintMessage(bool awaiting) {
    if (awaiting) {
      hintMessage = "Tap to open cards";
    } else {
      if (needShapeCardIndex != -1) {
        if (playedWhots.isNotEmpty && playedWhots.first.shape != 5) {
          hintMessage = "Play cards that match the requested shape";
        } else {
          hintMessage =
              "Choose the shape you need depending on the cards you have";
        }
      } else {
        hintMessage = "Play cards that match the awaiting card number or shape";
      }
    }
    setState(() {});
  }

  void shareCards() async {
    if (whots.isEmpty) return;

    for (int i = 0; i < availablePlayersCount; i++) {
      playersWhots.add([]);

      for (int j = 0; j < startCards; j++) {
        playersWhots[i].insert(0, whots.last);
        whots.removeLast();
      }
    }
    final whot = whots.last;
    if (whot.number == 20) {
      playedWhots.insert(0, whot);
      showPlayerMessage(currentPlayer, "Select a shape or random is selected");
    } else {
      playersWhots[currentPlayer].insert(0, whot);
      playWhot(currentPlayer, 0, null, false, false);
    }
    whots.removeLast();

    message = "";
    setState(() {});
  }

  void playMultipleWhots(int player, [bool isClick = true]) {
    if (deckPoses == null || deckPoses!.isEmpty) return;
    final length = deckPoses!.length;
    for (int i = 0; i < length; i++) {
      final index = deckPoses![i];
      playWhot(player, index, null, i != length - 1, isClick);
    }
  }

  void selectWhot(int player, int index, [bool isClick = true]) {
    if (isClick && cardVisibilities[player] == WhotCardVisibility.turned) {
      if (gameId.isNotEmpty && player != myPlayer && !finishedRound) {
        showToast("You can't flip your opponent's card");
        return;
      }
      cardVisibilities[player] = WhotCardVisibility.visible;
      getHintPositions();
      setState(() {});
      return;
    }

    if (!itsMyTurnToPlay(isClick, player)) return;

    final currentWhot = playedWhots.first;
    final whot = playersWhots[currentPlayer][index];
    if (whot.number == 20 || whot.number == 1 || whot.number == 8) {
      showPlayerToast(currentPlayer, "${whot.number} cannot be decked");
      return;
    }

    if (currentWhot.number != whot.number) {
      showPlayerToast(currentPlayer, "Whot numbers don't match so can't deck");
      return;
    }

    deckPoses ??= [];

    if (deckPoses!.contains(index)) {
      deckPoses!.remove(index);
    } else {
      deckPoses!.add(index);
    }

    if (deckPoses!.isEmpty) {
      deckPoses = null;
    }
    setState(() {});
  }

  void playShape(int shapeIndex, [bool isClick = true]) {
    if (isClick) updateShapeDetails(shapeIndex);
    showPlayerMessage(currentPlayer, "");
    changePlayer();
    playedWhots.first.shape = shapeIndex;
    showPlayerMessage(
        currentPlayer, "I need ${whotCardShapes[shapeIndex].name}");
    setState(() {});
  }

  void playWhot(int player, int index,
      [int? shapeIndex, bool isDeck = false, bool isClick = true]) {
    if (isClick && cardVisibilities[player] == WhotCardVisibility.turned) {
      if (gameId.isNotEmpty && player != myPlayer && !finishedRound) {
        showToast("You can't flip your opponent's card");
        return;
      }
      cardVisibilities[player] = WhotCardVisibility.visible;
      getHintPositions();
      setState(() {});
      return;
    }

    if (!itsMyTurnToPlay(isClick, player)) return;

    final currentWhot = playedWhots.firstOrNull;
    final whot = playersWhots[currentPlayer][index];
    int prevPlayer = currentPlayer;

    if (currentWhot != null) {
      if (pickCount > 1 &&
          ((currentWhot.number == 2 && whot.number != 2) ||
              (currentWhot.number == 5 && whot.number != 5))) {
        final number = currentWhot.number == 2 ? 2 : 5;
        showPlayerToast(currentPlayer,
            "You are to pick $pickCount from market or stack it with card number $number");

        return;
      }

      if (pickPlayer != -1 &&
          currentWhot.number == 14 &&
          currentPlayer != pickPlayer) {
        showPlayerToast(currentPlayer, "You are to pick general market");
        return;
      }

      if (currentWhot.number == 20 && currentWhot.shape == 5) {
        showPlayerToast(currentPlayer, "You are to select a shape");
        return;
      }

      if (whot.number == 20 && shapeIndex == null) {
        if (needShapeCardIndex != index) {
          needShapeCardIndex = index;
        } else {
          needShapeCardIndex = -1;
        }

        setState(() {});
        return;
      }

      if (currentWhot.number == 20 &&
          whot.number != 20 &&
          currentWhot.shape != whot.shape) {
        showPlayerToast(currentPlayer,
            "Whot shape doesn't match ${whotCardShapes[currentWhot.shape].name}");
        return;
      } else {
        if (whot.number != 20 &&
            currentWhot.number != whot.number &&
            currentWhot.shape != whot.shape) {
          showPlayerToast(currentPlayer, "Whot doesn't match shape or number");
          return;
        }
      }

      if (currentWhot.number == 14 && currentPlayer == pickPlayer) {
        pickPlayer = -1;
      }
    }

    playedWhots.insert(0, whot);

    if (!isDeck) {
      if (isClick) updateDetails(index, shapeIndex);

      if (deckPoses != null && deckPoses!.isNotEmpty) {
        List<String> whotIds = [];
        for (int i = 0; i < deckPoses!.length; i++) {
          final index = deckPoses![i];
          whotIds.add(playersWhots[currentPlayer][index].id);
        }
        playersWhots[currentPlayer]
            .removeWhere((whot) => whotIds.contains(whot.id));
        updateCount(prevPlayer, playersWhots[currentPlayer].length);

        // deckPoses = null;
      } else {
        playersWhots[currentPlayer].removeAt(index);
        updateCount(currentPlayer, playersWhots[currentPlayer].length);
      }

      if (whot.number != 1 &&
          whot.number != 8 &&
          whot.number != 2 &&
          whot.number != 5 &&
          whot.number != 20 &&
          whot.number != 14) {
        checkWinGame();
      }
    }

    if (isHoldOn) {
      showAllPlayersMessages("");
      isHoldOn = false;
    } else {
      showPlayerMessage(currentPlayer, "");
    }

    if (whot.number == 14) {
      if (isDeck) {
        pickCount++;
      } else {
        if (deckPoses == null) {
          pickCount = 1;
        }
      }
      pickPlayer = currentPlayer;

      if (!isDeck) {
        showAllPlayersMessages("Pick $pickCount General Market",
            exceptedPlayers: [currentPlayer]);
        changePlayer();
      }
    } else if (whot.number == 1) {
      showAllPlayersMessages("Hold On", exceptedPlayers: [currentPlayer]);
      showPlayerMessage(currentPlayer, "Continue");
      isHoldOn = true;
    } else if (whot.number == 8) {
      changePlayer();
      showPlayerMessage(currentPlayer, "Suspension");
      changePlayer();
      showPlayerMessage(currentPlayer, "Continue");
    } else if (whot.number == 2 || whot.number == 5) {
      final count = whot.number == 2 ? 2 : 3;
      if (pickCount == 1) {
        pickCount = count;
      } else {
        pickCount += count;
      }
      if (!isDeck) {
        changePlayer();
        showPlayerMessage(currentPlayer, "Pick $pickCount");
      }
    } else if (whot.number == 20) {
      changePlayer();
      if (shapeIndex != null) {
        whot.shape = shapeIndex;
        showPlayerMessage(
            currentPlayer, "I need ${whotCardShapes[shapeIndex].name}");
      }

      needShapeCardIndex = -1;
    } else {
      if (!isDeck) {
        changePlayer();
        showPlayerMessage(currentPlayer, "I play, Play");
      }
    }
    if (needShapeCardIndex != -1) {
      needShapeCardIndex = -1;
    }

    if (playersWhots[prevPlayer].length == 1) {
      isLastCard = true;
      showAllPlayersMessages(
          "Last Card${activePlayersCount > 2 ? "(${getPlayerUsername(playerIndex: prevPlayer)})" : ""}",
          exceptedPlayers: [prevPlayer],
          append: true);
    }

    if (gameId.isEmpty && currentPlayer != prevPlayer) {
      hideCards();
    }

    if (!isDeck && deckPoses != null && deckPoses!.isNotEmpty) {
      deckPoses = null;
    }

    showPossiblePlayPositions();

    setState(() {});
  }

  void pickWhot([String? whotIndices, bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;
    //awaiting

    if (!mounted || whots.isEmpty) return;

    if (playedWhots.isNotEmpty &&
        playedWhots.first.number == 20 &&
        playedWhots.first.shape == 5) {
      showPlayerToast(currentPlayer, "You are to select a shape");
      return;
    }

    if (pickCount >= whots.length) {
      final lastPlayedWhot = playedWhots.first;
      List<Whot> otherPlayedWhots = [];
      if (whotIndices != null) {
        otherPlayedWhots = (jsonDecode(whotIndices) as List)
            .map((e) => Whot.fromJson(e))
            .toList();
      } else {
        otherPlayedWhots = playedWhots
            .map((whot) => whot.number == 20 ? whot.copyWith(shape: 5) : whot)
            .where((element) => element.id != lastPlayedWhot.id)
            .toList();
        otherPlayedWhots.shuffle();
        if (isClick) {
          updateDetails(-1, null, jsonEncode(otherPlayedWhots));
        }
      }

      playedWhots = [lastPlayedWhot];
      whots = [...otherPlayedWhots, ...whots];
      //whots.addAll(otherPlayedWhots);
    } else {
      if (isClick) {
        updateDetails(-1);
      }
    }
    if (gameId.isEmpty) {
      hideCards();
    }

    for (int i = 0; i < pickCount; i++) {
      if (whots.isEmpty) return;
      playersWhots[currentPlayer].insert(0, whots.last);
      whots.removeLast();
      updateCount(currentPlayer, playersWhots[currentPlayer].length);
    }

    if (pickPlayer == -1 && pickCount > 1) {
      pickCount = 1;
      pickPlayer = -1;
    }

    if (isHoldOn) {
      showAllPlayersMessages("");
      isHoldOn = false;
    } else {
      showPlayerMessage(currentPlayer, "");
    }
    changePlayer();
    showPlayerMessage(currentPlayer, "I pick, Play");

    if (currentPlayer == pickPlayer) {
      pickCount = 1;
      pickPlayer = -1;
    }

    if ((deckPoses ?? []).isNotEmpty) {
      deckPoses = null;
    }

    hastLastCard = false;
    showPossiblePlayPositions();
    if (needShapeCardIndex != -1) {
      needShapeCardIndex = -1;
    }

    if (whots.isEmpty) {
      tenderCards();
    }
    setState(() {});
  }

  void resetLastOrSemiLastCard() {
    if (hastLastCard && playersWhots[currentPlayer].length == 1) {
      for (int i = 0; i < playersSize; i++) {
        if (i != currentPlayer) {
          final message = playersMessages[i];
          if (message.startsWith("Last Card ")) {
            playersMessages[i].replaceAll("Last Card ", "");
          }
          // else if (message.startsWith("Semi Last Card ")) {
          //   playersMessages[i].replaceAll("Semi Last Card ", "");
          // }
        }
      }
    }
  }

  void hideCards() {
    if (needShapeCardIndex != -1 || isWatch) return;
    for (int i = 0; i < playersSize; i++) {
      cardVisibilities[i] = WhotCardVisibility.turned;
    }

    setState(() {});
  }

  int prevPlayer([bool doubleCount = false]) {
    int index = getPrevPlayerIndex();
    if (doubleCount) {
      index = getPrevPlayerIndex(index);
    }
    return index;
  }

  int nextPlayer([bool doubleCount = false]) {
    int index = getNextPlayerIndex();
    if (doubleCount) {
      index = getNextPlayerIndex(index);
    }
    return index;
  }

  Future tenderCards() async {
    int lowestCount = -1;
    List<int> counts = [];
    List<int> playersWhotsCount = [];
    List<int> winners = [];
    bool hasWinner = false;

    for (int i = 0; i < playersWhots.length; i++) {
      final playerWhots = playersWhots[i];
      int count = 0;
      List<String> messages = [];
      if (playerWhots.isEmpty) {
        lowestCount = count;
        counts.add(0);
        playersMessages[i] = "0 card";
        winners.clear();
        winners.add(i);
        hasWinner = true;
        continue;
      }
      playersMessages[i] = "Counting Cards";
      if (!seeking) await Future.delayed(const Duration(seconds: 1));
      for (int j = 0; j < playerWhots.length; j++) {
        final whot = playerWhots[j];
        WhotCardShape shape = whotCardShapes[whot.shape];
        int value = whot.number;
        // if (shape == WhotCardShape.star) {
        //   value = 2 * whot.number;
        // } else {
        //   value = whot.number;
        // }
        count += value;

        String message = "${whot.number}${shape.name}($value)";
        messages.add(message);
      }
      counts.add(count);
      playersMessages[i] = "$count count";
      //playersMessages[i] = "${messages.join("+")} = $count";
      playersWhotsCount.add(count);
      setState(() {});
      if (!hasWinner) {
        if (lowestCount == -1) {
          lowestCount = count;
        } else if (count < lowestCount) {
          lowestCount = count;
          winners.clear();
          winners.add(i);
        } else if (count == lowestCount) {
          winners.add(i);
        }
      }
    }
    counts.sort();
    for (int i = 0; i < playersMessages.length; i++) {
      final message = playersMessages[i];
      final position = counts
          .indexWhere((element) => "$element" == message.split(" ").first);
      playersMessages[i] =
          "${position == 0 ? "1st" : position == 1 ? "2nd" : position == 2 ? "3rd" : "4th"} - $message";
    }
    setState(() {});
    if (winners.isNotEmpty) {
      if (winners.length == 1) {
        updateWin(winners.first);
      } else {
        updateTie(winners);
      }
    }
  }

  void checkWinGame() async {
    if (playersWhots[currentPlayer].isEmpty) {
      if (playersSize > 2) {
        tenderCards();
      } else {
        updateWin(currentPlayer);
      }
    }
  }

  List<Whot> getWhots() {
    List<Whot> whots = [
      ...List.generate(14, (index) => Whot("", index + 1, 0))
          .where((value) => value.number != 6 && value.number != 9),
      ...List.generate(14, (index) => Whot("", index + 1, 1))
          .where((value) => value.number != 6 && value.number != 9),
      ...List.generate(14, (index) => Whot("", index + 1, 2)).where((value) =>
          value.number != 6 &&
          value.number != 9 &&
          value.number != 4 &&
          value.number != 8 &&
          value.number != 12),
      ...List.generate(14, (index) => Whot("", index + 1, 3)).where((value) =>
          value.number != 6 &&
          value.number != 9 &&
          value.number != 4 &&
          value.number != 8 &&
          value.number != 12),
      ...List.generate(8, (index) => Whot("", index + 1, 4))
          .where((value) => value.number != 6),
      ...List.generate(5, (index) => Whot("", 20, 5)),
    ];
    for (int i = 0; i < whots.length; i++) {
      whots[i].id = "$i";
    }
    return whots;
  }

  void initWhots([String? whotIndices]) async {
    setInitialCount(startCards);
    needShapeCardIndex = -1;
    hintPositions.clear();
    whots.clear();
    playedWhots.clear();
    playersWhots.clear();
    cardVisibilities.clear();
    for (int i = 0; i < playersSize; i++) {
      playersMessages[i] = "";
    }
    cardVisibilities.addAll(List.generate(
        playersSize,
        (index) => finishedRound
            ? WhotCardVisibility.visible
            : WhotCardVisibility.turned));
    if (whotIndices != null) {
      whots = (jsonDecode(whotIndices) as List)
          .map((e) => Whot.fromJson(e))
          .toList();
    } else {
      final newWhots = getWhots();
      // newWhots = newWhots
      //     .where((whot) =>
      //         whot.number == 2 ||
      //         whot.number == 5 ||
      //         whot.number == 14 ||
      //         whot.number == 20)
      //     .toList();
      //newWhots.sortList((whot) => whot.number, false);

      newWhots.shuffle();
      // newWhots.insert(newWhots.length - (activePlayersCount * startCards),
      //     Whot("100", 20, 5));

      whots.addAll(newWhots);

      updateInitalWhotDetails(jsonEncode(whots));
    }

    shareCards();
  }

  Future updateInitalWhotDetails(String whotIndices) async {
    final details = WhotDetails(whotIndices: whotIndices);

    await setDetail(details.toMap());
  }

  // Future updateINeedDetails(int playPos, int shapePos) async {
  //   final details = WhotDetails(playPos: playPos, shapePos: shapePos);

  //   await setDetail(details.toMap());
  // }

  Future updateShapeDetails(int shapePos) async {
    final details = WhotDetails(shapePos: shapePos);

    await setDetail(details.toMap());
  }

  Future updateDetails(int playPos,
      [int? shapePos, String? whotIndices]) async {
    final details = WhotDetails(
        playPos: deckPoses == null ? playPos : null,
        whotIndices: whotIndices,
        shapePos: shapePos,
        deckPoses: deckPoses);

    await setDetail(details.toMap());
  }

  void flipCards(int index) {
    WhotCardVisibility cardVisibility = cardVisibilities[index];
    if (cardVisibility == WhotCardVisibility.turned) {
      cardVisibilities[index] = WhotCardVisibility.visible;
      getHintPositions();
    } else {
      cardVisibilities[index] = WhotCardVisibility.turned;
      showPossiblePlayPositions();
    }
    setState(() {});
  }

  String getCardVisibilityString(int index) {
    WhotCardVisibility cardVisibility = cardVisibilities[index];
    return "${cardVisibility == WhotCardVisibility.visible ? "Turn" : cardVisibility == WhotCardVisibility.turned ? "Hide" : "Show"} Cards";
  }

  @override
  int? maxGameTime = 15.minToSec;

  @override
  int? maxPlayerTime;

  @override
  void onConcede(int index) {
    if (gameId.isEmpty) hideCards();
  }

  @override
  Future onDetailsChange(Map<String, dynamic>? map) async {
    if (map != null) {
      final details = WhotDetails.fromMap(map);
      final playPos = details.playPos;
      final shapePos = details.shapePos;
      final deckPoses = details.deckPoses;

      final whotIndices = details.whotIndices;
      final playerIndex = getPlayerIndex(map["id"]);

      if (playPos == null) {
        if (whotIndices != null) {
          initWhots(whotIndices);
        }
        if (deckPoses != null) {
          this.deckPoses = [...deckPoses];
          playMultipleWhots(playerIndex, false);
        }
        if (shapePos != null) {
          playShape(shapePos, false);
        }
      } else if (playPos == -1) {
        pickWhot(whotIndices, false);
      } else {
        playWhot(playerIndex, playPos, shapePos, false, false);
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
    // if (gameId.isEmpty) hideCards();
  }

  @override
  void onPause() {
    // TODO: implement onPause
  }

  @override
  void onSpaceBarPressed() {
    pickWhot();
  }

  @override
  void onInit() {
    initWhots();
  }

  @override
  void onResume() {
    // TODO: implement onResume
  }

  @override
  void onStart() {}

  @override
  void onPlayerTimeEnd() {
    playIfTimeOut();
  }

  @override
  void onTimeEnd() {
    tenderCards();
  }

  @override
  void onPlayerChange(int player) {}

  @override
  Widget buildBottomOrLeftChild(int index) {
    // if (whots.isEmpty || playersWhots.isEmpty) {
    //   return Container();
    // }
    if (playersWhots.isEmpty) {
      return Container();
    }
    return Stack(
      // mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.end,
      alignment: Alignment.centerRight,
      children: [
        Container(
          height: cardHeight,
          width: double.infinity,
          alignment: Alignment.center,
          child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: playersWhots[index].length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 6);
              },
              itemBuilder: ((context, whotIndex) {
                final whot = playersWhots[index][whotIndex];
                if (currentPlayer == index && needShapeCardIndex == whotIndex) {
                  return SizedBox(
                    height: cardHeight,
                    width: cardWidth,
                    child: Wrap(
                        // alignment: WrapAlignment.center,
                        children: List.generate(6, (shapeIndex) {
                      if (shapeIndex == 5) {
                        return GestureDetector(
                          onTap: () {
                            needShapeCardIndex = -1;
                            setState(() {});
                          },
                          child: Container(
                            height: (cardHeight / 3),
                            width: (cardWidth / 2),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.red),
                            child:
                                const Icon(EvaIcons.close, color: Colors.white),
                          ),
                        );
                      }
                      return WhotCard(
                          highlight: false,
                          blink: firstTime &&
                              hintPositions.contains(shapeIndex) &&
                              !awaiting,
                          height: (cardHeight / 3),
                          width: (cardWidth / 2),
                          margin: 0,
                          whot: Whot("", -1, shapeIndex),
                          onPressed: () {
                            playWhot(index, whotIndex, shapeIndex);
                          });
                    })),
                  );
                }
                return WhotCard(
                  blink: firstTime &&
                      index == currentPlayer &&
                      hintPositions.contains(whotIndex) &&
                      needShapeCardIndex == -1 &&
                      !awaiting,
                  highlight: index == currentPlayer &&
                      (deckPoses ?? []).contains(whotIndex),
                  // index == currentPlayer && whotIndex == needShapeCardIndex,
                  key: Key(whot.id),
                  height: cardHeight,
                  width: cardWidth,
                  whot: whot,
                  count: whotIndex + 1,
                  isBackCard:
                      cardVisibilities[index] == WhotCardVisibility.turned,
                  onLongPressed: () {
                    selectWhot(index, whotIndex);
                  },
                  onPressed: () {
                    if ((deckPoses ?? []).isNotEmpty) {
                      selectWhot(index, whotIndex);
                    } else {
                      playWhot(index, whotIndex);
                    }
                  },
                  onDoubleTap: () {
                    flipCards(index);
                  },
                );
              })),
        ),
        if (index == currentPlayer && (deckPoses ?? []).isNotEmpty) ...[
          GestureDetector(
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor,
              child: Icon(EvaIcons.checkmark, color: Colors.white),
            ),
            onTap: () {
              playMultipleWhots(index);
            },
          ),
          // const SizedBox(height: 4),
        ],
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    // print("gameDetails = $gameDetails");
    // bool isEdgeTilt = gameId.isNotEmpty &&
    //     playersSize > 2 &&
    //     (myPlayer == 1 || myPlayer == 3);
    // final value = isEdgeTilt ? !landScape : landScape;
    // final playedRemaining = (minSize / 2) + (cardWidth / 2);
    if (playedWhots.isEmpty || whots.isEmpty || playersWhots.isEmpty) {
      return Container();
    }

    final generalMarketWidget = RotatedBox(
      quarterTurns: getTurn(currentPlayer),
      child: playedWhots.first.number == 20 && playedWhots.first.shape == 5
          ? SizedBox(
              height: cardHeight,
              width: cardWidth,
              child: Wrap(
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (shapeIndex) {
                    return WhotCard(
                        highlight: false,
                        blink: firstTime &&
                            hintPositions.contains(shapeIndex) &&
                            !awaiting,
                        height: (cardHeight / 3),
                        width: (cardWidth / 2),
                        margin: 0,
                        whot: Whot("", -1, shapeIndex),
                        onPressed: () {
                          playShape(shapeIndex);
                        });
                  })),
            )
          : WhotCard(
              highlight: false,
              blink: hintGeneralMarket && needShapeCardIndex == -1 && firstTime,
              height: cardHeight,
              width: cardWidth,
              whot: whots.last,
              count: whots.length,
              isBackCard: true,
              onPressed: pickWhot,
            ),
    );
    final playedRemaining =
        (minSize / 2) + (landScape ? (cardWidth / 2) : (cardHeight / 2));

    bool isLeft = currentPlayer == 0 ||
        (landScape
            ? currentPlayer == 3
            : (currentPlayer == 1 && playersSize > 2));
    return Center(
      child: SizedBox(
        height: landScape ? cardHeight : minSize,
        width: landScape ? minSize : cardHeight,
        child: ColumnOrRow(
          column: !landScape,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isLeft) generalMarketWidget,
            SizedBox(
              width: landScape ? playedRemaining : cardHeight,
              height: landScape ? cardHeight : playedRemaining,
              child: ListView.separated(
                scrollDirection: landScape ? Axis.horizontal : Axis.vertical,
                reverse: !isLeft,
                itemCount: playedWhots.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 6);
                },
                itemBuilder: (context, index) {
                  final whot = playedWhots[index];

                  return RotatedBox(
                    quarterTurns: getTurn(currentPlayer),
                    child: WhotCard(
                      blink: false,
                      height: cardHeight,
                      width: cardWidth,
                      count: playedWhots.length - index,
                      whot: whot,
                      isBackCard: false,
                      highlight: index == 0,
                    ),
                  );
                },
              ),
            ),
            if (!isLeft) generalMarketWidget,
          ],
        ),
      ),
      // : RotatedBox(
      //     quarterTurns: currentPlayer == 0 ||
      //             (playersSize > 2 &&
      //                 ((value && currentPlayer == 3) ||
      //                     (!value && currentPlayer == 1)))
      //         ? 2
      //         : 0,
      //     child: SizedBox(
      //       height: value ? cardHeight : minSize,
      //       width: value ? minSize : cardHeight,
      //       child: ColumnOrRow(
      //         column: !value,
      //         mainAxisSize: MainAxisSize.min,
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           // RotatedBox(
      //           //   quarterTurns: currentPlayer == 3 ||
      //           //           (currentPlayer == 1 && playersSize > 2)
      //           //       ? value
      //           //           ? 3
      //           //           : 1
      //           //       : 0,
      //           //   child: SizedBox(
      //           //     height: cardHeight,
      //           //     width: cardWidth,
      //           //   ),
      //           // ),
      //           RotatedBox(
      //               quarterTurns: currentPlayer == 3 ||
      //                       (currentPlayer == 1 && playersSize > 2)
      //                   ? value
      //                       ? 3
      //                       : 1
      //                   : 0,
      //               child: SizedBox(
      //                 width: value ? playedRemaining : cardHeight,
      //                 height: value ? cardHeight : playedRemaining,
      //                 child: ListView.separated(
      //                   scrollDirection:
      //                       value ? Axis.horizontal : Axis.vertical,
      //                   reverse: true,
      //                   itemCount: playedWhots.length,
      //                   separatorBuilder: (context, index) {
      //                     return const SizedBox(width: 6);
      //                   },
      //                   itemBuilder: (context, index) {
      //                     final whot = playedWhots[index];

      //                     return WhotCard(
      //                       blink: false,
      //                       height: cardHeight,
      //                       width: cardWidth,
      //                       count: playedWhots.length - index,
      //                       whot: whot,
      //                       isBackCard: false,
      //                       highlight: index == 0,
      //                     );
      //                   },
      //                 ),
      //               )),
      //           RotatedBox(
      //             quarterTurns: currentPlayer == 3 ||
      //                     (currentPlayer == 1 && playersSize > 2)
      //                 ? value
      //                     ? 3
      //                     : 1
      //                 : 0,
      //             child: playedWhots.first.number == 20 &&
      //                     playedWhots.first.shape == 5
      //                 ? SizedBox(
      //                     height: cardHeight,
      //                     width: cardWidth,
      //                     child: Wrap(
      //                         alignment: WrapAlignment.center,
      //                         children: List.generate(5, (shapeIndex) {
      //                           return WhotCard(
      //                               highlight: false,
      //                               blink: firstTime &&
      //                                   hintPositions
      //                                       .contains(shapeIndex) &&
      //                                   !awaiting,
      //                               height: (cardHeight / 3),
      //                               width: (cardWidth / 2),
      //                               margin: 0,
      //                               whot: Whot("", -1, shapeIndex),
      //                               onPressed: () {
      //                                 playShape(shapeIndex);
      //                               });
      //                         })),
      //                   )
      //                 : WhotCard(
      //                     highlight: false,
      //                     blink: hintGeneralMarket &&
      //                         needShapeCardIndex == -1 &&
      //                         firstTime,
      //                     height: cardHeight,
      //                     width: cardWidth,
      //                     whot: whots.last,
      //                     count: whots.length,
      //                     isBackCard: true,
      //                     onPressed: pickWhot,
      //                   ),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
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
