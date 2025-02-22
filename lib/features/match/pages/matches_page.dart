import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/views/empty_listview.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/match/pages/game_matches_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../../main.dart';
import '../../../shared/providers/internet_connection_provider.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/views/loading_view.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../theme/colors.dart';
import '../../tutorials/pages/tutorials_page.dart';
import '../providers/gamelist_provider.dart';
import '../providers/match_provider.dart';
import '../../game/services.dart';
import '../../game/utils.dart';
import '../widgets/game_list_item.dart';
import '../../../shared/models/models.dart';
import '../../onboarding/pages/auth_page.dart';
import '../providers/search_matches_provider.dart';

class MatchesPage extends ConsumerStatefulWidget {
  const MatchesPage({super.key});

  @override
  ConsumerState<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends ConsumerState<MatchesPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<GameList> gameLists = [];
  List<Match> matches = [];

  //late Stream<List<GameList>> gameListStream;
  StreamSubscription? gameListsSub;
  Map<String, dynamic> matchesSubs = {};
  Map<String, bool> gamelistsAddedMap = {};
  int matchesLimit = 10;
  List<String> gameIds = [];
  bool? isConnected;
  GameList? prevGameList;

  bool loading = false;
  TabController? tabController;
  List<String> matchCategories = ["All", "Players", "Groups", "Unseen"];

  final gameListsBox = Hive.box<String>("gamelists");
  final matchesBox = Hive.box<String>("matches");

  @override
  void initState() {
    super.initState();
    readGameListsAndMatches();
    tabController = TabController(
        length: matchCategories.length, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    closeSubs();
    tabController?.dispose();

    super.dispose();
  }

  void closeSubs() {
    gameListsSub?.cancel();
    matchesSubs.forEach((key, value) {
      if (value is bool) return;
      value.cancel();
    });
    gameLists.clear();
    matchesSubs.clear();
    gamelistsAddedMap.clear();
    gameListsSub = null;
  }

  void readGameListsAndMatches() async {
    closeSubs();

    gameLists =
        gameListsBox.values.map((map) => GameList.fromJson(map)).toList();
    matches = matchesBox.values.map((map) => Match.fromJson(map)).toList();

    gameLists.sortList((gamelist) => gamelist.time_modified, true);
    matches.sortList((match) => match.time_modified, true);

    var lastGamelistTime = gameLists.firstOrNull?.time_modified;

    if (myId.isEmpty) return;

    loading = true;
    setState(() {});

    await getGameListMatchesAndDetails(gameLists);

    final newGameLists = await getGameLists(time: lastGamelistTime);

    await getGameListMatchesAndDetails(newGameLists);

    if (isHomeResumed && gameLists.isEmpty) {
      Future.delayed(const Duration(seconds: 5)).then((value) {
        context.pushTo(const TutorialsPage());
      });
    }
    if (!mounted) return;

    loading = false;
    setState(() {});
    // gameLists.sortList((gamelist) => gamelist.time_modified, true);

    lastGamelistTime = newGameLists.isNotEmpty
        ? newGameLists.firstOrNull?.time_modified
        : gameLists.firstOrNull?.time_modified;

    gameListsSub = getGameListsChange(time: lastGamelistTime)
        .listen((gameListsChange) async {
      List<GameList> gottenGameLists = [];
      for (int i = 0; i < gameListsChange.length; i++) {
        final change = gameListsChange[i];
        final gameList = change.value;

        if (change.removed) {
          if (gameListsBox.get(gameList.game_id) != null) {
            unlistenForMatches(gameList.game_id);

            gameLists
                .removeWhere((element) => element.game_id == gameList.game_id);
            gameListsBox.delete(gameList.game_id);
          }
          continue;
        }
        gottenGameLists.add(gameList);
      }

      //adding matches
      getGameListMatchesAndDetails(gottenGameLists);
    });

    FirebaseNotification.addListener((data) {
      final notificationType = data["type"];
      if (data["data"] == null) return;
      if (notificationType == "match") {
        final dataValue = jsonDecode(data["data"]);
        final match = Match.fromMap(dataValue);
        //if (match.user_id == myId) return;
        saveMatch(match);
      }
    });
  }

  Future getGameListMatchesAndDetails(List<GameList> addedGameLists) async {
    if (addedGameLists.isEmpty) return;

    for (int i = 0; i < addedGameLists.length; i++) {
      var gameList = addedGameLists[i];

      if (gameList.time_deleted != null &&
          gameListsBox.get(gameList.game_id) != null) {
        unlistenForMatches(gameList.game_id);
        gameLists.removeWhere((element) => element.game_id == gameList.game_id);
        gameListsBox.delete(gameList.game_id);
        continue;
      }

      if (gamelistsAddedMap[gameList.game_id] == null) {
        gamelistsAddedMap[gameList.game_id] = true;

        gameList.game ??= await getGame(gameList.game_id);

        final prevGameListJson = gameListsBox.get(gameList.game_id);

        if (prevGameListJson != null) {
          final gameMatches = matches
              .where((match) => match.game_id == gameList.game_id)
              .toList();

          gameMatches.sortList((match) => match.time_modified, true);

          if (gameList.time_end != null &&
              gameMatches.firstOrNull?.time_modified != null &&
              gameMatches.firstOrNull!.time_modified!.toInt >=
                  gameList.time_end!.toInt) {
            continue;
          }

          final newMatches = await getMatches(gameList.game_id,
              time: gameMatches.firstOrNull?.time_modified,
              timeEnd: gameList.time_end);

          for (int i = 0; i < newMatches.length; i++) {
            final match = newMatches[i];
            final index = gameMatches
                .indexWhere((element) => element.match_id == match.match_id);
            if (index != -1) {
              gameMatches[index] = match;
            } else {
              gameMatches.add(match);
            }
            if (matchesBox.get(match.match_id) == null &&
                match.creator_id != myId &&
                (gameList.time_seen == null ||
                    match.time_created!.toInt > gameList.time_seen!.toInt)) {
              gameList.unseen = (gameList.unseen ?? 0) + 1;
            }

            matchesBox.put(match.match_id, match.toJson());
          }

          gameMatches.sortList((match) => match.time_created, true);

          if (gameMatches.isNotEmpty) {
            gameList.match = gameMatches.firstOrNull;
          }

          gameMatches.sortList((match) => match.time_modified, true);

          listenForMatches(gameList.game_id,
              timeStart: gameMatches.firstOrNull?.time_modified,
              timeEnd: gameList.time_end);
        } else {
          final previousMatches = await getPreviousMatches(gameList.game_id,
              timeStart: gameList.time_start,
              timeEnd: gameList.time_end,
              limit: matchesLimit);

          for (int i = 0; i < previousMatches.length; i++) {
            final match = previousMatches[i];
            matchesBox.put(match.match_id, match.toJson());
          }

          if (previousMatches.isNotEmpty) {
            gameList.match = previousMatches.firstOrNull;
          }
        }
      } else {
        if (gameList.time_end != null) {
          unlistenForMatches(gameList.game_id);
        }
      }
      final index = gameLists
          .indexWhere((element) => element.game_id == gameList.game_id);

      if (index != -1) {
        final prevGameList = gameLists[index];
        gameList = gameList.copyWith(
            game: prevGameList.game,
            match: prevGameList.match,
            unseen: prevGameList.unseen);

        gameLists[index] = gameList;
      } else {
        gameLists.add(gameList);
      }

      await gameListsBox.put(gameList.game_id, gameList.toJson());
    }
    setState(() {});
  }

  void listenForMatches(String gameId, {String? timeStart, String? timeEnd}) {
    if (matchesSubs[gameId] != null) return;

    if (isAndroidAndIos) {
      firebaseNotification.subscribeToTopic(gameId);
      matchesSubs[gameId] = true;
      return;
    }

    final sub = getMatchesChange(gameId).listen((matchesChanges) {
      for (int i = 0; i < matchesChanges.length; i++) {
        final matchesChange = matchesChanges[i];
        final match = matchesChange.value;

        if (matchesChange.removed) {
          final matchesBox = Hive.box<String>("matches");
          matchesBox.delete(match.match_id);
        } else {
          saveMatch(match);
        }
      }
    });
    matchesSubs[gameId] = sub;
  }

  void unlistenForMatches(String gameId) {
    if (matchesSubs[gameId] == null) return;

    if (isAndroidAndIos) {
      firebaseNotification.unsubscribeFromTopic(gameId);
      matchesSubs.remove(gameId);
      return;
    }
    matchesSubs[gameId]?.cancel();
    matchesSubs.remove(gameId);
  }

  void saveMatch(Match match) {
    // final gameListIndex =
    //     gameLists.indexWhere((gameList) => gameList.game_id == match.game_id);
    // if (gameListIndex != -1) {
    //   final gameList = gameLists[gameListIndex];
    //   gameList.match = match;
    //   gameLists[gameListIndex] = gameList;
    //   ref.read(gamelistProvider.notifier).updateGameList(gameList);
    // }
    ref.read(matchProvider.notifier).updateMatch(match);
  }

  void addMatch(Match match) {
    final gameListIndex =
        gameLists.indexWhere((gameList) => gameList.game_id == match.game_id);
    final gameListJson = gameListsBox.get(match.game_id);

    final gameList = gameListIndex != -1
        ? gameLists[gameListIndex]
        : gameListJson != null
            ? GameList.fromJson(gameListJson)
            : null;
    if (gameList != null) {
      if (matchesBox.get(match.match_id) == null &&
          match.creator_id != myId &&
          (gameList.time_seen == null ||
              match.time_created!.toInt > gameList.time_seen!.toInt)) {
        gameList.unseen = (gameList.unseen ?? 0) + 1;
      }
      gameList.match = match;
      gameListsBox.put(gameList.game_id, gameList.toJson());
      if (gameListIndex == -1) {
        gameLists.add(gameList);
      } else {
        gameLists[gameListIndex] = gameList;
      }
    } else {}

    matchesBox.put(match.match_id, match.toJson());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final match = ref.watch(matchProvider);
    if (match != null) {
      addMatch(match);
    }
    final currentGameList = ref.watch(gamelistProvider);

    if (currentGameList != null) {
      if (prevGameList?.game_id != currentGameList.game_id) {
        final index = this.gameLists.indexWhere(
            (element) => element.game_id == currentGameList.game_id);
        if (index != -1) {
          this.gameLists[index] = currentGameList;
          if (currentGameList.time_end != null) {
            unlistenForMatches(currentGameList.game_id);
          }
        } else {
          this.gameLists.add(currentGameList);
          listenForMatches(currentGameList.game_id);
        }
        prevGameList = currentGameList;
      } else {
        final index = this.gameLists.indexWhere(
            (element) => element.game_id == currentGameList.game_id);

        if (index != -1 &&
            currentGameList.time_modified !=
                this.gameLists[index].time_modified) {
          this.gameLists[index] = currentGameList;
          prevGameList = currentGameList;
          if (currentGameList.time_end != null) {
            unlistenForMatches(currentGameList.game_id);
          }
        }
      }
    }

    final connected = ref.watch(internetConnectionProvider);
    if (connected != null && isConnected != null && connected != isConnected) {
      readGameListsAndMatches();
    }
    isConnected = connected;

    // if (myId.isEmpty) {
    //   return SizedBox(
    //     width: double.infinity,
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         const Text("Login to Play Online Games"),
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             AppButton(
    //               title: "Sign Up",
    //               onPressed: () {
    //                 context.pushTo(const AuthPage(
    //                   mode: AuthMode.signUp,
    //                 ));
    //               },
    //               wrapped: true,
    //               bgColor: lightestTint,
    //               color: tint,
    //             ),
    //             AppButton(
    //               title: "Login",
    //               onPressed: () {
    //                 context.pushTo(const AuthPage());
    //               },
    //               wrapped: true,
    //             ),
    //           ],
    //         )
    //       ],
    //     ),
    //   );
    // }

    final searchString = ref.watch(searchMatchesProvider);

    final gameLists = searchString.isEmpty
        ? this.gameLists
        : this
            .gameLists
            .where((gameList) => ((gameList.game?.groupName != null
                        ? gameList.game!.groupName!.toLowerCase()
                        : gameList.game?.players != null
                            ? getOtherPlayersUsernames(playersToUsersLocal(
                                    gameList.game!.players!))
                                .toLowerCase()
                            : "")
                    .contains(searchString.toLowerCase()) ||
                (gameList.match?.games ?? [])
                    .join("")
                    .toLowerCase()
                    .contains(searchString.toLowerCase())))
            .toList();

    gameLists.sortList(
        (gameList) => gameList.match?.time_created ?? gameList.time_created,
        true);

    return Column(
      children: [
        TabBar(
          controller: tabController,
          padding: EdgeInsets.zero,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          dividerColor: transparent,
          tabs: List.generate(
            matchCategories.length,
            (index) {
              final tab = matchCategories[index];
              return Tab(text: tab, height: 35);
            },
          ),
        ),
        // if (!isConnectedToInternet)
        //   Center(
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        //       decoration: BoxDecoration(
        //           color: Colors.red, borderRadius: BorderRadius.circular(20)),
        //       child: Text(
        //         "No Internet Connection",
        //         style: context.bodySmall?.copyWith(color: Colors.white),
        //       ),
        //     ),
        //   ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: List.generate(matchCategories.length, (index) {
              final category = matchCategories[index];
              final gameListsMatches = category == "All"
                  ? gameLists
                  : gameLists
                      .where((gamelist) =>
                          gamelist.game != null &&
                          (category == "Players"
                              ? gamelist.game!.groupName == null
                              : category == "Groups"
                                  ? gamelist.game!.groupName != null
                                  : (gamelist.unseen ?? 0) > 0))
                      .toList();
              if (gameListsMatches.isEmpty) {
                return loading
                    ? const LoadingView()
                    : const EmptyListView(message: "No match");
              }
              return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: gameListsMatches.length + (loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final gameList =
                        gameListsMatches[loading ? index - 1 : index];

                    return GameListItem(
                      key: Key(gameList.game_id),
                      gameList: gameList,
                      onPressed: () {
                        context.pushTo(GameMatchesPage(
                            gameList: gameList, game_id: gameList.game_id));
                      },
                    );
                  });
            }),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
