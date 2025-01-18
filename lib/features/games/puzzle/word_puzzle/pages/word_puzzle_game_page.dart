import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/games/puzzle/word_puzzle/widgets/match_lines_paint.dart';
import 'package:gamesarena/features/games/puzzle/word_puzzle/widgets/word_puzzle_tile.dart';
import 'package:gamesarena/shared/widgets/app_container.dart';
import 'package:gamesarena/features/games/puzzle/word_puzzle/models/match_line.dart';
import 'package:gamesarena/features/games/puzzle/word_puzzle/models/word_puzzle.dart';
import 'package:gamesarena/features/game/pages/base_game_page.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:word_generator/word_generator.dart';

import '../../../../../enums/emums.dart';
import '../../../../../shared/utils/call_utils.dart';
import '../../../../game/models/game_action.dart';

class WordPuzzleGamePage extends BaseGamePage {
  static const route = "/wordpuzzle";
  final Map<String, dynamic> args;
  final CallUtils callUtils;
  final void Function(GameAction gameAction) onActionPressed;
  const WordPuzzleGamePage(this.args, this.callUtils, this.onActionPressed,
      {super.key})
      : super(args, callUtils, onActionPressed);

  @override
  ConsumerState<BaseGamePage> createState() => WordPuzzleGamePageState();
}

class WordPuzzleGamePageState extends BaseGamePageState<WordPuzzleGamePage> {
  int gridSize = 15;

  List<ChessDirection> diagonalDirections = [
    ChessDirection.topLeft,
    ChessDirection.topRight,
    ChessDirection.bottomLeft,
    ChessDirection.bottomRight
  ];
  List<ChessDirection> edgeDirections = [
    ChessDirection.top,
    ChessDirection.right,
    ChessDirection.left,
    ChessDirection.bottom
  ];
  List<int> hintPositions = [];
  List<List<WordPuzzle>> playersWordPuzzles = [];
  List<List<String>> playersWords = [];
  List<List<MatchLine>> playersMatchLines = [];
  List<int?> playersSelectedPos = [];
  List<int?> playersPos = [];

  List<WordPuzzle> wordPuzzles = [];
  List<String> words = [];
  List<MatchLine> draggedMatchLines = [];

  int wordsLength = 20;

  String getRandomWord(List<String> words) {
    final generator = WordGenerator();
    String word = generator.randomVerb().toUpperCase();
    while (word.length < 6 || word.length > 12 || words.contains(word)) {
      word = generator.randomVerb().toUpperCase();
    }
    return word;
  }

  List<String> generateRandomWords() {
    List<String> words = [];
    for (int i = 0; i < wordsLength; i++) {
      words.add(getRandomWord(words));
    }
    return words;
  }

  Map<String, String> getWordMap(
      Map<String, String> charMap, String word, int wordIndex) {
    LineDirection direction = LineDirection.horizontal;
    if (word.length <= 8) {
      direction =
          LineDirection.values[Random().nextInt(LineDirection.values.length)];
    }
    Map<String, String> newMap = {};
    final rand = Random();
    final length = word.length;
    //final halfSize = gridSize ~/ 2;
    final xSize = gridSize;
    final ySize = gridSize;

    int startX = rand.nextInt(xSize);
    int startY = rand.nextInt(ySize);
    if (direction == LineDirection.horizontal) {
      if (startX + length > xSize) {
        if (startX - length < -1) {
          return {};
        } else {
          startX = startX - length + 1;
        }
      }
    } else if (direction == LineDirection.vertical) {
      if (startY + length > ySize) {
        if (startY - length < -1) {
          return {};
        } else {
          startY = startY - length + 1;
        }
      }
    } else if (direction == LineDirection.upperDiagonal) {
      if (startY + length > ySize || startX + length > xSize) {
        if (startY - length < -1 || startX - length < -1) {
          return {};
        } else {
          startY = startY - length + 1;
          startX = startX - length + 1;
        }
      }
    } else if (direction == LineDirection.lowerDiagonal) {
      if (startY + length > ySize || startX - length < -1) {
        if (startY - length < -1 || startX + length > xSize) {
          return {};
        } else {
          startY = startY - length + 1;
          startX = startX + length - 1;
        }
      }
    }
    // trying to reverse the chars
    bool reverse = rand.nextBool();
    Offset start = Offset.zero;
    Offset end = Offset.zero;

    // updating the char in the right x and y position
    for (int i = 0; i < length; i++) {
      final j = reverse ? length - i - 1 : i;
      final char = word[i];
      int x = 0;
      int y = 0;
      if (direction == LineDirection.horizontal) {
        y = startY;
        x = startX + j;
      } else if (direction == LineDirection.vertical) {
        x = startX;
        y = startY + j;
      } else if (direction == LineDirection.upperDiagonal) {
        x = startX + j;
        y = startY + j;
      } else if (direction == LineDirection.lowerDiagonal) {
        x = startX - j;
        y = startY + j;
      }
      final key = "$x:$y";
      if (charMap[key] != null && charMap[key] != char) {
        return {};
      } else {
        newMap[key] = char;
      }
      if (j == 0) {
        start = Offset(x.toDouble(), y.toDouble());
      } else if (j == word.length - 1) {
        end = Offset(x.toDouble(), y.toDouble());
      }
    }

    // if (currentPlayer == 0 && playersMatchLines.isNotEmpty) {
    //   playersMatchLines[currentPlayer].add(
    //     MatchLine(
    //       start: start,
    //       end: end,
    //       player: currentPlayer,
    //       wordIndex: wordIndex,
    //     ),
    //   );
    // }

    return newMap;
  }

  void addWordToGrid(String word, Map<String, String> charMap, int wordIndex) {
    int trialCount = 1000;
    int newWordCount = trialCount;
    while (newWordCount > 0) {
      int count = trialCount;
      while (count > 0) {
        final result = getWordMap(charMap, word, wordIndex);
        if (result.isNotEmpty) {
          charMap.addAll(result);
          break;
        }
        count--;
      }
      if (count > 0) break;

      final newWord = getRandomWord(words);
      words[wordIndex] = newWord;

      word = newWord;

      newWordCount--;
    }

    if (newWordCount <= 0) {
      //print("newWordCount = $newWordCount, newGrid");
      initGrids();
    }
  }

  List<WordPuzzle> generateWordPuzzles(List<String> words) {
    List<WordPuzzle> wordPuzzles = [];
    Map<String, String> playerCharMap = {};

    for (int i = 0; i < words.length; i++) {
      addWordToGrid(words[i], playerCharMap, i);
    }

    final rand = Random();
    //final halfSize = gridSize ~/ 2;

    for (int colindex = 0; colindex < gridSize; colindex++) {
      //final List<WordPuzzle> puzzles = [];

      for (int rowindex = 0; rowindex < gridSize; rowindex++) {
        final pos = convertToPosition([rowindex, colindex], gridSize);
        String char = playerCharMap["$rowindex:$colindex"] ??
            String.fromCharCode(rand.nextInt(26) + 65);
        wordPuzzles
            .add(WordPuzzle(x: rowindex, y: colindex, char: char, pos: pos));
      }
      //wordPuzzles.add(puzzles);
    }
    return wordPuzzles;
  }

  void initGrids({String? wordsJson, String? puzzlesJson}) async {
    showMessage = false;
    playersWordPuzzles.clear();
    playersMatchLines.clear();
    playersWords.clear();
    playersSelectedPos.clear();
    playersPos.clear();

    draggedMatchLines.clear();

    for (int i = 0; i < playersSize; i++) {
      playersMatchLines.add([]);
      playersSelectedPos.add(null);
      playersPos.add(null);
    }

    if (wordsJson != null && puzzlesJson != null) {
      words = List<String>.from(jsonDecode(wordsJson));
      wordPuzzles = (jsonDecode(puzzlesJson) as List)
          .map((e) => WordPuzzle.fromJson(e))
          .toList();
    } else {
      words = generateRandomWords();
      wordPuzzles = generateWordPuzzles(words);

      updateGridDetails(jsonEncode(words), jsonEncode(wordPuzzles));
    }

    for (int i = 0; i < playersSize; i++) {
      playersWordPuzzles.add([...wordPuzzles]);
      playersWords.add([...words]);
      updateCount(i, words.length);
    }

    if (!mounted) return;
    setState(() {});
  }

  Future updateGridDetails(String words, String puzzles) async {
    final details = WordPuzzleDetails(words: words, puzzles: puzzles);
    await setDetail(details.toMap());
  }

  Future updateDetails(int playPos) async {
    final details = WordPuzzleDetails(
        startPos: playersSelectedPos[currentPlayer], endPos: playPos);
    await setDetail(details.toMap(), add: false);
  }

  String getWord(Offset start, Offset end) {
    String word = "";
    final xDiff = (end.dx - start.dx).toInt();
    final yDiff = (end.dy - start.dy).toInt();
    final range = xDiff.abs() > yDiff.abs() ? xDiff.abs() : yDiff.abs();

    for (int i = 0; i <= range; i++) {
      final dx = xDiff == 0
          ? start.dx
          : xDiff.isNegative
              ? start.dx - i
              : start.dx + i;
      final dy = yDiff == 0
          ? start.dy
          : yDiff.isNegative
              ? start.dy - i
              : start.dy + i;

      //getting chars at positions

      final pos = convertToPosition([dx.toInt(), dy.toInt()], gridSize);
      final char = wordPuzzles[pos].char;
      word += char;
    }
    return word;
  }

  // int getTouchPos(Offset offset) {
  //   //final halfSize = gridSize ~/ 2;
  //   final xSize = gridSize;
  //   final ySize = gridSize;

  //   final dx = offset.dx > context.minSize
  //       ? context.minSize
  //       : offset.dx < 0
  //           ? 0
  //           : offset.dx;
  //   final dy = offset.dy > (context.minSize / 2)
  //       ? (context.minSize / 2)
  //       : offset.dy < 0
  //           ? 0
  //           : offset.dy;

  //   int x = ((dx / context.minSize) * xSize).floor();
  //   int y = ((dy / (context.minSize / 2)) * ySize).floor();
  //   if (x >= xSize) {
  //     x = xSize - 1;
  //   }
  //   if (y >= ySize) {
  //     y = ySize - 1;
  //   }
  //   final pos = convertToPosition([x, y], gridSize);
  //   return pos;
  // }

  // int getTouchPos(Offset offset) {
  //   //final halfSize = gridSize ~/ 2;
  //   final xSize = gridSize;
  //   final ySize = gridSize;

  //   final dx = offset.dx > context.minSize
  //       ? context.minSize
  //       : offset.dx < 0
  //           ? 0
  //           : offset.dx;
  //   final dy = offset.dy > (context.minSize / 2)
  //       ? (context.minSize / 2)
  //       : offset.dy < 0
  //           ? 0
  //           : offset.dy;

  //   int x = ((dx / context.minSize) * xSize).floor();
  //   int y = ((dy / (context.minSize / 2)) * ySize).floor();
  //   if (x >= xSize) {
  //     x = xSize - 1;
  //   }
  //   if (y >= ySize) {
  //     y = ySize - 1;
  //   }
  //   final pos = convertToPosition([x, y], gridSize);
  //   return pos;
  // }
  int getTouchPos(Offset offset) {
    final xSize = gridSize;
    final ySize = gridSize;

    final dx = offset.dx > context.minSize
        ? context.minSize
        : offset.dx < 0
            ? 0
            : offset.dx;
    final dy = offset.dy > context.minSize
        ? context.minSize
        : offset.dy < 0
            ? 0
            : offset.dy;

    int x = ((dx / context.minSize) * xSize).floor();
    int y = ((dy / context.minSize) * ySize).floor();
    if (x >= xSize) {
      x = xSize - 1;
    }
    if (y >= ySize) {
      y = ySize - 1;
    }
    final pos = convertToPosition([x, y], gridSize);
    return pos;
  }

  void startDrawingLine(DragStartDetails details, int player) {
    if (playersSelectedPos.isEmpty) return;
    playersSelectedPos[player] = null;
    playersPos[player] = null;

    final startOffset = details.localPosition;
    final pos = getTouchPos(startOffset);
    playersPos[player] = pos;
    playChar(pos, player, true);
  }

  void updateDrawingLine(DragUpdateDetails details, int player) {
    if (playersPos.isEmpty) return;

    final currentOffset = details.localPosition;
    final pos = getTouchPos(currentOffset);
    if (playersPos[player] != pos) {
      playersPos[player] = pos;

      playChar(pos, player, true);
    }
  }

  void endDrawingLine(DragEndDetails details, int player) {
    if (playersPos.isEmpty) return;

    final pos = playersPos[player];
    if (pos != null) {
      playChar(pos, player, false);
    }
  }

  // int getWordIndex(int player, String word) {
  //   return words.indexWhere((element) => element == word);
  // }

  // void replaceIfFaster(int endPos, int player, String? time) {
  //   final startPos = player == 0 ? player1SelectedPos : player2SelectedPos;
  //   if (startPos == null || time == null) return;
  //   if (gameDetails != null &&
  //       gameDetails!.isNotEmpty &&
  //       gameDetails!.last["startPos"] == startPos &&
  //       gameDetails!.last["endPos"] == endPos &&
  //       int.parse(time) < int.parse(gameDetails!.last["time"])) {
  //     final startPositions = convertToGrid(startPos, gridSize);
  //     final endPositions = convertToGrid(endPos, gridSize);
  //     final startOffet =
  //         Offset(startPositions[0].toDouble(), startPositions[1].toDouble());
  //     final endOffset =
  //         Offset(endPositions[0].toDouble(), endPositions[1].toDouble());

  //     final lineIndex = matchLines.indexWhere(
  //         (element) => element.start == startOffet && element.end == endOffset);
  //     if (lineIndex != -1) {
  //       final matchLine = matchLines[lineIndex];

  //       if (matchLine.player == 0) {
  //         final word = player1Words[matchLine.wordIndex];
  //         player1Words.remove(word);
  //         player2Words.add(word);
  //       } else {
  //         final word = player2Words[matchLine.wordIndex];
  //         player2Words.remove(word);
  //         player1Words.add(word);
  //       }
  //       matchLines[lineIndex].player = player;
  //     }
  //   }
  // }

  void playChar(int pos, int player, bool dragging,
      [bool isClick = true, String? time]) async {
    if (!itsMyTurnToPlay(isClick)) return;
    final matchLines = playersMatchLines[player];
    final coordinates = convertToGrid(pos, gridSize);

    final offset = Offset(coordinates[0].toDouble(), coordinates[1].toDouble());

    Offset? selectedOffset;

    final selectedPos = playersSelectedPos[player];
    if (selectedPos != null) {
      final selectedCoordinates = convertToGrid(selectedPos, gridSize);
      selectedOffset = Offset(
          selectedCoordinates[0].toDouble(), selectedCoordinates[1].toDouble());
    }

    if (selectedOffset == null) {
      playersSelectedPos[player] = pos;
      getHintPositions(pos);

      if (dragging) {
        draggedMatchLines.add(
          MatchLine(
              start: Offset(offset.dx, offset.dy),
              end: Offset(offset.dx, offset.dy),
              player: player,
              wordIndex: -1),
        );
      }
    } else {
      if (selectedOffset != offset) {
        final xDiff = (offset.dx - selectedOffset.dx).toInt().abs();
        final yDiff = (offset.dy - selectedOffset.dy).toInt().abs();
        if (xDiff == yDiff || xDiff == 0 || yDiff == 0) {
          if (dragging) {
            final matchLineIndex = draggedMatchLines.indexWhere((line) =>
                line.player == player && line.start == selectedOffset);
            if (matchLineIndex != -1) {
              draggedMatchLines[matchLineIndex] = MatchLine(
                start: Offset(selectedOffset.dx, selectedOffset.dy),
                end: Offset(offset.dx, offset.dy),
                player: player,
                wordIndex: -1,
              );
            } else {
              draggedMatchLines.add(MatchLine(
                start: Offset(offset.dx, offset.dy),
                end: Offset(offset.dx, offset.dy),
                player: player,
                wordIndex: -1,
              ));
            }
          } else {
            final matchLineIndex = matchLines.indexWhere((line) =>
                line.player == player &&
                line.start == selectedOffset &&
                line.end == offset);
            if (matchLineIndex != -1) {
              if (!dragging) {
                showPlayerToast(player, "Word already found! Try another");
              }
            } else {
              final word = getWord(selectedOffset, offset);
              final words = playersWords[player];

              if (words.contains(word)) {
                if (isClick) {
                  updateDetails(pos);
                }

                matchLines.add(
                  MatchLine(
                    start: Offset(selectedOffset.dx, selectedOffset.dy),
                    end: Offset(offset.dx, offset.dy),
                    player: player,
                    wordIndex: words.indexOf(word),
                  ),
                );
                words.remove(word);
                updateCount(player, words.length);
                if (words.isEmpty) {
                  updateWin(player);
                }
                // if (isPlayerOne) {
                //   player1Words.add(word);
                //   //updateCount(player, player1Words.length);
                // } else {
                //   player2Words.add(word);
                //   //updateCount(player, player2Words.length);
                // }
                //incrementCount(player);
              } else {
                if (!dragging) {
                  showPlayerToast(player, "Invalid word! Try again");
                }
              }
            }
          }
        } else {
          if (!dragging) {
            showPlayerToast(player,
                "Wrong Direction! Can only go vertically, horizontally and diagonally");
          }
        }
      }

      if (!dragging && draggedMatchLines.isNotEmpty) {
        final matchLineIndex = draggedMatchLines.indexWhere(
            (line) => line.player == player && line.start == selectedOffset);
        if (matchLineIndex != -1) {
          draggedMatchLines.removeAt(matchLineIndex);
        }
      }
      if (!dragging) {
        playersSelectedPos[player] = null;
        hintPositions.clear();
      }
    }
    setState(() {});
  }

  // void checkWinner() {
  //   if (player1Words.length > player2Words.length) {
  //     updateWin(0);
  //   } else if (player2Words.length > player1Words.length) {
  //     updateWin(1);
  //   } else {
  //     updateDraw();
  //   }
  //   // if (player1Words.isEmpty) {
  //   //   updateWin(0);
  //   // } else if (player2Words.isEmpty) {
  //   //   updateWin(1);
  //   // } else {
  //   //   updateDraw();
  //   // }
  // }

  void getHintMessage() {
    if (!firstTime) return;

    hintMessage =
        "Tap on any grid to play till you have a complete word match that contains your words in any direction";
    message = hintMessage;
    setState(() {});
  }

  bool exceedRange(int x, int y) =>
      x > gridSize - 1 || x < 0 || y > gridSize - 1 || y < 0;

  void getHintPositions(int pos) {
    hintPositions.clear();
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];

    List<ChessDirection> directions = [
      ...edgeDirections,
      ...diagonalDirections
    ];

    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];

      for (int j = 1; j < gridSize; j++) {
        int newX = direction == ChessDirection.topRight ||
                direction == ChessDirection.bottomRight ||
                direction == ChessDirection.right
            ? x + j
            : direction == ChessDirection.topLeft ||
                    direction == ChessDirection.bottomLeft ||
                    direction == ChessDirection.left
                ? x - j
                : x;
        int newY = direction == ChessDirection.bottomRight ||
                direction == ChessDirection.bottomLeft ||
                direction == ChessDirection.bottom
            ? y + j
            : direction == ChessDirection.topRight ||
                    direction == ChessDirection.topLeft ||
                    direction == ChessDirection.top
                ? y - j
                : y;
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);

        hintPositions.add(pos);
      }
    }
  }

  @override
  int? maxGameTime;

  @override
  int? maxPlayerTime;
  @override
  Future onDetailsChange(Map<String, dynamic>? map) async {
    if (map != null) {
      final details = WordPuzzleDetails.fromMap(map);
      final startPos = details.startPos;
      final endPos = details.endPos;
      final words = details.words;
      final puzzles = details.puzzles;
      final time = map["time"];
      final playerId = map["id"];
      final player = gameId.isEmpty ? 0 : getPlayerIndex(playerId);

      if (words != null && puzzles != null) {
        initGrids(wordsJson: words, puzzlesJson: puzzles);
      } else if (startPos != null && endPos != null) {
        playChar(startPos, player, false, false, time);
        playChar(endPos, player, false, false, time);
      }
    }
  }

  @override
  void onSpaceBarPressed() {}

  @override
  void onKeyEvent(KeyEvent event) {
    // TODO: implement onKeyEvent
  }

  @override
  void onLeave(int index) {
    // TODO: implement onleaveMatch
  }

  @override
  void onPause() {
    // TODO: implement onPauseGame
  }
  @override
  void onPlayerChange(int player) {
    // TODO: implement onPlayerChange
  }

  @override
  void onInit() {
    initGrids();
  }

  @override
  void onResume() {
    // TODO: implement onResume
  }

  @override
  void onStart() {}

  @override
  void onConcede(int index) {}

  @override
  void onPlayerTimeEnd() {}

  @override
  void onTimeEnd() {}

  @override
  Widget buildBody(BuildContext context) {
    // print("currentPlayer= $currentPlayer, $playersSize");
    // print("gameDetails = $gameDetails");
    return Center(
      child: AspectRatio(
          aspectRatio: 1 / 1,
          child: RotatedBox(
            quarterTurns: getOppositeLayoutTurn(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => startDrawingLine(details, currentPlayer),
              onPanUpdate: (details) =>
                  updateDrawingLine(details, currentPlayer),
              onPanEnd: (details) => endDrawingLine(details, currentPlayer),
              child: CustomPaint(
                foregroundPainter: playersMatchLines.isEmpty
                    ? null
                    : MatchLinesPainter(
                        context: context,
                        gridSize: gridSize,
                        matchLines: playersMatchLines[currentPlayer],
                        draggedMatchLines: draggedMatchLines,
                        player: currentPlayer,
                      ),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: tint)),
                  child: GridView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0),
                    children: List.generate(gridSize * gridSize, (index) {
                      if (playersWordPuzzles.isEmpty) return Container();
                      final wordPuzzle =
                          playersWordPuzzles[currentPlayer][index];
                      final selectedPos = playersSelectedPos[currentPlayer];

                      return WordPuzzleTile(
                          key: Key("${wordPuzzle.x}:${wordPuzzle.y}"),
                          gameId: gameId,
                          blink:
                              hintPositions.contains(index) && !finishedRound,
                          highLight: selectedPos == index,
                          wordPuzzle: wordPuzzle,
                          onPressed: () {
                            playChar(index, currentPlayer, false);
                          });
                    }),
                  ),
                ),
              ),
            ),
          )),
      // child: AspectRatio(
      //   aspectRatio: 1 / 1,
      //   child: Column(
      //     children: List.generate(2, (pindex) {
      //       return Expanded(
      //         child: RotatedBox(
      //           quarterTurns: (gameId.isEmpty && pindex == 0) ||
      //                   (gameId.isNotEmpty && currentPlayer == 0)
      //               ? 2
      //               : 0,
      //           child: GestureDetector(
      //             behavior: HitTestBehavior.opaque,
      //             onPanStart: (details) =>
      //                 startDrawingLine(details, pindex),
      //             onPanUpdate: (details) =>
      //                 updateDrawingLine(details, pindex),
      //             onPanEnd: (details) => endDrawingLine(details, pindex),
      //             child: CustomPaint(
      //               foregroundPainter: MatchLinesPainter(
      //                 context: context,
      //                 gridSize: gridSize,
      //                 matchLines: matchLines,
      //                 draggedMatchLines: draggedMatchLines,
      //                 player: pindex,
      //               ),
      //               child: Container(
      //                 decoration:
      //                     BoxDecoration(border: Border.all(color: tint)),
      //                 child: GridView(
      //                   physics: const NeverScrollableScrollPhysics(),
      //                   padding: EdgeInsets.zero,
      //                   gridDelegate:
      //                       SliverGridDelegateWithFixedCrossAxisCount(
      //                           crossAxisCount: gridSize,
      //                           crossAxisSpacing: 0,
      //                           mainAxisSpacing: 0),
      //                   children: List.generate(gridSize * (gridSize ~/ 2),
      //                       (index) {
      //                     final coordinates =
      //                         convertToGrid(index, gridSize);
      //                     final rowindex = coordinates[0];
      //                     final colindex = coordinates[1];

      //                     // final wordPuzzles = pindex == 0
      //                     //     ? player1WordPuzzles
      //                     //     : player2WordPuzzles;
      //                     if (wordPuzzles.isEmpty) return Container();
      //                     final wordPuzzle =
      //                         wordPuzzles[colindex][rowindex];
      //                     return WordPuzzleTile(
      //                         key: Key("${wordPuzzle.x}:${wordPuzzle.y}"),
      //                         gameId: gameId,
      //                         highLight: (pindex == 0 &&
      //                                 player1SelectedOffset != null &&
      //                                 player1SelectedOffset!.dx ==
      //                                     rowindex &&
      //                                 player1SelectedOffset!.dy ==
      //                                     colindex) ||
      //                             (pindex == 1 &&
      //                                 player2SelectedOffset != null &&
      //                                 player2SelectedOffset!.dx ==
      //                                     rowindex &&
      //                                 player2SelectedOffset!.dy ==
      //                                     colindex),
      //                         wordPuzzle: wordPuzzle,
      //                         onPressed: () {
      //                           playChar(index, pindex, false);
      //                         },
      //                         blink: false);
      //                   }),
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ),
      //       );
      //     }),
      //   ),
      // ),
    );
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    if (index != currentPlayer || playersWords.isEmpty) return Container();
    final words = playersWords[index];
    return RotatedBox(
      quarterTurns: getStraightTurn(index),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            words.length,
            (index) {
              final word = words[index];
              return AppContainer(
                wrapped: true,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: BorderRadius.circular(10),
                color: lightestTint,
                child: Text(word, style: context.bodyMedium),
              );
            },
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
