import 'package:gamesarena/features/game/utils/examples/ludo_examples.dart';
import 'package:gamesarena/shared/utils/constants.dart';

import 'examples/chess_examples.dart';
import 'examples/draught_examples.dart';
import 'examples/quiz_examples.dart';
import 'examples/whot_examples.dart';
import 'examples/word_puzzle_examples.dart';
import 'examples/xando_examples.dart';

List<String> getGameExamples(String gameName) {
  switch (gameName) {
    case ludoGame:
      return ludoExamples;
    case chessGame:
      return chessExamples;
    case draughtGame:
      return draughtExamples;
    case quizGame:
      return quizExamples;
    case whotGame:
      return whotExamples;
    case wordPuzzleGame:
      return wordPuzzleExamples;
    case xandoGame:
      return xandoExamples;
  }
  return [];
}
