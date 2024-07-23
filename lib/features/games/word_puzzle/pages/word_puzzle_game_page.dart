import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/games/word_puzzle/widgets/match_lines_paint.dart';
import 'package:gamesarena/features/games/word_puzzle/widgets/word_puzzle_tile.dart';
import 'package:gamesarena/shared/widgets/app_container.dart';
import 'package:gamesarena/features/games/word_puzzle/models/match_line.dart';
import 'package:gamesarena/features/games/word_puzzle/models/word_puzzle.dart';
import 'package:gamesarena/core/base/base_game_page.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:word_generator/word_generator.dart';

import '../../../../enums/emums.dart';
import '../../../../shared/utils/constants.dart';

class WordPuzzleGamePage extends BaseGamePage {
  static const route = "/wordpuzzle";

  const WordPuzzleGamePage({super.key});

  @override
  State<BaseGamePage> createState() => WordPuzzleGamePageState();
}

class WordPuzzleGamePageState extends BaseGamePageState<WordPuzzleGamePage> {
  //XandODetails? prevDetails;
  int gridSize = 16;
  List<List<WordPuzzle>> player1WordPuzzles = [];
  List<List<WordPuzzle>> player2WordPuzzles = [];

  //List<String> words = [];
  List<String> player1Words = [];
  List<String> player2Words = [];
  // List<String> player1MatchedWords = [];
  // List<String> player2MatchedWords = [];
  List<MatchLine> matchLines = [];
  List<MatchLine> draggedMatchLines = [];

  List<LineDirection> directions = [
    LineDirection.vertical,
    LineDirection.horizontal,
    LineDirection.lowerDiagonal,
    LineDirection.upperDiagonal
  ];

  //List<int> playersScores = [];

  Map<String, String> charMap = {};
  String matchedString = "";
  int? player1Pos, player2Pos;
  Offset? player1SelectedOffest, player2SelectedOffest;

  int wordsLength = 15;
  //final _controller = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    //_controller.dispose();
  }

  String getRandomWord() {
    final generator = WordGenerator();
    String word = generator.randomVerb().toUpperCase();
    while (word.length < 6 ||
        word.length > 12 ||
        player1Words.contains(word) ||
        player2Words.contains(word)) {
      word = generator.randomVerb().toUpperCase();
    }
    return word;
  }

  void generateRandomWords() {
    player1Words.clear();
    player2Words.clear();
    for (int i = 0; i < wordsLength; i++) {
      player1Words.add(getRandomWord());
      player2Words.add(getRandomWord());
    }
  }

  Map<String, String> getWordMap(
      Map<String, String> charMap, String word, int player, int wordIndex) {
    LineDirection direction = LineDirection.horizontal;
    if (word.length <= 8) {
      direction =
          LineDirection.values[Random().nextInt(LineDirection.values.length)];
    }
    Map<String, String> newMap = {};
    final rand = Random();
    final length = word.length;
    final halfSize = gridSize ~/ 2;

    int startX = rand.nextInt(gridSize);
    int startY = rand.nextInt(halfSize);
    if (direction == LineDirection.horizontal) {
      if (startX + length > gridSize) {
        if (startX - length < -1) {
          return {};
        } else {
          startX = startX - length + 1;
        }
      }
    } else if (direction == LineDirection.vertical) {
      if (startY + length > halfSize) {
        if (startY - length < -1) {
          return {};
        } else {
          startY = startY - length + 1;
        }
      }
    } else if (direction == LineDirection.upperDiagonal) {
      if (startY + length > halfSize || startX + length > gridSize) {
        if (startY - length < -1 || startX - length < -1) {
          return {};
        } else {
          startY = startY - length + 1;
          startX = startX - length + 1;
        }
      }
    } else if (direction == LineDirection.lowerDiagonal) {
      if (startY + length > halfSize || startX - length < -1) {
        if (startY - length < -1 || startX + length > gridSize) {
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

    // matchLines.add(
    //   MatchLine(
    //     start: start,
    //     end: end,
    //     player: player,
    //     wordIndex: wordIndex,
    //   ),
    // );
    return newMap;
  }

  void addWordToGrid(
      String word, Map<String, String> charMap, int player, int wordIndex) {
    int trialCount = 1000;
    int newWordCount = trialCount;
    while (newWordCount > 0) {
      int count = trialCount;
      while (count > 0) {
        final result = getWordMap(charMap, word, player, wordIndex);
        if (result.isNotEmpty) {
          charMap.addAll(result);
          break;
        }
        count--;
      }
      if (count > 0) break;
      //print("count = $count, word = $word");

      final newWord = getRandomWord();
      if (player == 0) {
        player1Words[wordIndex] = newWord;
      } else {
        player2Words[wordIndex] = newWord;
      }
      word = newWord;

      newWordCount--;
    }

    if (newWordCount <= 0) {
      //print("newWordCount = $newWordCount, newGrid");
      initGrids();
    }
  }

  void initGrids() {
    showMessage = false;
    generateRandomWords();

    matchLines.clear();
    draggedMatchLines.clear();

    player1WordPuzzles.clear();
    player2WordPuzzles.clear();

    Map<String, String> player1CharMap = {};
    Map<String, String> player2CharMap = {};

    for (int i = 0; i < wordsLength; i++) {
      addWordToGrid(player1Words[i], player1CharMap, 0, i);
      addWordToGrid(player2Words[i], player2CharMap, 1, i);
    }

    final rand = Random();
    final halfSize = gridSize ~/ 2;

    for (int colindex = 0; colindex < halfSize; colindex++) {
      final List<WordPuzzle> player1Puzzles = [];
      final List<WordPuzzle> player2Puzzles = [];

      for (int rowindex = 0; rowindex < gridSize; rowindex++) {
        String? char1 = player1CharMap["$rowindex:$colindex"] ??
            String.fromCharCode(rand.nextInt(26) + 65);
        player1Puzzles.add(WordPuzzle(x: rowindex, y: colindex, char: char1));

        String? char2 = player2CharMap["$rowindex:$colindex"] ??
            String.fromCharCode(rand.nextInt(26) + 65);
        player2Puzzles.add(WordPuzzle(x: rowindex, y: colindex, char: char2));
      }

      player1WordPuzzles.add(player1Puzzles);
      player2WordPuzzles.add(player2Puzzles);
    }

    // player1WordPuzzles = List.generate(
    //     gridSize ~/ 2,
    //     (colindex) => List.generate(gridSize, (rowindex) {
    //           String? char = player1CharMap["$rowindex:$colindex"] ??
    //               String.fromCharCode(rand.nextInt(26) + 65);
    //           return WordPuzzle(x: rowindex, y: colindex, char: char);
    //         }));

    // player2WordPuzzles = List.generate(
    //     gridSize ~/ 2,
    //     (colindex) => List.generate(gridSize, (rowindex) {
    //           //final index = convertToPosition([rowindex, colindex], gridSize);
    //           String? char = player2CharMap["$rowindex:$colindex"] ??
    //               String.fromCharCode(rand.nextInt(26) + 65);
    //           return WordPuzzle(x: rowindex, y: colindex, char: char);
    //         }));

    if (!mounted) return;
    setState(() {});
  }

  void updateDetails(int playPos) {
    if (matchId != "" && gameId != "" && users != null) {
      //   if (played) return;
      //   played = true;
      //   final details = XandODetails(playPos: playPos, currentPlayerId: myId);
      //   fs.setXandODetails(
      //     gameId,
      //     details,
      //     prevDetails,
      //   );
      //   prevDetails = details;
    }
  }

  String getWord(Offset start, Offset end, bool isPlayerOne) {
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
      final wordPuzzles = isPlayerOne ? player1WordPuzzles : player2WordPuzzles;

      final char = wordPuzzles[dy.toInt()][dx.toInt()].char;
      word += char;
    }
    return word;
  }

  int getTouchPos(Offset offset) {
    final halfSize = gridSize ~/ 2;
    final dx = offset.dx > context.minSize
        ? context.minSize
        : offset.dx < 0
            ? 0
            : offset.dx;
    final dy = offset.dy > (context.minSize / 2)
        ? (context.minSize / 2)
        : offset.dy < 0
            ? 0
            : offset.dy;

    int x = ((dx / context.minSize) * gridSize).floor();
    int y = ((dy / (context.minSize / 2)) * halfSize).floor();
    if (x >= gridSize) {
      x = gridSize - 1;
    }
    if (y >= halfSize) {
      y = halfSize - 1;
    }
    final pos = convertToPosition([x, y], gridSize);
    return pos;
  }

  void startDrawingLine(DragStartDetails details, int player) {
    if (player == 0 && player1SelectedOffest != null) {
      player1SelectedOffest = null;
    } else if (player == 1 && player2SelectedOffest != null) {
      player2SelectedOffest = null;
    }
    final startOffset = details.localPosition;
    final pos = getTouchPos(startOffset);
    if (player == 0) {
      player1Pos = pos;
    } else if (player == 1) {
      player2Pos = pos;
    }
    playChar(pos, player, true);
  }

  void updateDrawingLine(DragUpdateDetails details, int player) {
    final currentOffset = details.localPosition;
    final pos = getTouchPos(currentOffset);
    if (player == 0) {
      player1Pos = pos;
    } else if (player == 1) {
      player2Pos = pos;
    }
    playChar(pos, player, true);
  }

  void endDrawingLine(DragEndDetails details, int player) {
    final pos = player == 0 ? player1Pos ?? 0 : player2Pos ?? 0;
    playChar(pos, player, false);
  }

  int getWordIndex(int player, String word) {
    if (player == 0) {
      return player1Words.indexWhere(
        (element) => element == word,
      );
    } else {
      return player2Words.indexWhere(
        (element) => element == word,
      );
    }
  }

  void playChar(int pos, int player, bool dragging) {
    if (awaiting) return;
    bool isPlayerOne = player == 0;
    final wordIndex = isPlayerOne
        ? wordsLength - player1Words.length
        : wordsLength - player2Words.length;

    final coordinates = convertToGrid(pos, gridSize);
    final rowindex = coordinates[0];
    final colindex = coordinates[1];
    final offset = Offset(rowindex.toDouble(), colindex.toDouble());

    final selectedOffset =
        isPlayerOne ? player1SelectedOffest : player2SelectedOffest;

    if (selectedOffset == null) {
      if (isPlayerOne) {
        player1SelectedOffest = offset;
      } else {
        player2SelectedOffest = offset;
      }
      if (dragging) {
        draggedMatchLines.add(
          MatchLine(
              start: Offset(offset.dx, offset.dy),
              end: Offset(offset.dx, offset.dy),
              player: player,
              wordIndex: wordIndex),
        );
      }
    } else {
      if (selectedOffset == offset) {
        if (!dragging) {
          if (isPlayerOne) {
            player1SelectedOffest = null;
          } else {
            player2SelectedOffest = null;
          }
        }
      } else {
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
                wordIndex: wordIndex,
              );
            } else {
              draggedMatchLines.add(MatchLine(
                start: Offset(offset.dx, offset.dy),
                end: Offset(offset.dx, offset.dy),
                player: player,
                wordIndex: wordIndex,
              ));
            }
          } else {
            final matchLineIndex = matchLines.indexWhere((line) =>
                line.player == player &&
                line.start == selectedOffset &&
                line.end == offset);
            if (matchLineIndex != -1) {
              showToast(player, "Word already found! Try another");
            } else {
              final word = getWord(selectedOffset, offset, isPlayerOne);
              final words = isPlayerOne ? player1Words : player2Words;

              if (words.contains(word)) {
                if (matchLineIndex == -1) {
                  matchLines.add(
                    MatchLine(
                      start: Offset(selectedOffset.dx, selectedOffset.dy),
                      end: Offset(offset.dx, offset.dy),
                      player: player,
                      wordIndex: wordIndex,
                    ),
                  );
                }
                words.remove(word);
              } else {
                showToast(player, "Invalid word! Try again");
              }

              if (words.isEmpty) {
                checkWinner();
              }
            }
            if (isPlayerOne) {
              player1SelectedOffest = null;
            } else {
              player2SelectedOffest = null;
            }
          }
        } else {
          showToast(player,
              "Wrong Direction! Can only go vertically, horizantally and diagonally");
        }
      }

      if (!dragging && draggedMatchLines.isNotEmpty) {
        final matchLineIndex = draggedMatchLines.indexWhere(
            (line) => line.player == player && line.start == selectedOffset);
        if (matchLineIndex != -1) {
          draggedMatchLines.removeAt(matchLineIndex);
        }
      }
    }
    setState(() {});
  }

  void checkWinner() {
    if (player1Words.isEmpty) {
      updateWin(0);
    } else if (player2Words.isEmpty) {
      updateWin(1);
    } else {
      updateDraw();
    }
  }

  void getHintMessage() {
    if (!firstTime) return;

    hintMessage =
        "Tap on any grid to play till you have a complete word match that contains your words in any direction";
    message = hintMessage;
    setState(() {});
  }

  @override
  String gameName = wordPuzzleGame;

  @override
  int maxGameTime = 20.minToSec;

  @override
  void onDetailsChange(Map<String, dynamic>? map) {
    // TODO: implement onDetailsChange
  }
  @override
  void onSpaceBarPressed() {}

  @override
  void onKeyEvent(KeyEvent event) {
    // TODO: implement onKeyEvent
  }

  @override
  void onLeave(int index) {
    // TODO: implement onLeaveGame
  }

  @override
  void onPause() {
    // TODO: implement onPauseGame
  }
  @override
  void onPlayerChange() {
    // TODO: implement onPlayerChange
  }

  @override
  void onStart() {
    initGrids();
  }

  @override
  void onConcede(int index) {}

  @override
  void onPlayerTimeEnd() {}

  @override
  void onTimeEnd() {}

  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Column(
              children: List.generate(2, (pindex) {
                return Expanded(
                  child: RotatedBox(
                    quarterTurns: pindex == 0 ? 2 : 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) =>
                          startDrawingLine(details, pindex),
                      onPanUpdate: (details) =>
                          updateDrawingLine(details, pindex),
                      onPanEnd: (details) => endDrawingLine(details, pindex),
                      child: CustomPaint(
                        foregroundPainter: MatchLinesPainter(
                          context: context,
                          gridSize: gridSize,
                          matchLines: matchLines,
                          draggedMatchLines: draggedMatchLines,
                          player: pindex,
                        ),
                        child: Container(
                          decoration:
                              BoxDecoration(border: Border.all(color: tint)),
                          child: GridView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridSize,
                                    crossAxisSpacing: 0,
                                    mainAxisSpacing: 0),
                            children: List.generate(gridSize * (gridSize ~/ 2),
                                (index) {
                              final coordinates =
                                  convertToGrid(index, gridSize);
                              final rowindex = coordinates[0];
                              final colindex = coordinates[1];

                              final wordPuzzles = pindex == 0
                                  ? player1WordPuzzles
                                  : player2WordPuzzles;
                              final wordPuzzle =
                                  wordPuzzles[colindex][rowindex];
                              return WordPuzzleTile(
                                  key: Key("${wordPuzzle.x}:${wordPuzzle.y}"),
                                  highLight: (pindex == 0 &&
                                          player1SelectedOffest != null &&
                                          player1SelectedOffest!.dx ==
                                              rowindex &&
                                          player1SelectedOffest!.dy ==
                                              colindex) ||
                                      (pindex == 1 &&
                                          player2SelectedOffest != null &&
                                          player2SelectedOffest!.dx ==
                                              rowindex &&
                                          player2SelectedOffest!.dy ==
                                              colindex),
                                  wordPuzzle: wordPuzzle,
                                  onPressed: () {
                                    if (gameId != "" &&
                                        currentPlayerId != myId) {
                                      showToast(index,
                                          "Its ${getUsername(currentPlayerId)}'s turn");
                                      return;
                                    }
                                    if (gameId != "") {
                                      updateDetails(index);
                                    } else {
                                      playChar(index, pindex, false);
                                    }
                                  },
                                  blink: false);
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    final words = index == 0 ? player1Words : player2Words;
    return SingleChildScrollView(
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
              child: Text(
                word,
                style: context.bodyMedium,
              ),
            );
          },
        ),
      ),
    );
  }
}
