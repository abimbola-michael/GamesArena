// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/pages/base_game_page.dart';

import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/card/whot/models/whot.dart';

import '../../../../../shared/extensions/special_context_extensions.dart';
import '../../../../../shared/utils/call_utils.dart';
import '../../../../../shared/widgets/custom_grid.dart';
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

  int startCards = 5;
  WhotCardShape? shapeNeeded;
  bool needShape = false;
  int iNeedCardIndex = -1;

  // int pickCount = 1;
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
    if (needShape && shapeNeeded == null) {
      final index = Random().nextInt(5);
      playShape(index);
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
    if (needShape) {
      for (int i = 0; i < playerWhots.length; i++) {
        final whot = playerWhots[i];
        if (!hintPositions.contains(whot.shape)) {
          hintPositions.add(whot.shape);
        }
      }
    } else {
      final currentWhot = playedWhots.last;
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

  void getHintMessage(bool awaiting) {
    if (awaiting) {
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
        hintMessage = "Play cards that match the awaiting card number or shape";
      }
    }
    setState(() {});
  }

  void shareCards() async {
    if (whots.isEmpty) return;
    for (int i = 0; i < playersSize; i++) {
      playersWhots.add([]);
    }
    pickCards(playersSize * startCards, 1);
    playInitialWhot();
    // awaiting = true;
    // final cardsToShare = (startCards * playersSize) + 1;
    // int j = 0;
    // for (int i = 0; i < cardsToShare; i++) {
    //   if (i < whots.length) {
    //     final whot = whots.first;
    //     if (!seeking) {
    //       await Future.delayed(const Duration(milliseconds: 100));
    //     }
    //     if (i == cardsToShare - 1) {
    //       playWhot(j, -1);
    //     } else {
    //       playersWhots[j].insert(0, whot);
    //       j = j == playersSize - 1 ? 0 : j + 1;
    //     }
    //     whots.removeAt(0);
    //     if (!mounted) return;
    //     setState(() {});
    //   }
    // }
    // awaiting = false;
    // pausePlayerTime = false;

    message = "";
    setState(() {});
  }

  Future pickCards(int rounds, int count, [int duration = 1000]) async {
    for (int i = 0; i < rounds; i++) {
      pickWhot(count, false, null, false);
    }
  }

  void playInitialWhot() {
    final whot = whots.last;
    playedWhots.add(whot);

    changePlayer();

    showActivePlayersMessages("");

    if (whot.number == 14) {
      showActivePlayersMessages("General Market", currentPlayer);

      pickCards(playersSize - 1, 1);
    } else if (whot.number == 2) {
      showPlayerMessage(currentPlayer, "Pick 2");

      pickCards(1, 2);
    } else if (whot.number == 1 || whot.number == 8) {
      showPlayerMessage(
          currentPlayer, whot.number == 1 ? "Hold On" : "Suspension");
      changePlayer();
      showPlayerMessage(currentPlayer, "Continue");
    } else if (whot.number == 20) {
      showPlayerMessage(currentPlayer, "Select Card shape");
      needShape = true;
    }

    // if (whot.number == 14) {
    //   showActivePlayersMessages("General Market", currentPlayer);

    //   pickCards(playersSize, 1);
    // } else if (whot.number == 2) {
    //   showPlayerMessage(currentPlayer, "Pick 2");

    //   pickCards(1, 2);
    // } else if (whot.number == 1 || whot.number == 8) {
    //   showPlayerMessage(
    //       currentPlayer, whot.number == 1 ? "Hold On" : "Suspension");
    //   print("beforecurrentPlayer = $currentPlayer");

    //   changePlayer();
    //   showPlayerMessage(currentPlayer, "Continue");
    //   print("aftercurrentPlayer = $currentPlayer");
    // } else if (whot.number == 20) {
    //   showPlayerMessage(currentPlayer, "Select Card shape");
    //   getHintPositions();
    //   needShape = true;
    // }

    setState(() {});
  }

  void playWhot(int player, int index, [bool isClick = true]) {
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

    if (playedWhots.isEmpty) return;
    final currentWhot = playedWhots.last;
    final whot = playersWhots[currentPlayer][index];

    if (needShape) {
      showPlayerToast(
          currentPlayer, "You are to select a shape you need above");
      return;
    }
    if (shapeNeeded != null && whot.number != 20) {
      if (shapeNeeded!.index != whot.shape) {
        showPlayerToast(
            currentPlayer, "Shape doesn't match ${shapeNeeded!.name}");
        return;
      }
    } else {
      if (whot.number != 20 &&
          currentWhot.number != whot.number &&
          currentWhot.shape != whot.shape) {
        showPlayerToast(currentPlayer, "Whot doesn't match shape or number");
        return;
      }
    }

    playedWhots.add(whot);
    playersWhots[currentPlayer].removeAt(index);
    updateCount(currentPlayer, playersWhots[currentPlayer].length);

    int prevPlayer = currentPlayer;

    if (whot.number != 20) {
      if (isClick) updateDetails(index);
      checkWinGame();
      changePlayer();
    }
    showActivePlayersMessages("");

    if (shapeNeeded != null) {
      shapeNeeded = null;
    }

    if (whot.number == 14) {
      showActivePlayersMessages("General Market", prevPlayer);

      pickCards(playersSize - 1, 1);
    } else if (whot.number == 2) {
      showPlayerMessage(currentPlayer, "Pick 2");

      pickCards(1, 2);
    } else if (whot.number == 1 || whot.number == 8) {
      showPlayerMessage(
          currentPlayer, whot.number == 1 ? "Hold On" : "Suspension");
      changePlayer();
      showPlayerMessage(currentPlayer, "Continue");
    } else if (whot.number == 20) {
      showPlayerMessage(currentPlayer, "Select Card shape");
      needShape = true;
      iNeedCardIndex = index;
    }
    // print("prevPlayer = $prevPlayer, currentPlayer = $currentPlayer");

    if (gameId.isEmpty && currentPlayer != prevPlayer) {
      hideCards();
    }

    showPossiblePlayPositions();

    setState(() {});
  }

  void playShape(int index, [bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;

    shapeNeeded = whotCardShapes[index];

    needShape = false;
    if (isClick) updateINeedDetails(iNeedCardIndex, index);
    iNeedCardIndex = -1;
    changePlayer();
    showActivePlayersMessages("");

    showPlayerMessage(currentPlayer, "I need ${shapeNeeded!.name}");

    showPossiblePlayPositions();
    setState(() {});
  }

  void pickWhot(
      [int pickCount = 1,
      bool isMe = true,
      String? whotIndices,
      bool isClick = true]) async {
    if (!itsMyTurnToPlay(isClick)) return;
    //awaiting

    if (!mounted || whots.isEmpty) return;

    if (pickCount >= whots.length) {
      final lastPlayedWhot = playedWhots.last;
      List<Whot> otherPlayedWhots = [];
      if (whotIndices != null) {
        otherPlayedWhots = (jsonDecode(whotIndices) as List)
            .map((e) => Whot.fromJson(e))
            .toList();
      } else {
        otherPlayedWhots = playedWhots
            .where((element) => element.id != lastPlayedWhot.id)
            .toList();
        otherPlayedWhots.shuffle();
        if (isClick) {
          updateDetails(-1, jsonEncode(otherPlayedWhots));
        }
      }

      playedWhots = [lastPlayedWhot];
      whots.addAll(otherPlayedWhots);
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

      final whot = whots.last;
      playersWhots[currentPlayer].insert(0, whot);
      whots.removeLast();
      updateCount(currentPlayer, playersWhots[currentPlayer].length);
    }

    changePlayer();
    if (isMe) {
      showActivePlayersMessages("");
      showPlayerMessage(currentPlayer, "I pick, Play");
    }

    if (shapeNeeded != null) {
      showPlayerMessage(currentPlayer, "I need ${shapeNeeded!.name}");
    }

    hastLastCard = false;
    showPossiblePlayPositions();
    // if (gameId.isEmpty) {
    //   hideCards();
    // }
    setState(() {});
  }

//   void playWhot(int player, int index, [bool isClick = true]) async {
//     if (index != -1 && isClick) {
//       if (cardVisibilities[player] == WhotCardVisibility.turned) {
//         if (gameId.isNotEmpty && player != myPlayer && !finishedRound) {
//           showToast("You can't flip your opponent's card");
//           return;
//         }
//         cardVisibilities[player] = WhotCardVisibility.visible;
//         getHintPositions();
//         setState(() {});
//         return;
//       }
//       if (!itsMyTurnToPlay(isClick, player)) return;

//       final currentNumber = playedWhots.first.number;
//       if (currentNumber == 14 &&
//           pickPlayer != -1 &&
//           pickPlayer != currentPlayer) {
//         showPlayerToast(index, "Pick General Market");
//         return;
//       }

//       if (currentNumber == 2 &&
//           pickPlayer != -1 &&
//           pickPlayer == currentPlayer) {
//         showPlayerToast(index, "Pick 2 From Market");
//         return;
//       }

//       if (needShape && index != -1) {
//         showPlayerToast(currentPlayer, "Select shape");
//         return;
//       }
//     }

//     Whot whot = index == -1 ? whots.first : playersWhots[currentPlayer][index];
//     final currentWhot = playedWhots.isEmpty ? whots.first : playedWhots.first;
//     if (shapeNeeded != null &&
//         shapeNeeded != whotCardShapes[whot.shape] &&
//         whot.number != 20 &&
//         index != -1) {
//       showPlayerToast(currentPlayer,
//           "This is not ${shapeNeeded!.name}\n Go to Market if you don't have");
//       return;
//     }

//     final next = nextPlayer();
//     final prev = prevPlayer();
//     final next2 = nextPlayer(true);
//     //final prev2 = prevPlayer(true);
//     if (currentWhot.number == whot.number ||
//         currentWhot.shape == whot.shape ||
//         whot.number == 20 ||
//         (shapeNeeded != null && shapeNeeded == whotCardShapes[whot.shape])) {
//       //making sure the cards match
//       final number = whot.number;
//       if (index != -1) {
//         // if (playedWhots.isNotEmpty && playedWhots.first.number == 1) {
//         //   for (int i = 0; i < playersSize; i++) {
//         //     if (i != currentPlayer) {
//         //       playersMessages[i] = playersMessages[i].replaceAll("Hold On", "");
//         //     }
//         //   }
//         // }
//         playedWhots.insert(0, whot);
//         final currentPlayerWhots = playersWhots[currentPlayer];
//         if (currentPlayerWhots.isNotEmpty) {
//           currentPlayerWhots.removeAt(index);
//         }
//         updateCount(currentPlayer, currentPlayerWhots.length);
//       } else {
//         playedWhots.add(whot);
//       }

//       playersMessages[currentPlayer] = "";
//       playersMessages[prev] = "";

//       String lastMessage = "";
//       hastLastCard = false;
//       // if (playersWhots[currentPlayer].length == 2) {
//       //   lastMessage = "Semi Last Card ";
//       //   hastLastCard = true;
//       // } else
//       if (playersWhots[currentPlayer].length == 1) {
//         lastMessage = "Last Card ";
//         hastLastCard = true;
//       } else if (playersWhots[currentPlayer].isEmpty) {
//         if (number != 1 &&
//             number != 8 &&
//             number != 14 &&
//             number != 2 &&
//             number != 20) {
//           lastMessage = "Check Up";
//         }
//       }
//       // if (lastMessage != "") {
//       //   if (playersSize > 2) {
//       //     lastMessage +=
//       //         ": ${users != null ? "${users![currentPlayer]?.username ?? ""}\n" : "${currentPlayer + 1}"}\n";
//       //   } else {
//       //     lastMessage += "\n";
//       //   }
//       // }

//       if (number == 1 || number == 8 || number == 14 || number == 2) {
//         String nextMessage = number == 1
//             ? "Hold On"
//             : number == 8
//                 ? "Suspension"
//                 : number == 2
//                     ? "Pick 2"
//                     : "General Market";
//         if (number == 14) {
//           pickCount = 1;
//           pickPlayer = currentPlayer;
//         } else if (number == 2) {
//           pickCount = 2;
//           pickPlayer = next;
//         }
// // || number == 1
//         if (number == 14) {
//           for (int i = 0; i < playersSize; i++) {
//             if (i != currentPlayer) {
//               playersMessages[i] = "$lastMessage$nextMessage";
//             }
//             // else {
//             //   if (number == 1) {
//             //     playersMessages[currentPlayer] += "Continue";
//             //   }
//             // }
//           }
//         } else {
//           playersMessages[next] = "";
//           playersMessages[next2] = "";
//           if (lastMessage != "") {
//             for (int i = 0; i < playersSize; i++) {
//               if (i != currentPlayer) {
//                 playersMessages[i] = lastMessage;
//               }
//             }
//           }
//           playersMessages[next] += nextMessage;
//           if (number == 8 || number == 1) {
//             playersMessages[next2] += "Continue";
//           }
//         }
//       } else {
//         if (lastMessage != "") {
//           for (int i = 0; i < playersSize; i++) {
//             if (i != currentPlayer) {
//               playersMessages[i] = lastMessage;
//             }
//           }
//         }
//         needShape = number == 20;
//         if (index != -1 && number != 20) {
//           checkWinGame();
//         }
//       }

//       if (shapeNeeded != null && shapeNeeded == whotCardShapes[whot.shape]) {
//         needShape = false;
//         shapeNeeded = null;
//       }
// // || number == 1

//       if (number == 20) {
//         iNeedCardIndex = index;
//         //resetPlayerTime();
//         if (index == -1) {
//           showPossiblePlayPositions();
//         } else {
//           getHintPositions();
//         }
//       } else {
//         if (isClick) {
//           updateDetails(index);
//         }
//         changePlayer(suspend: number == 8 || number == 1);
//         showPossiblePlayPositions();
//       }
//       // if (gameId.isEmpty && (playersSize != 2 || (number != 8 && number != 1))) {
//       //   hideCards();
//       // }
//       if (gameId.isEmpty && number != 8 && number != 1 && number != 20) {
//         hideCards();
//       }

//       hintGeneralMarket = number == 2 || number == 14;
//       awaiting = false;
//       setState(() {});
//     } else {
//       showPlayerToast(currentPlayer, "Cards Don't Match");
//     }
//   }

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
    if (needShape && shapeNeeded == null || isWatch) return;
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

  void initWhots([bool isUpdate = true, String? whotIndices]) async {
    setInitialCount(startCards);

    //getCurrentPlayer();
    iNeedCardIndex = -1;
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
      newWhots.shuffle();
      whots.addAll(newWhots);
      if (isUpdate) {
        updateInitalWhotDetails(jsonEncode(whots));
      }
    }

    shareCards();
  }

  Future updateInitalWhotDetails(String whotIndices) async {
    final details = WhotDetails(whotIndices: whotIndices);

    await setDetail(details.toMap());
  }

  Future updateINeedDetails(int playPos, int shapePos) async {
    final details = WhotDetails(playPos: playPos, shapePos: shapePos);

    await setDetail(details.toMap());
  }

  Future updateDetails(int playPos, [String? whotIndices]) async {
    final details = WhotDetails(playPos: playPos, whotIndices: whotIndices);

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

      final whotIndices = details.whotIndices;
      final playerIndex = getPlayerIndex(map["id"]);
      //final shapeNeeded = details.shapeNeeded;
      if (playPos == null) {
        if (whotIndices != null) {
          initWhots(false, whotIndices);
        }
      } else if (playPos == -1) {
        pickWhot(1, true, whotIndices, false);
      } else {
        playWhot(playerIndex, playPos, false);
        if (shapePos != null) {
          playShape(shapePos, false);
        }

        // if (needShape) {
        //   playShape(playPos, false);
        // } else {
        //   playWhot(currentPlayer, playPos, false);
        // }
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
    if (whots.isEmpty || playersWhots.isEmpty) {
      return Container();
    }
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          // primary: (gameId != "" && index == myPlayer) ||
          //     (gameId == "" && index == currentPlayer),
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
              isBackCard: cardVisibilities[index] == WhotCardVisibility.turned,
              onLongPressed: () {
                flipCards(index);
              },
              onPressed: () {
                playWhot(index, whotindex);
              },
            );
          })),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    // print("gameDetails = $gameDetails");
    bool isEdgeTilt =
        gameId != "" && playersSize > 2 && (myPlayer == 1 || myPlayer == 3);
    final value = isEdgeTilt ? !landScape : landScape;
    return Center(
      child: playedWhots.isEmpty || whots.isEmpty || playersWhots.isEmpty
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
                            whot: playedWhots.last,
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
                              playedWhots.last.number == 20) ...[
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
                      child: needShape
                          ? SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: Wrap(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(5, (index) {
                                    return WhotCard(
                                        blink: firstTime &&
                                            hintPositions.contains(index) &&
                                            !awaiting,
                                        height: (cardHeight / 3),
                                        width: (cardWidth / 2),
                                        margin: 0,
                                        whot: Whot("", -1, index),
                                        onPressed: () {
                                          playShape(index);
                                        });
                                  })),
                            )
                          : Stack(
                              children: [
                                WhotCard(
                                  blink: hintGeneralMarket &&
                                      !needShape &&
                                      firstTime,
                                  height: cardHeight,
                                  width: cardWidth,
                                  whot: whots.last,
                                  isBackCard: true,
                                  onPressed: () {
                                    pickWhot();
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

  @override
  void onDispose() {
    // TODO: implement onDispose
  }

  @override
  void onInitState() {
    // TODO: implement onInitState
  }
}
