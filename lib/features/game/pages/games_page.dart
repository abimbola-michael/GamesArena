import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/game/pages/new_offline_game_page.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../theme/colors.dart';
import '../../match/providers/match_provider.dart';
import '../models/game_list.dart';
import '../providers/search_games_provider.dart';
import '../services.dart';
import '../widgets/game_item.dart';
import '../../../shared/utils/constants.dart';
import '../../games/pages.dart';
import '../../onboarding/pages/auth_page.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';
import '../models/match.dart';

class GamesPage extends ConsumerStatefulWidget {
  final bool isTab;
  final List<String>? players;
  final String? gameId;
  final String? groupName;

  final int? playersSize;
  final bool isCallback;
  final bool isChangeGame;
  final VoidCallback? onBackPressed;
  final void Function(String game)? gameCallback;
  final String? currentGame;
  const GamesPage({
    super.key,
    this.isTab = false,
    this.isCallback = false,
    this.isChangeGame = false,
    this.players,
    this.gameId,
    this.groupName,
    this.playersSize,
    this.gameCallback,
    this.onBackPressed,
    this.currentGame,
  });

  @override
  ConsumerState<GamesPage> createState() => GamesPageState();
}

class GamesPageState extends ConsumerState<GamesPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String game = "";
  String current = "game";
  List<String>? players;
  bool creating = false;
  int playersSize = 2;
  int gridSize = 2;
  int currentTab = 0;
  List<String> gameCategories = [];
  void Function(String game)? gameCallback;

  List<String> boardGames = [];
  List<String> cardGames = [];
  List<String> puzzleGames = [];
  List<String> quizGames = [];

  TabController? tabController;

  @override
  void initState() {
    super.initState();

    if (widget.players != null) {
      players = [...widget.players!];
    }

    gameCallback = widget.gameCallback;

    if (widget.playersSize != null) {
      playersSize = widget.playersSize!;
      if (playersSize == 1) {
        puzzleGames.addAll(allPuzzleGames);
        quizGames.addAll(allQuizGames);
      } else {
        if (playersSize > 2) {
          boardGames.add(ludoGame);
          cardGames.add(whotGame);
        } else {
          boardGames.addAll(allBoardGames);
          cardGames.addAll(allCardGames);
        }
        puzzleGames.addAll(allPuzzleGames);
        quizGames.addAll(allQuizGames);
        // if ((widget.gameId ?? "").isNotEmpty) {

        // }
      }
    } else {
      cardGames.addAll(allCardGames);
      boardGames.addAll(allBoardGames);
      puzzleGames.addAll(allPuzzleGames);
      quizGames.addAll(allQuizGames);
    }

    if (widget.currentGame != null) {
      if (boardGames.contains(widget.currentGame)) {
        boardGames.remove(widget.currentGame);
      } else if (cardGames.contains(widget.currentGame)) {
        cardGames.remove(widget.currentGame);
      } else if (puzzleGames.contains(widget.currentGame)) {
        puzzleGames.remove(widget.currentGame);
      } else if (quizGames.contains(widget.currentGame)) {
        quizGames.remove(widget.currentGame);
      }
    }
    if (boardGames.isNotEmpty) {
      gameCategories.add("Board");
    }
    if (cardGames.isNotEmpty) {
      gameCategories.add("Card");
    }
    if (puzzleGames.isNotEmpty) {
      gameCategories.add("Puzzle");
    }
    if (quizGames.isNotEmpty) {
      gameCategories.add("Quiz");
    }
    tabController = TabController(
        length: gameCategories.length, vsync: this, initialIndex: currentTab);
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  void goBackToGames() {
    if (creating) return;

    if (gameCallback != null) {
      gameCallback!("");
    }
    game = "";
    current = "game";
    setState(() {});
  }

  void createNewMatch() async {
    if (creating) return;
    // setState(() {
    //   creating = true;
    // });
    showLoading(message: "Creating match...");
    try {
      final match = await createMatch(game, widget.gameId, [...players!]);
      if (!mounted || match == null) return;
      if (match.users == null && match.players != null) {
        List<User> users = await playersToUsers(match.players!);
        match.users = users;
      } else if (match.players == null || match.players!.isEmpty) {
        final game = await getGame(match.game_id!);
        match.game = game;
      }

      saveMatch(match);

      await hideDialog();

      if (!mounted) return;
      final page = NewOnlineGamePage(
        players: const [],
        users: const [],
        game: match.games?.firstOrNull ?? "",
        matchId: match.match_id!,
        gameId: match.game_id!,
        creatorId: match.creator_id!,
        match: match,
        creatorName: "",
      );

      creating = false;
      if (!mounted) return;
      setState(() {});

      if (widget.isTab) {
        context.pushTo(page);
      } else {
        context.pushReplacement(page);
      }

      players!.clear();
      players = null;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      // print("error = $e");
      hideDialog();
    } finally {}
  }

  void saveMatch(Match match) {
    ref.read(matchProvider.notifier).updateMatch(match);
  }

  void gotoOfflineGame() async {
    if (!widget.isTab) {
      await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => NewOfflineGamePage(game: game)),
          result: true);
    } else {
      final result = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NewOfflineGamePage(game: game)));
      if (!mounted) return;
      if (result == true) {
        goBackToGames();
      }
    }
  }

  void gotoSelectPlayers() async {
    final players = (await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => myId.isEmpty
            ? const AuthPage()
            : PlayersSelectionPage(
                type: "",
                game: game,
                gameId: widget.gameId,
                groupName: widget.groupName,
              ))) as List<String>?);
    if (players != null) {
      this.players = players;
      if (creating) return;

      createNewMatch();
      goBackToGames();
    }
  }

  void gotoGame() {
    gotoGamePage(context, game, "", "", playersSize: playersSize, result: true);
  }

  void gotoNext(String game) async {
    if (game == yourTopicQuizGame) {
      final topicName = await context.showTextInputDialog(
        title: "Quiz Topic",
        hintText: "Topic",
        message:
            "Enter your quiz topic without ending with quiz and should be between 1 to 3 words",
        actions: ["Cancel", "Start"],
      );
      if (topicName == null) {
        return;
      }
      String name = (topicName as String).trim();
      if (name.isEmpty || name.split(" ").length > 3) {
        showErrorToast(
            "Please enter a valid topic. Your topic should be between 1 to 3 words");
        return;
      }
      if (name.toLowerCase().endsWith("quiz")) {
        name = name.substring(0, name.length - 4);
      }
      game = "${name.capitalize} Quiz";
    }
    if (gameCallback != null) {
      gameCallback!(game);
      if (widget.isChangeGame) {
        return;
      }
    }
    this.game = game;

    if (!mounted) return;

    if (widget.isCallback) {
      Navigator.of(context).pop(game);
    } else {
      if (widget.isTab) {
        setState(() {
          current = "mode";
        });
      } else {
        if (players != null && players!.isNotEmpty) {
          createNewMatch();
        } else if (widget.gameId != null) {
          gotoSelectPlayers();
        } else if (widget.playersSize != null) {
          gotoGame();
        } else {
          gotoOfflineGame();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    gridSize = context.screenWidth < context.screenHeight ? 2 : 4;
    final searchString = ref.watch(searchGamesProvider);
    return PopScope(
      canPop: current == "game",
      onPopInvoked: (pop) {
        if (pop) return;
        if (current != "game") {
          goBackToGames();
        }
      },
      // onWillPop: () async {
      //   if (current == "game") {
      //     return true;
      //   } else {
      //     goBackToGames();
      //     return false;
      //   }
      // },
      child: Scaffold(
        appBar: widget.isTab
            ? null
            : AppAppBar(
                leading: IconButton(
                  onPressed: widget.onBackPressed ?? () => context.pop(),
                  icon: const Icon(
                    EvaIcons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                title: "Select Game",
              ),
        body:
            //  creating
            //     ? const Center(
            //         child: Column(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             CircularProgressIndicator(),
            //             Padding(
            //               padding: EdgeInsets.all(8.0),
            //               child: Text(
            //                 "Creating game...",
            //                 style: TextStyle(
            //                     fontSize: 18, fontWeight: FontWeight.bold),
            //                 textAlign: TextAlign.center,
            //               ),
            //             )
            //           ],
            //         ),
            //       )
            //     :
            Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: current == "game"
              ? Column(
                  children: [
                    TabBar(
                      controller: tabController,
                      padding: EdgeInsets.zero,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      dividerColor: transparent,
                      tabs: List.generate(
                        gameCategories.length,
                        (index) {
                          final tab = gameCategories[index];
                          return Tab(text: tab, height: 35);
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: List.generate(
                          gameCategories.length,
                          (index) {
                            final category = gameCategories[index];
                            List<String> foundGames = category == "Board"
                                ? boardGames
                                : category == "Card"
                                    ? cardGames
                                    : category == "Puzzle"
                                        ? puzzleGames
                                        : category == "Quiz"
                                            ? quizGames
                                            : [];
                            final games = searchString.isEmpty
                                ? foundGames
                                : foundGames
                                    .where((game) => game
                                        .toLowerCase()
                                        .contains(searchString))
                                    .toList();
                            return SingleChildScrollView(
                              // primary: true,
                              padding: const EdgeInsets.only(bottom: 100),
                              scrollDirection: Axis.vertical,
                              child: Wrap(
                                direction: Axis.horizontal,
                                children: List.generate(
                                  games.length,
                                  (index) {
                                    String game = games[index];
                                    return GameItemWidget(
                                      width:
                                          (context.screenWidth - 32) / gridSize,
                                      game: game,
                                      onPressed: () async {
                                        gotoNext(game);
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                )
              : Center(
                  child: SingleChildScrollView(
                    // primary: true,
                    padding: const EdgeInsets.only(bottom: 100),
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (game.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              game,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        Wrap(
                          direction: Axis.horizontal,
                          children: List.generate(
                            modes.length,
                            (index) {
                              String mode = modes[index];
                              return SizedBox(
                                width: (context.screenWidth - 32) / gridSize,
                                child: GameCard(
                                    text: mode,
                                    icon: Icons.gamepad_rounded,
                                    onPressed: () {
                                      if (index == 1) {
                                        gotoOfflineGame();
                                      } else {
                                        gotoSelectPlayers();
                                      }
                                    }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
