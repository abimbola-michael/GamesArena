// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/base/base_game_page.dart';

import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/whot/models/whot.dart';

import '../../../../shared/widgets/custom_grid.dart';
import '../services.dart';
import '../widgets/whot_card.dart';
import '../../../../enums/emums.dart';

import '../../../../shared/utils/constants.dart';
import '../../../../shared/utils/utils.dart';

class WhotGamePage extends BaseGamePage {
  static const route = "/whot";

  const WhotGamePage({
    super.key,
  });

  @override
  State<WhotGamePage> createState() => _WhotGamePageState();
}

class _WhotGamePageState extends BaseGamePageState<WhotGamePage> {
  bool played = false;
  WhotDetails? prevDetails;
  List<Whot> whots = [], playedWhots = [], newWhots = [];
  List<List<Whot>> playersWhots = [];
  List<WhotCardVisibility> cardVisibilities = [];
  List<String> whotIndices = [];

  int startCards = 5;
  WhotCardShape? shapeNeeded;
  bool needShape = false;

  int pickCount = 1;
  int pickPlayer = 0;

  String updatePlayerId = "";
  int currentPlayerIndex = 0;

  bool hastLastCard = false;

  List<int> hintPositions = [];
  bool hintGeneralMarket = false;
  bool hintShapeNeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cardHeight = (minSize - 80) / 3;
    cardWidth = cardHeight.percentValue(65);
  }

  void playIfTimeOut() {
    if (gameId != "") {
      pausePlayerTime = true;
      if (currentPlayerId == myId) {
        if (needShape && shapeNeeded == null) {
          final index = Random().nextInt(5);
          updateDetails(-1, index, "");
        } else {
          updateDetails(-1, -1, "");
        }
      } else {}
    } else {
      if (needShape && shapeNeeded == null) {
        final index = Random().nextInt(5);
        playShape(index);
      } else {
        pickWhot();
      }
    }
  }

  void shareCards() async {
    if (awaiting) return;
    if (whots.isEmpty) return;
    for (int i = 0; i < playersSize; i++) {
      playersWhots.add([]);
    }
    awaiting = true;
    final cardsToShare = (startCards * playersSize) + 1;
    int j = 0;
    for (int i = 0; i < cardsToShare; i++) {
      if (i < whots.length) {
        final whot = whots.first;
        await Future.delayed(const Duration(milliseconds: 100));
        if (i == cardsToShare - 1) {
          playWhot(-1);
        } else {
          playersWhots[j].insert(0, whot);
          j = j == playersSize - 1 ? 0 : j + 1;
        }
        whots.removeAt(0);
        setState(() {});
      }
    }
    awaiting = false;
    pausePlayerTime = false;

    message = "";
    setState(() {});
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
    if (needShape) {
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
                shapeNeeded != null &&
                whot.shape == shapeNeeded!.index)) {
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

  void getHintMessage(bool played) {
    if (played) {
      hintMessage = "Tap to open cards";
    } else {
      if (needShape) {
        if (shapeNeeded != null) {
          hintMessage = "Play cards that match the requested shape";
        } else {
          hintMessage =
              "Choose the shape you need depending on the cards you have";
        }
      } else {
        hintMessage = "Play cards that match the played card number or shape";
      }
    }
    setState(() {});
  }

  void playWhot(int index) async {
    if (!mounted) return;

    if (needShape && index != -1) {
      showToast(currentPlayer, "Select shape");
      return;
    }
    Whot whot = index == -1 ? whots.first : playersWhots[currentPlayer][index];
    final currentWhot = playedWhots.isEmpty ? whots.first : playedWhots.first;
    if (shapeNeeded != null &&
        shapeNeeded != whotCardShapes[whot.shape] &&
        whot.number != 20 &&
        index != -1) {
      showToast(currentPlayer,
          "This is not ${shapeNeeded!.name}\n Go to Market if you don't have");
      return;
    }
    final next = nextPlayer();
    final prev = prevPlayer();
    final next2 = nextPlayer(true);
    final prev2 = prevPlayer(true);
    if (currentWhot.number == whot.number ||
        currentWhot.shape == whot.shape ||
        whot.number == 20 ||
        (shapeNeeded != null && shapeNeeded == whotCardShapes[whot.shape])) {
      final number = whot.number;
      if (index != -1) {
        // if (playedWhots.isNotEmpty && playedWhots.first.number == 1) {
        //   for (int i = 0; i < playersSize; i++) {
        //     if (i != currentPlayer) {
        //       playersMessages[i] = playersMessages[i].replaceAll("Hold On", "");
        //     }
        //   }
        // }
        playedWhots.insert(0, whot);
        final currentPlayerWhots = playersWhots[currentPlayer];
        if (currentPlayerWhots.isNotEmpty) {
          currentPlayerWhots.removeAt(index);
        }
      } else {
        playedWhots.add(whot);
      }

      playersMessages[currentPlayer] = "";
      playersMessages[prev] = "";

      String lastMessage = "";
      hastLastCard = false;
      // if (playersWhots[currentPlayer].length == 2) {
      //   lastMessage = "Semi Last Card ";
      //   hastLastCard = true;
      // } else
      if (playersWhots[currentPlayer].length == 1) {
        lastMessage = "Last Card ";
        hastLastCard = true;
      } else if (playersWhots[currentPlayer].isEmpty) {
        if (number != 1 &&
            number != 8 &&
            number != 14 &&
            number != 2 &&
            number != 20) {
          lastMessage = "Check Up";
        }
      }
      // if (lastMessage != "") {
      //   if (playersSize > 2) {
      //     lastMessage +=
      //         ": ${users != null ? "${users![currentPlayer]?.username ?? ""}\n" : "${currentPlayer + 1}"}\n";
      //   } else {
      //     lastMessage += "\n";
      //   }
      // }

      if (number == 1 || number == 8 || number == 14 || number == 2) {
        String nextMessage = number == 1
            ? "Hold On"
            : number == 8
                ? "Suspension"
                : number == 2
                    ? "Pick 2"
                    : "General Market";
        if (number == 14) {
          pickCount = 1;
          pickPlayer = currentPlayer;
        } else if (number == 2) {
          pickCount = 2;
          pickPlayer = next;
        }
// || number == 1
        if (number == 14) {
          for (int i = 0; i < playersSize; i++) {
            if (i != currentPlayer) {
              playersMessages[i] = "$lastMessage$nextMessage";
            }
            // else {
            //   if (number == 1) {
            //     playersMessages[currentPlayer] += "Continue";
            //   }
            // }
          }
        } else {
          playersMessages[next] = "";
          playersMessages[next2] = "";
          if (lastMessage != "") {
            for (int i = 0; i < playersSize; i++) {
              if (i != currentPlayer) {
                playersMessages[i] = lastMessage;
              }
            }
          }
          playersMessages[next] += nextMessage;
          if (number == 8 || number == 1) {
            playersMessages[next2] += "Continue";
          }
        }
      } else {
        if (lastMessage != "") {
          for (int i = 0; i < playersSize; i++) {
            if (i != currentPlayer) {
              playersMessages[i] = lastMessage;
            }
          }
        }
        needShape = number == 20;
        if (index != -1 && number != 20) {
          checkWinGame();
        }
      }

      if (shapeNeeded != null && shapeNeeded == whotCardShapes[whot.shape]) {
        needShape = false;
        shapeNeeded = null;
      }
// || number == 1
      if (number == 20) {
        playerTime = maxPlayerTime;
        if (index == -1) {
          showPossiblePlayPositions();
        } else {
          getHintPositions();
        }
      } else {
        changePlayer(number == 8 || number == 1);
        showPossiblePlayPositions();
      }
      if (gameId == "" && (playersSize != 2 || (number != 8 && number != 1))) {
        hideCards();
      }

      hintGeneralMarket = number == 2 || number == 14;
      awaiting = false;
      setState(() {});
    } else {
      showToast(currentPlayer, "Cards Don't Match");
    }
  }

  void playShape(int index) {
    shapeNeeded = whotCardShapes[index];
    final next = nextPlayer();
    playersMessages[next] =
        "${playersMessages[currentPlayer].contains("I need") ? "" : "${playersMessages[currentPlayer]} "}I need ${shapeNeeded!.name}";
    needShape = false;
    changePlayer(false);
    showPossiblePlayPositions();
    setState(() {});
  }

  void pickWhot() {
    if (!mounted || awaiting || whots.isEmpty) return;
    // if (shapeNeeded == null) {
    //   message = "";
    // }
    for (int i = 0; i < pickCount; i++) {
      final whot = whots.first;
      playersWhots[currentPlayer].insert(0, whot);
      whots.removeAt(0);
      awaiting = false;
      if (whots.isEmpty) {
        tenderCards();
        return;
      }
    }

    // if (playedWhots.isNotEmpty && playedWhots.first.number == 1) {
    //   for (int i = 0; i < playersSize; i++) {
    //     if (i != currentPlayer) {
    //       playersMessages[i] = playersMessages[i].replaceAll("Hold On", "");
    //     }
    //   }
    // }
    resetLastOrSemiLastCard();
    final next = nextPlayer();
    final prev = prevPlayer();
    playersMessages[currentPlayer] = "";
    playersMessages[prev] = "";
    // changePlayer(false, true);
    changePlayer(false);

    if (pickPlayer == currentPlayer) {
      pickPlayer = -1;
    }
    pickCount = 1;
    hastLastCard = false;
    showPossiblePlayPositions();
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

  void getNewWhots() {
    List<Whot> newWhots = [];
    if (playedWhots.isNotEmpty) {
      newWhots.addAll(playedWhots);
      newWhots.removeAt(0);
      final indices = newWhots.map((value) => value.id).toList();
      for (int i = 0; i < 10; i++) {
        indices.shuffle();
      }
      if (gameId == "") {
        updateNewWhots(indices);
      } else {
        updateDetails(-1, -1, indices.join(","));
      }
    } else {
      if (gameId == "") {
        pickWhot();
      } else {
        updateDetails(-1, -1, "");
      }
    }
  }

  void updateNewWhots(List<String> indices) {
    List<Whot> newPlayedWhot = [];
    List<Whot> newWhots = [], convertedWhots = [];
    if (playedWhots.isNotEmpty) {
      newPlayedWhot.add(playedWhots[0]);
      newWhots.addAll(playedWhots);
      newWhots.removeAt(0);
      for (int i = 0; i < indices.length; i++) {
        final id = indices[i];
        convertedWhots.add(newWhots.firstWhere((element) => element.id == id));
      }
      newWhots = convertedWhots;
      whots.addAll(newWhots);
      playedWhots.clear();
      playedWhots.addAll(newPlayedWhot);
      whotIndices = indices;
      setState(() {});
      showToast(currentPlayer, "Updated new whots");
      pickWhot();
    }
  }

  void hideCards() {
    if (needShape && shapeNeeded == null) return;
    for (int i = 0; i < playersSize; i++) {
      cardVisibilities[i] = WhotCardVisibility.turned;
      // if (i == playerIndex && gameId != "") {
      //   continue;
      // } else {
      //   cardVisibilities[i] = WhotCardVisibility.turned;
      // }
    }
    //if (gameId != "" || (needShape && shapeNeeded == null)) return;
    // if (playersSize == 2) {
    //   cardVisibilities[currentPlayer == 0 ? 1 : 0] = WhotCardVisibility.turned;
    //   cardVisibilities[currentPlayer] = WhotCardVisibility.turned;
    // } else {
    //   if (currentPlayer == 0 || currentPlayer == 1) {
    //     cardVisibilities[currentPlayer] = WhotCardVisibility.turned;
    //     cardVisibilities[currentPlayer == 0 ? 1 : 0] =
    //         WhotCardVisibility.hidden;
    //     cardVisibilities[2] = WhotCardVisibility.turned;
    //     if (playersSize == 4) {
    //       cardVisibilities[3] = WhotCardVisibility.hidden;
    //     }
    //   } else if (currentPlayer == 2 || currentPlayer == 3) {
    //     cardVisibilities[currentPlayer] = WhotCardVisibility.turned;
    //     if (playersSize == 4) {
    //       cardVisibilities[currentPlayer == 2 ? 3 : 2] =
    //           WhotCardVisibility.hidden;
    //     }
    //     cardVisibilities[0] = WhotCardVisibility.turned;
    //     cardVisibilities[1] = WhotCardVisibility.hidden;
    //   }
    // }
    // if (gameId != "") {
    //   cardVisibilities[playerIndex] = WhotCardVisibility.visible;
    //   if (playersSize == 4) {
    //     cardVisibilities[playerIndex == 2 ? 3 : 2] = WhotCardVisibility.turned;
    //   }
    // }
    setState(() {});
  }

  // void changePlayer(bool suspend, [bool picked = false]) {
  //   hintGeneralMarket = false;
  //   playerTime = maxPlayerTime;
  //   // message = "Player $currentPlayer ${picked ? "picked" : "played"} Your Turn";
  //   getNextPlayer();
  //   if (suspend) getNextPlayer();
  //   if (gameId != "" || (playersSize == 2 && suspend)) {
  //     return;
  //   }
  //   hideCards();
  // }

  int prevPlayer([bool doubleCount = false]) {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      int prevPlayerIndex = prevIndex(playersSize, currentPlayerIndex);
      String playerId = playerIds[prevPlayerIndex];
      while (playing.indexWhere((element) => element.id == playerId) == -1) {
        prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
        playerId = playerIds[prevPlayerIndex];
      }
      if (doubleCount) {
        prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
        playerId = playerIds[prevPlayerIndex];
        while (playing.indexWhere((element) => element.id == playerId) == -1) {
          prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
          playerId = playerIds[prevPlayerIndex];
        }
      }
      return prevPlayerIndex;
    } else {
      int prevPlayerIndex = prevIndex(playersSize, currentPlayer);
      if (doubleCount) {
        prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
      }
      return prevPlayerIndex;
    }
  }

  int nextPlayer([bool doubleCount = false]) {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      int nextPlayerIndex = nextIndex(playersSize, currentPlayerIndex);
      String playerId = playerIds[nextPlayerIndex];
      while (playing.indexWhere((element) => element.id == playerId) == -1) {
        nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
        playerId = playerIds[nextPlayerIndex];
      }
      if (doubleCount) {
        nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
        playerId = playerIds[nextPlayerIndex];
        while (playing.indexWhere((element) => element.id == playerId) == -1) {
          nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
          playerId = playerIds[nextPlayerIndex];
        }
      }
      return nextPlayerIndex;
    } else {
      int nextPlayerIndex = nextIndex(playersSize, currentPlayer);
      if (doubleCount) {
        nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
      }
      return nextPlayerIndex;
    }
  }

  void startMessageFuture() {
    if (showMessage) return;
    setState(() {
      showMessage = true;
    });
    Future.delayed(const Duration(seconds: 3)).then((value) {
      setState(() {
        showMessage = false;
        message = "";
      });
    });
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
      await Future.delayed(const Duration(seconds: 1));
      for (int j = 0; j < playerWhots.length; j++) {
        final whot = playerWhots[j];
        WhotCardShape shape = whotCardShapes[whot.shape];
        int value = 0;
        if (shape == WhotCardShape.star) {
          value = 2 * whot.number;
        } else {
          value = whot.number;
        }
        count += value;

        String message = "${whot.number}${shape.name}($value)";
        messages.add(message);
      }
      counts.add(count);
      playersMessages[i] = "$count cards";
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

  void addInitialWhots() {
    //getCurrentPlayer();
    needShape = false;
    shapeNeeded = null;
    hintPositions.clear();
    whots.clear();
    playedWhots.clear();
    playersWhots.clear();
    cardVisibilities.clear();
    for (int i = 0; i < playersSize; i++) {
      playersMessages[i] = "";
    }
    cardVisibilities.addAll(
        List.generate(playersSize, (index) => WhotCardVisibility.turned));
    whots.addAll(getWhots());
    whots = whots.arrangeWithStringList(whotIndices);
    shareCards();
  }

  void updateDetails(int playPos, int shapeNeeded, String whotIndices) {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = WhotDetails(
        currentPlayerId: myId,
        playPos: playPos,
        shapeNeeded: shapeNeeded,
        whotIndices: whotIndices,
      );
      setWhotDetails(
        gameId,
        details,
        prevDetails,
      );
      prevDetails = details;
    }
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
  //         quarterTurns: gameId != ""
  //             ? myPlayer == 0
  //                 ? 2
  //                 : myPlayer == 1 && playersSize > 2
  //                     ? 1
  //                     : myPlayer == 3
  //                         ? 3
  //                         : 0
  //             : 0,
  //         child: Stack(
  //           children: [
  //             ...List.generate(playersSize, (index) {
  //               final mindex = (playersSize / 2).ceil();
  //               bool isEdgeTilt = gameId != "" &&
  //                   playersSize > 2 &&
  //                   (myPlayer == 1 || myPlayer == 3);
  //               final value = isEdgeTilt ? !landScape : landScape;
  //               return Positioned(
  //                   top: index < mindex ? 0 : null,
  //                   bottom: index >= mindex ? 0 : null,
  //                   left: index == 0 || index == 3 ? 0 : null,
  //                   right: index == 1 || index == 2 ? 0 : null,
  //                   child: Container(
  //                     width: value
  //                         ? padding
  //                         : playersSize > 2
  //                             ? minSize / 2
  //                             : minSize,
  //                     height: value ? minSize / 2 : padding,
  //                     alignment: value
  //                         ? index == 0
  //                             ? Alignment.topRight
  //                             : index == 1
  //                                 ? playersSize > 2
  //                                     ? Alignment.topLeft
  //                                     : Alignment.bottomLeft
  //                                 : index == 2
  //                                     ? Alignment.bottomLeft
  //                                     : Alignment.bottomRight
  //                         : index == 0
  //                             ? Alignment.bottomLeft
  //                             : index == 1
  //                                 ? playersSize > 2
  //                                     ? Alignment.bottomRight
  //                                     : Alignment.topRight
  //                                 : index == 2
  //                                     ? Alignment.topRight
  //                                     : Alignment.topLeft,
  //                     child: RotatedBox(
  //                       quarterTurns: index == 0
  //                           ? 2
  //                           : index == 1 && playersSize > 2
  //                               ? 3
  //                               : index == 3
  //                                   ? 1
  //                                   : 0,
  //                       child: RotatedBox(
  //                         quarterTurns:
  //                             gameId != "" && myPlayer != index ? 2 : 0,
  //                         child: Padding(
  //                           padding: const EdgeInsets.only(
  //                               left: 8.0, right: 8.0, bottom: 24),
  //                           child: Column(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               SizedBox(
  //                                 height: 70,
  //                                 child: Text(
  //                                   '${playersScores[index]}',
  //                                   style: TextStyle(
  //                                       fontWeight: FontWeight.bold,
  //                                       fontSize: 60,
  //                                       color: darkMode
  //                                           ? Colors.white.withOpacity(0.5)
  //                                           : Colors.black.withOpacity(0.5)),
  //                                 ),
  //                               ),
  //                               GameTimer(
  //                                 timerStream: timerController.stream,
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ));
  //             }),
  //             ...List.generate(playersSize, (index) {
  //               return Positioned(
  //                 top: index == 0 ||
  //                         (!landScape && index == 1 && playersSize > 2)
  //                     ? 0
  //                     : null,
  //                 bottom: (index == 1 && playersSize == 2) ||
  //                         index == 2 ||
  //                         (!landScape && index == 3)
  //                     ? 0
  //                     : null,
  //                 left: index == 3 || (landScape && index == 0) ? 0 : null,
  //                 right: (index == 1 && playersSize > 2) ||
  //                         (landScape &&
  //                             ((index == 1 && playersSize == 2) || index == 2))
  //                     ? 0
  //                     : null,
  //                 child: RotatedBox(
  //                   quarterTurns: index == 0
  //                       ? 2
  //                       : index == 1 && playersSize > 2
  //                           ? 3
  //                           : index == 3
  //                               ? 1
  //                               : 0,
  //                   child: Container(
  //                     width: (landScape &&
  //                                 ((index == 1 && playersSize > 2) ||
  //                                     index == 3)) ||
  //                             (!landScape &&
  //                                 (index == 0 ||
  //                                     index == 2 ||
  //                                     (index == 1 && playersSize == 2)))
  //                         ? minSize
  //                         : padding,
  //                     alignment: Alignment.center,
  //                     child: RotatedBox(
  //                       quarterTurns: gameId != "" && myPlayer != index ? 2 : 0,
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Text(
  //                             users != null
  //                                 ? users![index]?.username ?? ""
  //                                 : "Player ${index + 1}",
  //                             style: TextStyle(
  //                                 fontSize: 18,
  //                                 color: currentPlayer == index
  //                                     ? Colors.blue
  //                                     : darkMode
  //                                         ? Colors.white
  //                                         : Colors.black),
  //                             textAlign: TextAlign.center,
  //                           ),
  //                           CountWidget(count: playersWhots[index].length)
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }),
  //             ...List.generate(playersSize + 1, (index) {
  //               bool isEdgeTilt = gameId != "" &&
  //                   playersSize > 2 &&
  //                   (myPlayer == 1 || myPlayer == 3);
  //               final value = isEdgeTilt ? !landScape : landScape;
  //               if (index == 0) {
  //                 return Center(
  //                   child: playedWhots.isEmpty || whots.isEmpty
  //                       ? null
  //                       : RotatedBox(
  //                           quarterTurns: currentPlayer == 0 ||
  //                                   (playersSize > 2 &&
  //                                       ((value && currentPlayer == 3) ||
  //                                           (!value && currentPlayer == 1)))
  //                               ? 2
  //                               : 0,
  //                           child: SizedBox(
  //                             height: value ? cardHeight : minSize,
  //                             width: value ? minSize : cardHeight,
  //                             child: ColumnOrRow(
  //                               column: !value,
  //                               mainAxisSize: MainAxisSize.min,
  //                               mainAxisAlignment:
  //                                   MainAxisAlignment.spaceBetween,
  //                               children: [
  //                                 RotatedBox(
  //                                   quarterTurns: currentPlayer == 3 ||
  //                                           (currentPlayer == 1 &&
  //                                               playersSize > 2)
  //                                       ? value
  //                                           ? 3
  //                                           : 1
  //                                       : 0,
  //                                   child: SizedBox(
  //                                     height: cardHeight,
  //                                     width: cardWidth,
  //                                   ),
  //                                 ),
  //                                 RotatedBox(
  //                                   quarterTurns: currentPlayer == 3 ||
  //                                           (currentPlayer == 1 &&
  //                                               playersSize > 2)
  //                                       ? value
  //                                           ? 3
  //                                           : 1
  //                                       : 0,
  //                                   child: Stack(
  //                                     children: [
  //                                       WhotCard(
  //                                         blink: false,
  //                                         height: cardHeight,
  //                                         width: cardWidth,
  //                                         whot: playedWhots.first,
  //                                         isBackCard: false,
  //                                       ),
  //                                       Positioned(
  //                                         top: 8,
  //                                         right: 4,
  //                                         child: CountWidget(
  //                                           count: playedWhots.length,
  //                                           color:
  //                                               Colors.black.withOpacity(0.1),
  //                                           textColor: Colors.black,
  //                                         ),
  //                                       ),
  //                                       if (shapeNeeded != null &&
  //                                           playedWhots.isNotEmpty &&
  //                                           playedWhots.first.number == 20) ...[
  //                                         Positioned(
  //                                           bottom: 4,
  //                                           left: 4,
  //                                           child: WhotCard(
  //                                             blink: false,
  //                                             height: cardWidth / 2,
  //                                             width: cardWidth / 2,
  //                                             whot: Whot(
  //                                                 "", -1, shapeNeeded!.index),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ],
  //                                   ),
  //                                 ),
  //                                 RotatedBox(
  //                                   quarterTurns: currentPlayer == 3 ||
  //                                           (currentPlayer == 1 &&
  //                                               playersSize > 2)
  //                                       ? value
  //                                           ? 3
  //                                           : 1
  //                                       : 0,
  //                                   child: Stack(
  //                                     children: [
  //                                       WhotCard(
  //                                         blink: hintGeneralMarket &&
  //                                             !needShape &&
  //                                             firstTime,
  //                                         height: cardHeight,
  //                                         width: cardWidth,
  //                                         whot: whots.first,
  //                                         isBackCard: true,
  //                                         onPressed: () {
  //                                           if (gameId != "" &&
  //                                               currentPlayerId != myId) {
  //                                             showToast(myPlayer,
  //                                                 "Its ${getUsername(currentPlayerId)}'s turn");
  //                                             return;
  //                                           }

  //                                           if (pickCount >= whots.length) {
  //                                             getNewWhots();
  //                                           } else {
  //                                             if (gameId != "") {
  //                                               updateDetails(-1, -1, "");
  //                                             } else {
  //                                               pickWhot();
  //                                             }
  //                                           }
  //                                         },
  //                                       ),
  //                                       Positioned(
  //                                         top: 8,
  //                                         right: 4,
  //                                         child: CountWidget(
  //                                           count: whots.length,
  //                                           color:
  //                                               Colors.white.withOpacity(0.1),
  //                                           textColor: Colors.white,
  //                                         ),
  //                                       )
  //                                     ],
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                 );
  //               } else {
  //                 index = index - 1;
  //                 if (playersWhots.isEmpty && index > playersWhots.length - 1) {
  //                   return Container();
  //                 }
  //                 return Positioned(
  //                   top: index == 0 ||
  //                           ((index == 1 || index == 3) && playersSize > 2)
  //                       ? 0
  //                       : null,
  //                   bottom: index != 0 ? 0 : null,
  //                   left: playersSize > 2 && index == 1 ? null : 0,
  //                   right: index < 3 ? 0 : null,
  //                   child: RotatedBox(
  //                     quarterTurns: getTurn(index),
  //                     child: Container(
  //                       alignment: Alignment.center,
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           // height: cardWidth / 2,
  //                           //     width: ((cardWidth / 2) * 5) +
  //                           //         (cardWidth.percentValue(5) * 4),
  //                           //     alignment: Alignment.center,
  //                           if (needShape && currentPlayer == index) ...[
  //                             Row(
  //                                 mainAxisAlignment: MainAxisAlignment.center,
  //                                 children: List.generate(5, (index) {
  //                                   return WhotCard(
  //                                       blink: firstTime &&
  //                                           hintPositions.contains(index) &&
  //                                           !awaiting,
  //                                       height: cardWidth / 2,
  //                                       width: cardWidth / 2,
  //                                       whot: Whot("", -1, index),
  //                                       onPressed: () {
  //                                         if (gameId != "" &&
  //                                             currentPlayerId != myId) {
  //                                           showToast(myPlayer,
  //                                               "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
  //                                           return;
  //                                         }
  //                                         if (gameId != "") {
  //                                           updateDetails(-1, index, "");
  //                                         } else {
  //                                           playShape(index);
  //                                         }
  //                                       });
  //                                 }))
  //                           ],
  //                           RotatedBox(
  //                             quarterTurns:
  //                                 gameId != "" && myPlayer != index ? 2 : 0,
  //                             child: StreamBuilder<int>(
  //                                 stream: currentPlayer == index
  //                                     ? timerController.stream
  //                                     : null,
  //                                 builder: (context, snapshot) {
  //                                   return Text(
  //                                     getMessage(index),
  //                                     style: TextStyle(
  //                                       fontWeight: FontWeight.bold,
  //                                       fontSize: 18,
  //                                       color: darkMode
  //                                           ? Colors.white
  //                                           : Colors.black,
  //                                     ),
  //                                     textAlign: TextAlign.center,
  //                                   );
  //                                 }),
  //                           ),
  //                           // Container(
  //                           //   width: minSize,
  //                           //   alignment: (landScape &&
  //                           //               (index == 0 || index == 2)) ||
  //                           //           (!landScape &&
  //                           //               ((index == 1 && playersSize > 2) ||
  //                           //                   index == 3))
  //                           //       ? Alignment.centerLeft
  //                           //       : Alignment.center,
  //                           //   child: StreamBuilder<int>(
  //                           //       stream: currentPlayer == index
  //                           //           ? timerController.stream
  //                           //           : null,
  //                           //       builder: (context, snapshot) {
  //                           //         return Text(
  //                           //           getMessage(index),
  //                           //           style: TextStyle(
  //                           //             fontWeight: FontWeight.bold,
  //                           //             fontSize: 18,
  //                           //             color: darkMode
  //                           //                 ? Colors.white
  //                           //                 : Colors.black,
  //                           //           ),
  //                           //           textAlign: TextAlign.center,
  //                           //         );
  //                           //       }),
  //                           // ),
  //                           Stack(
  //                             alignment: Alignment.center,
  //                             children: [
  //                               Container(
  //                                 height: cardHeight,
  //                                 width: minSize,
  //                                 alignment: Alignment.center,
  //                                 margin: EdgeInsets.only(
  //                                     left: 24,
  //                                     right: 24,
  //                                     bottom: (landScape &&
  //                                                 (index == 1 || index == 3) &&
  //                                                 playersSize > 2) ||
  //                                             (!landScape &&
  //                                                 (index == 0 ||
  //                                                     (index == 2 &&
  //                                                         playersSize > 2) ||
  //                                                     (index == 1 &&
  //                                                         playersSize == 2)))
  //                                         ? 20
  //                                         : 8),
  //                                 child: SizedBox(
  //                                   height: cardHeight,
  //                                   child: ListView.builder(
  //                                       padding: EdgeInsets.zero,
  //                                       shrinkWrap: true,
  //                                       primary: (gameId != "" &&
  //                                               index == myPlayer) ||
  //                                           (gameId == "" &&
  //                                               index == currentPlayer),
  //                                       scrollDirection: Axis.horizontal,
  //                                       itemCount: playersWhots[index].length,
  //                                       itemBuilder: ((context, whotindex) {
  //                                         final whot =
  //                                             playersWhots[index][whotindex];
  //                                         return WhotCard(
  //                                           blink: firstTime &&
  //                                               index == currentPlayer &&
  //                                               hintPositions
  //                                                   .contains(whotindex) &&
  //                                               !needShape &&
  //                                               !awaiting,
  //                                           key: Key(whot.id),
  //                                           height: cardHeight,
  //                                           width: cardWidth,
  //                                           whot: whot,
  //                                           isBackCard:
  //                                               cardVisibilities[index] ==
  //                                                   WhotCardVisibility.turned,
  //                                           onLongPressed: () {
  //                                             flipCards(index);
  //                                           },
  //                                           onPressed: () {
  //                                             if (gameId != "" &&
  //                                                 index != myPlayer) {
  //                                               Fluttertoast.showToast(
  //                                                   msg:
  //                                                       "You can't flip your opponent's card");
  //                                               return;
  //                                             }
  //                                             if (gameId == "" &&
  //                                                 currentPlayer != index) {
  //                                               showToast(index,
  //                                                   "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
  //                                               return;
  //                                             }
  //                                             if (cardVisibilities[index] ==
  //                                                 WhotCardVisibility.turned) {
  //                                               cardVisibilities[index] =
  //                                                   WhotCardVisibility.visible;
  //                                               getHintPositions();
  //                                               setState(() {});
  //                                               return;
  //                                             }
  //                                             if (gameId != "" &&
  //                                                 currentPlayerId != myId) {
  //                                               showToast(myPlayer,
  //                                                   "Its ${getUsername(currentPlayerId)}'s turn");
  //                                               return;
  //                                             }

  //                                             final currentNumber =
  //                                                 playedWhots.first.number;
  //                                             if (currentNumber == 14 &&
  //                                                 pickPlayer != -1 &&
  //                                                 pickPlayer != currentPlayer) {
  //                                               showToast(index,
  //                                                   "Pick General Market");
  //                                               return;
  //                                             }
  //                                             if (currentNumber == 2 &&
  //                                                 pickPlayer != -1 &&
  //                                                 pickPlayer == currentPlayer) {
  //                                               showToast(index,
  //                                                   "Pick 2 From Market");
  //                                               return;
  //                                             }
  //                                             if (gameId != "") {
  //                                               updateDetails(
  //                                                   whotindex, -1, "");
  //                                             } else {
  //                                               playWhot(whotindex);
  //                                             }
  //                                           },
  //                                         );
  //                                       })),
  //                                 ),
  //                               ),
  //                               if (playersToasts[index] != "") ...[
  //                                 Align(
  //                                   alignment: Alignment.bottomCenter,
  //                                   child: AppToast(
  //                                     message: playersToasts[index],
  //                                     onComplete: () {
  //                                       playersToasts[index] = "";
  //                                       setState(() {});
  //                                     },
  //                                   ),
  //                                 ),
  //                               ],
  //                             ],
  //                           ),
  //                           // Row(
  //                           //   mainAxisSize: MainAxisSize.min,
  //                           //   children: [
  //                           //     Text(
  //                           //       users != null
  //                           //           ? users![index]?.username ?? ""
  //                           //           : "Player ${index + 1}",
  //                           //       style: TextStyle(
  //                           //           fontSize: 18,
  //                           //           color: currentPlayer == index
  //                           //               ? Colors.blue
  //                           //               : darkMode
  //                           //                   ? Colors.white
  //                           //                   : Colors.black),
  //                           //       textAlign: TextAlign.center,
  //                           //     ),
  //                           //     CountWidget(
  //                           //         count: playersWhots[index].length)
  //                           //   ],
  //                           // ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 );
  //               }
  //             }),
  //             if (firstTime && !paused && !seenFirstHint) ...[
  //               RotatedBox(
  //                 quarterTurns: gameId != ""
  //                     ? myPlayer == 0
  //                         ? 2
  //                         : myPlayer == 1 && playersSize > 2
  //                             ? 3
  //                             : myPlayer == 3
  //                                 ? 1
  //                                 : 0
  //                     : 0,
  //                 child: Container(
  //                   height: double.infinity,
  //                   width: double.infinity,
  //                   color: lighterBlack,
  //                   alignment: Alignment.center,
  //                   child: GestureDetector(
  //                     behavior: HitTestBehavior.opaque,
  //                     child: const Center(
  //                       child: Text(
  //                           "Tap any card to open\nLong press any card to hide\nPlay a matching card",
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
  //                 quarterTurns: gameId != ""
  //                     ? myPlayer == 0
  //                         ? 2
  //                         : myPlayer == 1 && playersSize > 2
  //                             ? 3
  //                             : myPlayer == 3
  //                                 ? 1
  //                                 : 0
  //                     : 0,
  //                 child: PausedGamePage(
  //                   context: context,
  //                   readAboutGame: readAboutGame,
  //                   game: "Whot",
  //                   playersScores: playersScores,
  //                   users: users,
  //                   playersSize: playersSize,
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
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  String gameName = whotGame;

  @override
  int maxGameTime = 20.minToSec;

  @override
  void onConcede(int index) {
    // TODO: implement onConcede
  }

  @override
  void onDetailsChange(Map<String, dynamic>? map) {
    if (map != null) {
      final details = WhotDetails.fromMap(map);
      played = false;
      pausePlayerTime = false;
      final playPos = details.playPos;
      final shapeNeeded = details.shapeNeeded;
      if (playPos != -1) {
        playWhot(playPos);
      } else {
        if (shapeNeeded != -1) {
          playShape(shapeNeeded);
        } else {
          List<String> indices =
              details.whotIndices == "" ? [] : details.whotIndices.split(",");
          if (indices.isNotEmpty && !whotIndices.equals(indices)) {
            whotIndices = indices;
            if (!finishedRound) {
              pausePlayerTime = false;
              updateNewWhots(indices);
            }
          }
          if (indices.isEmpty) {
            pickWhot();
          }
        }
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
    if (!paused) {
      if (gameId != "" && currentPlayerId != myId) {
        showToast(myPlayer, "Its ${getUsername(currentPlayerId)}'s turn");
        return;
      }
      if (pickCount >= whots.length) {
        getNewWhots();
      } else {
        if (gameId != "") {
          updateDetails(-1, -1, "");
        } else {
          pickWhot();
        }
      }
    }
  }

  @override
  void onStart() {
    if (indices != null) {
      whotIndices = indices!.split(",");
    } else {
      whotIndices = getRandomIndex(54);
    }
    if (gameId == "") {
      whotIndices = getRandomIndex(54);
    } else {
      if (indices != null) {
        whotIndices = indices!.split(",");
      } else {
        if (myId == currentPlayerId) {
          updateDetails(-1, -1, getRandomIndex(54).join(","));
        }
      }
    }
    addInitialWhots();
  }

  @override
  void onPlayerTimeEnd() {
    playIfTimeOut();
    // setState(() {});
  }

  @override
  void onTimeEnd() {
    tenderCards();
  }

  @override
  void onPlayerChange() {
    // TODO: implement onPlayerChange
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (needShape && currentPlayer == index) ...[
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return WhotCard(
                    blink:
                        firstTime && hintPositions.contains(index) && !awaiting,
                    height: cardWidth / 2,
                    width: cardWidth / 2,
                    whot: Whot("", -1, index),
                    onPressed: () {
                      if (gameId != "" && currentPlayerId != myId) {
                        showToast(myPlayer,
                            "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
                        return;
                      }
                      if (gameId != "") {
                        updateDetails(-1, index, "");
                      } else {
                        playShape(index);
                      }
                    });
              }))
        ],
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              primary: (gameId != "" && index == myPlayer) ||
                  (gameId == "" && index == currentPlayer),
              scrollDirection: Axis.horizontal,
              itemCount: playersWhots[index].length,
              itemBuilder: ((context, whotindex) {
                final whot = playersWhots[index][whotindex];
                return WhotCard(
                  blink: firstTime &&
                      index == currentPlayer &&
                      hintPositions.contains(whotindex) &&
                      !needShape &&
                      !awaiting,
                  key: Key(whot.id),
                  height: cardHeight,
                  width: cardWidth,
                  whot: whot,
                  isBackCard:
                      cardVisibilities[index] == WhotCardVisibility.turned,
                  onLongPressed: () {
                    flipCards(index);
                  },
                  onPressed: () {
                    if (gameId != "" && index != myPlayer) {
                      Fluttertoast.showToast(
                          msg: "You can't flip your opponent's card");
                      return;
                    }
                    if (gameId == "" && currentPlayer != index) {
                      showToast(index,
                          "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
                      return;
                    }
                    if (cardVisibilities[index] == WhotCardVisibility.turned) {
                      cardVisibilities[index] = WhotCardVisibility.visible;
                      getHintPositions();
                      setState(() {});
                      return;
                    }
                    if (gameId != "" && currentPlayerId != myId) {
                      showToast(myPlayer,
                          "Its ${getUsername(currentPlayerId)}'s turn");
                      return;
                    }

                    final currentNumber = playedWhots.first.number;
                    if (currentNumber == 14 &&
                        pickPlayer != -1 &&
                        pickPlayer != currentPlayer) {
                      showToast(index, "Pick General Market");
                      return;
                    }
                    if (currentNumber == 2 &&
                        pickPlayer != -1 &&
                        pickPlayer == currentPlayer) {
                      showToast(index, "Pick 2 From Market");
                      return;
                    }
                    if (gameId != "") {
                      updateDetails(whotindex, -1, "");
                    } else {
                      playWhot(whotindex);
                    }
                  },
                );
              })),
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    bool isEdgeTilt =
        gameId != "" && playersSize > 2 && (myPlayer == 1 || myPlayer == 3);
    final value = isEdgeTilt ? !landScape : landScape;
    return Center(
      child: playedWhots.isEmpty || whots.isEmpty
          ? null
          : RotatedBox(
              quarterTurns: currentPlayer == 0 ||
                      (playersSize > 2 &&
                          ((value && currentPlayer == 3) ||
                              (!value && currentPlayer == 1)))
                  ? 2
                  : 0,
              child: SizedBox(
                height: value ? cardHeight : minSize,
                width: value ? minSize : cardHeight,
                child: ColumnOrRow(
                  column: !value,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RotatedBox(
                      quarterTurns: currentPlayer == 3 ||
                              (currentPlayer == 1 && playersSize > 2)
                          ? value
                              ? 3
                              : 1
                          : 0,
                      child: SizedBox(
                        height: cardHeight,
                        width: cardWidth,
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: currentPlayer == 3 ||
                              (currentPlayer == 1 && playersSize > 2)
                          ? value
                              ? 3
                              : 1
                          : 0,
                      child: Stack(
                        children: [
                          WhotCard(
                            blink: false,
                            height: cardHeight,
                            width: cardWidth,
                            whot: playedWhots.first,
                            isBackCard: false,
                          ),
                          Positioned(
                            top: 8,
                            right: 4,
                            child: CountWidget(
                              count: playedWhots.length,
                              color: Colors.black.withOpacity(0.1),
                              textColor: Colors.black,
                            ),
                          ),
                          if (shapeNeeded != null &&
                              playedWhots.isNotEmpty &&
                              playedWhots.first.number == 20) ...[
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: WhotCard(
                                blink: false,
                                height: cardWidth / 2,
                                width: cardWidth / 2,
                                whot: Whot("", -1, shapeNeeded!.index),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: currentPlayer == 3 ||
                              (currentPlayer == 1 && playersSize > 2)
                          ? value
                              ? 3
                              : 1
                          : 0,
                      child: Stack(
                        children: [
                          WhotCard(
                            blink: hintGeneralMarket && !needShape && firstTime,
                            height: cardHeight,
                            width: cardWidth,
                            whot: whots.first,
                            isBackCard: true,
                            onPressed: () {
                              if (gameId != "" && currentPlayerId != myId) {
                                showToast(myPlayer,
                                    "Its ${getUsername(currentPlayerId)}'s turn");
                                return;
                              }

                              if (pickCount >= whots.length) {
                                getNewWhots();
                              } else {
                                if (gameId != "") {
                                  updateDetails(-1, -1, "");
                                } else {
                                  pickWhot();
                                }
                              }
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 4,
                            child: CountWidget(
                              count: whots.length,
                              color: Colors.white.withOpacity(0.1),
                              textColor: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
