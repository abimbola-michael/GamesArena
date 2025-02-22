import 'package:gamesarena/features/game/models/computer_format.dart';
import 'package:gamesarena/features/game/utils.dart';

import '../../../shared/utils/constants.dart';
import '../../about/utils/about_game_words.dart';
import '../models/game_info.dart';

String getFirstGamePrompt(String gameName, String difficultyLevel) {
  String prompt =
      "I want to play a $gameName game with you. You are player 1 and your id equals 0, I am player 2 and my id equals 1, The difficuly level is $difficultyLevel. Give me response following the model, infos, initialization, conditions and extras below.";
  ComputerFormat? computerFormat;
  if (gameName.isQuiz) {
    computerFormat = ComputerFormat(
        model: """class Quiz {
  String question;
  List<String> options;
  String answerExplanation;
  int answerIndex;
  int durationInSecs;
  int? selectedAnswer;
  class QuizDetails {
  String? quizzes;
  int? answer;""",
        initialization: """  void initQuizzes({String? quizzesJson}) async {
    
    quizGenerateTrialCount = 0;
    currentQuestion = 0;
    answeredQuestion = -1;
    selectedAnswer = null;
    playersQuizzes.clear();
    if (quizzesJson != null) {
      quizzes = (jsonDecode(quizzesJson) as List)
          .map((e) => Quiz.fromJson(e))
          .toList();
    } else {
      awaiting = true;
      quizzes = await generateQuizzes();
      awaiting = false;

      updateGridDetails(jsonEncode(quizzes));
    }
    loadingQuizzes = false;

    for (int i = 0; i < playersSize; i++) {
      playersQuizzes.add(quizzes.map((quiz) => quiz.copyWith()).toList());
      updateCount(i, 0);
    }
    if (quizzes.isNotEmpty) {
      resetPlayerTime(quizzes.first.durationInSecs);
      stopPlayerTime = false;
    } else {
      awaiting = true;
    }
  }""",
        conditions: """ final details = QuizDetails.fromMap(map);
      final answer = details.answer;

      final quizzes = details.quizzes;
      final playerId = map["id"];
      final player = getPlayerIndex(playerId);

      if (quizzes != null) {
        initQuizzes(quizzesJson: quizzes);
      } else if (answer != null) {
        submitAnswer(answer, player, false);
      }""",
        extras: "Generate 10 different quizzes");
  } else {
    switch (gameName) {
      case chessGame:
        computerFormat = ComputerFormat(
            model: """class Chess {
  int x;
  int y;
  String id;
  int player;
  ChessShape shape;
  bool moved;
  class ChessTile {
  int x;
  int y;
  String id;
  Chess? chess;
  class ChessDetails {
  int? startPos;
  int? endPos;""",
            initialization: """void initChessGrids() {
    clearPattern();
    selectedChessTile = null;
    drawMoveCount = 0;
    player1KingPos = 4;
    player2KingPos = 60;
    playersChesses.clear();
    playersWonChesses.clear();
    chessTiles.clear();
    checkingPos = -1;

    for (int i = 0; i < 2; i++) {
      playersChesses.add([]);
      playersWonChesses.add([]);
    }
    chessTiles = List.generate(gridSize * gridSize, (index) {
      Chess? chess;
      final coordinates = convertToGrid(index, gridSize);
      final x = coordinates[0];
      final y = coordinates[1];
      ChessShape shape = ChessShape.pawn;
      if (y == 1 || y == 6) {
        shape = ChessShape.pawn;
      } else if (y == 0 || y == 7) {
        if (x == 0 || x == 7) {
          shape = ChessShape.rook;
        } else if (x == 1 || x == 6) {
          shape = ChessShape.knight;
        } else if (x == 2 || x == 5) {
          shape = ChessShape.bishop;
        } else if (x == 3) {
          shape = ChessShape.queen;
        } else if (x == 4) {
          shape = ChessShape.king;
        }
      }
      if (y < 2) {
        chess = Chess(
            x: x, y: y, id: "\$index", player: 0, shape: shape, moved: false);
        playersChesses[0].add(chess);
      } else if (y > 5) {
        chess = Chess(
            x: x, y: y, id: "\$index", player: 1, shape: shape, moved: false);
        playersChesses[1].add(chess);
      }
      return ChessTile(x, y, "\$index", chess);
    });
  }""",
            conditions: """final details = ChessDetails.fromMap(map);
      final pos = details.pos;

      if (pos != -1) {
        if (choosePawnPromotion) {
          updateChessPromotion(pos, false);
        } else {
          playChess(pos, false);
        }
      } else {
        changePlayer();
      }""",
            extras:
                """Go online first and learn chess rules and how each piece move to understand better.
                My chess tile is a grid of 8 by 8. I have positions 0 to 63. First row 0 - 7 and (x, y) is (0 - 7, 0), Second 8 - 15 and (x, y) is (0 - 7, 1) and like that ... till Second to last row 48 - 55 and (x, y) is (0 - 7, 6), Second 56 - 63 and (x, y) is (0 - 7, 7). 
                At the start of the game player 1 which is you and is black and at the top on the first and second row which is between positions 0 - 15 and player 2 which is me and is white is on the second to last and last row which is between 48 to 63. 
                I start the game by playing my move and you reciprocate by also playing your move. Basically I am facing up you are facing down. In the detail you return I expect a startPos which is the position of any player you want to select and an endPos which is the place you are playing to,
                 either for capturing on your opponents' spot or just making a move on an empty spot. Make sure you study where your pieces are based on the moves played don't play on any empty spot only your player spot what for ids 0 for you and 1 for me
                 Your black pieces (Player 1 and id of 0) initial positions are 0 - Rook, 1 - Knight, 2 - Bishop, 3 - Queen, 4 - King, 5 - Bishop, 6 - Knight, 7 - Rook and positions 8 to 15 are pawns so initial i am expecting you to play with 0 to 15 startPos and the an endPos based on the piece move style,
                 My white pieces (Player 2 and id of 1) initial positions are and 48 to 55 are pawns, 56 - Rook, 57 - Knight, 58 - Bishop, 59 - Queen, 60 - King, 61 - Bishop, 62 - Knight, 63 - Rook.
                 Empty initial positions are 16 to 47 but would be filled as we play while any played one's spot will become empty and in turns like that,
                 Don't track of anyone according to the game play.
                 Player 1(id of 0) is black and player 2(id of 1) is white, Don't play for me, When the details end with id of 1 it means i played last and you are to play but if ends with id of 0 it means i am to play and like that we play,
                 Moves are;
            "Pawn: A Pawn moves 1 or 2 steps forward with 2 for first move and 1 for subsequent move and 1 step diagonal when about to capture";
            "Rook: A Rook moves 1 or multiple steps edge to edge in top, bottom, left and right direction";
            "Bishop: A Bishop moves 1 or multiple steps diagonally in top left, top right, bottom left, bottom right direction";
            "Knight: A Knight moves 1 step in one edge and 2 steps in the other edge in all directions";
            "King: A King moves 1 step in all directions";
            "Queen: A Queen moves 1 or multiple steps in all directions";
            You can't go over a player, if a player is blocking a move path you can't play over it,
            Using position 0 as example
            if a pawn is on position 1 it can go forward for me if you downward with 1 or 2 steps which means like position 9 or 17
            if a pawn is on position 1 and wants to capture its opponent diagonally it can go forward for me if you downward with 1 step which means like position 8 or 10,
            if a bishop is on position 1 and wants to capture its opponent or move vertically or horizontally it can go forward or downward with 1 or more steps which means like position 8 or 10,

                 """);
        break;
      case draughtGame:
        computerFormat = ComputerFormat(model: """class Draught {
  int x;
  int y;
  String id;
  int player;
  bool king;
  class DraughtTile {
  int x;
  int y;
  String id;
  Draught? draught
  class DraughtDetails {
  int? startPos;
  int? endPos;
  """, initialization: """void initDraughtGrids() {
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
            draught = Draught(x, y, "\$index", 0, false);
            playersDraughts[0].add(draught);
          } else if (y > (gridSize / 2)) {
            draught = Draught(x, y, "\$index", 1, false);
            playersDraughts[1].add(draught);
          }
        }
      }
      return DraughtTile(x, y, "\$index", draught);
    });
  }
""", conditions: """final details = DraughtDetails.fromMap(map);
        final details = DraughtDetails.fromMap(map);
      final startPos = details.startPos;
      final endPos = details.endPos;

      if (startPos != null && endPos != null) {
        playDraught(startPos, false);
        if (!seeking) await Future.delayed(const Duration(milliseconds: 500));
        playDraught(endPos, false);
      }
      }""", extras: "");
        break;
      case whotGame:
        computerFormat = ComputerFormat(
            model: """class Whot {
  String id;
  int number;
  int shape;
  class WhotDetails {
  String? whotIndices;
  int? playPos;
  int? shapePos;
  List<int>? deckPoses;""",
            initialization: """ void initWhots([String? whotIndices]) async {
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
      whots.addAll(newWhots);
    }
  }""",
            conditions: """  final details = WhotDetails.fromMap(map);
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
""",
            extras: "");
        break;
      case ludoGame:
        computerFormat = ComputerFormat(model: """class Ludo {
  String id;
  int step;
  int x;
  int y;
  int housePos;
  int houseIndex;
  int currentHouseIndex;
  class LudoDetails {
  String? ludoIndices;
  int? startPos;
  int? endPos;
  int? startHousePos;
  int? endHousePos;
  int? dice1;
  int? dice2;
  bool? selectedFromHouse;
  bool? enteredHouse;
  bool? selectedFromHouse;
  bool? enteredHouse;""", initialization: """ void initLudos() {
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
        return LudoTile(x, y, "\$index", [], i);
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
  }""", conditions: """ final details = LudoDetails.fromMap(map);

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
      }""", extras: "");
        break;
      case xandoGame:
        computerFormat = ComputerFormat(model: """class XandOTile {
  int x, y;
  String id;
  XandOChar? char;
  class XandODetails {
  int playPos;""", initialization: """void initGrids() {
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
              return XandOTile(null, rowindex, colindex, "\$index");
            }));
    setState(() {});
  }""", conditions: """final details = XandODetails.fromMap(map);
      final playerIndex = getPlayerIndex(map["id"]);

      final playPos = details.playPos;
      if (playPos != -1) {
        playChar(playPos, playerIndex, false);
      } else {
        changePlayer();
      }""", extras: "");
        break;
      case wordPuzzleGame:
        computerFormat = ComputerFormat(
            model: """
  class WordPuzzleDetails {
  String? puzzles;
  String? words;
  int? startPos;
  int? endPos;""",
            initialization: """""",
            conditions: """final details = WordPuzzleDetails.fromMap(map);
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
      }""",
            extras: "Generate 20 words and puzzles");
        break;
    }
  }
  GameInfo? info = gamesInfo[gameName.isQuiz ? quizGame : gameName];
  info?.about = "";
  prompt += "infos: $info,";
  prompt += "format: $computerFormat,";
  prompt +=
      "NB: I want my result to be convertible to a map when jsondecoded, If you need to play extra moves give me a list of map. I need your details in the format i give and play only your pieces and not mine don't confuse it. You are player 1 index 0, I am player 2 index 1, We play in turns like that. Game details of all previous moves are passed to you so play your next move based on the difficulty level";
  return prompt;
}

String getExtraMessage(String gameName) {
  switch (gameName) {
    case ludoGame:
      return "I rolled random dice for you just like for me, your job is to play after seeing your rolled dices";
    case xandoGame:
      return "You can't play on a place that has being played on before by any player, so monitor the id value in the update";
  }
  return "";
}
