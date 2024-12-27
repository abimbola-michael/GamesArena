import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/models/game_page_infos.dart';
import 'package:gamesarena/features/game/models/match_outcome.dart';
import 'package:gamesarena/features/game/providers/game_action_provider.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/features/games/quiz/pages/quiz_game_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../models/concede_or_left.dart';
import '../models/game_action.dart';
import '../models/game_page_data.dart';
import '../models/player.dart';
import '../../user/models/user.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/models/models.dart';

import '../providers/game_page_infos_provider.dart';
import '../providers/match_outcome_provider.dart';

class GamePage extends ConsumerStatefulWidget {
  static const route = "/game";
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _gamePagesDatastate();
}

class _gamePagesDatastate extends ConsumerState<GamePage> {
  bool firstTime = true;

  GameAction? gameAction;

  String gameName = "";

  String matchId = "";
  String gameId = "";

  bool isTournament = false;
  Match? match;
  List<User?>? users;
  int playersSize = 2;
  String? indices;
  int recordId = 0;
  int roundId = 0;
  int lastRecordId = 0;
  int lastRecordIdRoundId = 0;
  int firstRecordId = 0;
  int firstRecordIdRoundId = 0;
  int adsTime = 0;

  //Player
  bool isWatch = false;

  List<Map<String, dynamic>>? gameDetails;
  Map<int, List<Map<String, dynamic>>?> recordGameDetails = {};

  List<Player> players = [];
  List<Player> currentPlayers = [];
  List<List<Player>> tournamentPlayers = [];
  List<GamePageData> gamePagesDatas = [];

  String currentPlayerId = "";
  int currentPlayer = 0;
  int myPlayer = 0;
  int playerPage = 0;
  int currentPage = 0;

  List<int> playersCounts = [];
  List<int> playersScores = [];
  List<ConcedeOrLeft> concedeOrLeftPlayers = [];

  List<String> playersToasts = [];
  List<String> playersMessages = [];

  bool gottenDependencies = false;

  bool isChessOrDraught = false;
  bool isPuzzle = false;
  bool isQuiz = false;

  bool? isSubscribed;
  PageController pageController = PageController();
  List<PageController> pageControllers = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    for (int i = 0; i < pageControllers.length; i++) {
      final controller = pageControllers[i];
      controller.dispose();
    }
    pageControllers.clear();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!gottenDependencies) {
      if (context.args != null) {
        gameName = context.args["gameName"] ?? "";
        matchId = context.args["matchId"] ?? "";
        gameId = context.args["gameId"] ?? "";
        match = context.args["match"];
        users = context.args["users"];
        players = context.args["players"] ?? [];
        playersSize = context.args["playersSize"] ?? 2;
        indices = context.args["indices"];
        recordId = context.args["recordId"] ?? 0;
        roundId = context.args["roundId"] ?? 0;
        recordGameDetails = context.args["recordGameDetails"] ?? {};
        isWatch = context.args["isWatch"] ?? false;
        adsTime = context.args["adsTime"] ?? 0;
        isTournament = context.args["isTournament"] ?? false;
      }
      // ref.read(gameActionProvider.notifier).updateGameAction(null);
      gottenDependencies = true;
      init();
    }
  }

  void init() {
    lastRecordId = recordId;
    lastRecordIdRoundId = roundId;
    firstRecordId = recordId;
    firstRecordIdRoundId = roundId;

    if (gameId.isNotEmpty && match != null) {
      gameName = match!.records?["$recordId"]?["$roundId"]?["game"] ?? gameName;
    }

    currentPlayers.addAll(players);

    final gamePageData = getFullGamePageData(context.args, gameName);
    gamePagesDatas.add(gamePageData);

    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      ref.read(gamePageInfosProvider.notifier).updateGamePageInfos(
          GamePageInfos(
              totalPages: gamePagesDatas.length,
              currentPage: currentPage,
              lastRecordId: lastRecordId,
              lastRecordIdRoundId: lastRecordIdRoundId,
              firstRecordId: firstRecordId,
              firstRecordIdRoundId: firstRecordIdRoundId));
    });
  }

  List<List<Player>> getTournamentPlayers(List<Player> currentPlayers) {
    List<List<Player>> tournamentPlayers = [];
    for (int i = 0; i < currentPlayers.length; i += 2) {
      List<Player> players = [];

      final player = currentPlayers[i];
      players.add(player);
      if (player.id == myId) {
        playerPage = tournamentPlayers.length;
      }
      if (i + 1 < currentPlayers.length) {
        final player2 = currentPlayers[i + 1];
        players.add(player2);
        if (player2.id == myId) {
          playerPage = tournamentPlayers.length;
        }
      }

      tournamentPlayers.add(players);
    }
    return tournamentPlayers;
  }

  Widget getGamePage(Map<String, dynamic> args, String gameName) {
    if (gameName.endsWith("Quiz")) {
      return QuizGamePage(args, updateGameAction);
    }
    switch (gameName) {
      case chessGame:
        return ChessGamePage(args, updateGameAction);
      case draughtGame:
        return DraughtGamePage(args, updateGameAction);
      case ludoGame:
        return LudoGamePage(args, updateGameAction);
      case xandoGame:
        return XandOGamePage(args, updateGameAction);
      case whotGame:
        return WhotGamePage(args, updateGameAction);
      case wordPuzzleGame:
        return WordPuzzleGamePage(args, updateGameAction);
    }
    return Container();
  }

  GamePageData getFullGamePageData(Map<String, dynamic> args, String gameName,
      {bool hasDetails = false}) {
    var players = args["players"] as List<Player>?;
    //final playersSize = args["playersSize"] as int;

    Widget gamePage;
    if (players != null && players.length > 3 && isTournament) {
      List<List<Player>> tournamentPlayers = getTournamentPlayers(players);
      //playerPage
      final pageController = PageController(initialPage: playerPage);
      if (hasDetails) {
        pageControllers.add(pageController);
      }
      gamePage = PageView.builder(
        scrollDirection: Axis.vertical,
        controller: pageController,
        itemCount: tournamentPlayers.length,
        itemBuilder: (context, index) {
          final players = tournamentPlayers[index];
          Map<String, dynamic> newArgs = {...args};

          newArgs["players"] = players;
          newArgs["playersSize"] = players.length;
          newArgs["users"] = users == null
              ? null
              : players
                  .map((player) => users?.firstWhereNullable(
                      (user) => player.id == user?.user_id))
                  .toList();
          //roundId
          return getGamePage(newArgs, gameName);
        },
      );
      return GamePageData(child: gamePage, args: args);
    } else {
      if (players != null) {
        args["players"] = players;
        args["users"] = users == null
            ? null
            : players
                .map((player) => users
                    ?.firstWhereNullable((user) => player.id == user?.user_id))
                .toList();
      }

      gamePage = getGamePage(args, gameName);
      print("args = $args, gameName = $gameName");
      return GamePageData(child: gamePage, args: args);
    }
  }

  void updateGameAction(GameAction gameAction) async {
    Map<String, dynamic> args = {...gameAction.args};
    int recordId = args["recordId"] ?? 0;
    int roundId = args["roundId"] ?? 0;
    final match = args["match"] as Match?;
    final playersLeft = gameAction.playersLeft;
    final playersSize = args["playersSize"] as int;

    if (playersLeft.isNotEmpty &&
        (gameAction.action == "change" ||
            gameAction.action == "restart" ||
            gameAction.action == "continue")) {
      var players = args["players"] as List<Player>?;
      if (players != null) {
        final playersToRemove =
            playersLeft.map((index) => players![index].id).toList();
        players = players
            .where((player) => !playersToRemove.contains(player.id))
            .toList();
        args["players"] = players;

        args["playersSize"] = players.length;
      } else {
        args["playersSize"] = playersSize - playersLeft.length;
      }
    }

    if (gameAction.action == "change" || gameAction.action == "restart") {
      if (gameAction.hasDetails) {
        recordId++;
        args["recordId"] = recordId;
        args["roundId"] = 0;
      }
      args.remove("playersScores");

      if (gameAction.action == "change") {
        args["gameName"] = gameAction.game;
      }
    } else if (gameAction.action == "continue") {
      roundId++;
      args["roundId"] = roundId;
    } else if (gameAction.action == "previous") {
      if (currentPage > 0) {
        pageController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
        return;
      }
      if (match?.records != null) {
        if (roundId > 0) {
          roundId--;
        } else {
          if (recordId > 0) {
            recordId--;
            roundId =
                (match!.records!["$recordId"]["rounds"] as Map<String, dynamic>)
                        .length -
                    1;
          }
        }
        args["recordId"] = recordId;
        args["roundId"] = roundId;

        final playerIds = match!.records!["$recordId"]["rounds"]["$roundId"]
            ["players"] as List<String>?;
        if (playerIds != null) {
          args["players"] = List.generate(
              playerIds.length,
              (index) =>
                  Player(id: playerIds[index], time: timeNow, order: index));
          args["playersSize"] = playerIds.length;
        }
        //args["players"] = ;
      }
    } else if (gameAction.action == "next") {
      if (currentPage < gamePagesDatas.length - 1) {
        pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
        return;
      }
      if (match?.records != null) {
        final lastRecord = match!.records!.length - 1;
        final lastRound =
            (match.records!["$recordId"]["rounds"] as Map<String, dynamic>)
                    .length -
                1;
        if (roundId < lastRound) {
          roundId++;
        } else {
          if (recordId < lastRecord) {
            recordId++;
            roundId = 0;
          }
        }
        args["recordId"] = recordId;
        args["roundId"] = roundId;

        final playerIds = match.records!["$recordId"]["rounds"]["$roundId"]
            ["players"] as List<String>?;
        if (playerIds != null) {
          args["players"] = List.generate(
              playerIds.length,
              (index) =>
                  Player(id: playerIds[index], time: timeNow, order: index));
          args["playersSize"] = playerIds.length;
        }
      }
    }
    //else if (gameAction.action == "jump") {}

    final gamePageData = getFullGamePageData(args, gameAction.game,
        hasDetails: gameAction.hasDetails);

    if (gameAction.hasDetails ||
        gameAction.action == "previous" ||
        gameAction.action == "next") {
      if (gameAction.action == "previous") {
        gamePagesDatas.insert(0, gamePageData);
        setState(() {});
        pageController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        gamePagesDatas.add(gamePageData);
        setState(() {});
        pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    } else {
      gamePagesDatas[gamePagesDatas.length - 1] = gamePageData;
      setState(() {});
    }

    if (recordId <= firstRecordId) {
      firstRecordId = recordId;
      if (roundId < firstRecordIdRoundId) {
        firstRecordIdRoundId = roundId;
      }

      ref.read(gamePageInfosProvider.notifier).updateFirst(
          firstRecordId, firstRecordIdRoundId,
          totalPages: gamePagesDatas.length);
    } else if (recordId >= lastRecordId) {
      lastRecordId = recordId;
      if (roundId > lastRecordIdRoundId) {
        lastRecordIdRoundId = roundId;
      }
      ref.read(gamePageInfosProvider.notifier).updateLast(
          lastRecordId, lastRecordIdRoundId,
          totalPages: gamePagesDatas.length);
    } else {
      ref
          .read(gamePageInfosProvider.notifier)
          .updateTotalPages(gamePagesDatas.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final gameAction = ref.watch(gameActionProvider);
    // print("gameAction = $gameAction");

    return PageView.builder(
      controller: pageController,
      itemCount: gamePagesDatas.length,
      onPageChanged: (page) {
        currentPage = page;
        ref.read(gamePageInfosProvider.notifier).updateCurrentPage(currentPage);
        //final gamePageData = gamePagesDatas[page];
      },
      itemBuilder: (context, index) {
        final gamePageData = gamePagesDatas[index];
        return gamePageData.child;
      },
    );
    // final matchOutcome = ref.watch(matchOutcomeProvider);
    // updateMatchOutcome(matchOutcome);

    // Map<String, dynamic> args = {};
    // args.addAll(context.args);
    // args["recordGameDetails"] = recordGameDetails;

    // if (isTournament) {
    //   return PageView.builder(
    //     controller: pageController,
    //     itemCount: tournamentPlayers.length,
    //     itemBuilder: (context, index) {
    //       final players = tournamentPlayers[index];

    //       args["pageIndex"] = index;
    //       args["players"] = players;
    //       args["playersSize"] = players.length;
    //       args["users"] = users?.where((user) =>
    //           players.indexWhere((element) => element.id == user?.user_id) !=
    //           -1);
    //       //roundId
    //       return getGamePage(args);
    //     },
    //   );
    // } else {
    //   return getGamePage(args, gameName);
    // }
  }
}
