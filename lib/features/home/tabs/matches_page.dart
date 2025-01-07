import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/views/empty_listview.dart';
import 'package:gamesarena/shared/widgets/action_button.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/records/pages/game_records_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../../main.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../game/services.dart';
import '../../game/utils.dart';
import '../../game/widgets/game_list_item.dart';
import '../../../shared/models/models.dart';
import '../../onboarding/pages/auth_page.dart';
import '../../onboarding/pages/login_page.dart';
import '../providers/search_matches_provider.dart';

class MatchesPage extends ConsumerStatefulWidget {
  final VoidCallback playGameCallback;
  const MatchesPage({super.key, required this.playGameCallback});

  @override
  ConsumerState<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends ConsumerState<MatchesPage> {
  List<GameList> gameLists = [];
  //late Stream<List<GameList>> gameListStream;
  StreamSubscription? gameListsSub;
  Map<String, StreamSubscription> matchesSubs = {};
  Map<String, bool> gamelistsAddedMap = {};
  int matchesLimit = 10;
  List<String> gameIds = [];
  @override
  void initState() {
    super.initState();
    readGameListsAndMatches();
  }

  @override
  void dispose() {
    gameListsSub?.cancel();
    matchesSubs.forEach((key, value) {
      value.cancel();
    });
    super.dispose();
  }

  void readGameListsAndMatches() async {
    final gameListsBox = Hive.box<String>("gamelists");
    final matchesBox = Hive.box<String>("matches");

    final gameLists =
        gameListsBox.values.map((map) => GameList.fromJson(map)).toList();
    final matches =
        matchesBox.values.map((map) => Match.fromJson(map)).toList();

    gameLists.sortList((gamelist) => gamelist.time_modified, true);
    matches.sortList((match) => match.time_modified, true);

    Future getGameListMatchesAndDetails(List<GameList> addedGameLists) async {
      final gameListsBox = Hive.box<String>("gamelists");
      final matchesBox = Hive.box<String>("matches");

      final gameLists =
          gameListsBox.values.map((map) => GameList.fromJson(map)).toList();
      final matches =
          matchesBox.values.map((map) => Match.fromJson(map)).toList();

      gameLists.sortList((gamelist) => gamelist.time_modified, true);
      matches.sortList((match) => match.time_modified, true);

      for (int i = 0; i < addedGameLists.length; i++) {
        var gameList = addedGameLists[i];

        if (gameList.time_deleted != null &&
            gameListsBox.get(gameList.game_id) != null) {
          unlistenForMatches(gameList.game_id);
          // gameLists
          //     .removeWhere((element) => element.game_id == gameList.game_id);
          gameListsBox.delete(gameList.game_id);
          continue;
        }

        if (gamelistsAddedMap[gameList.game_id] == null) {
          gamelistsAddedMap[gameList.game_id] = true;

          final gameMatches = matches
              .where((match) => match.game_id == gameList.game_id)
              .toList();

          if (gameList.time_end != null &&
              gameMatches.firstOrNull?.time_modified != null &&
              gameMatches.firstOrNull!.time_modified!.toInt >=
                  gameList.time_end!.toInt) {
            continue;
          }

          gameList.game ??= await getGame(gameList.game_id);

          final newMatches = await getMatches(gameList.game_id,
              time: gameMatches.firstOrNull?.time_modified ??
                  gameList.time_seen ??
                  gameList.time_start ??
                  gameList.time_created,
              timeEnd: gameList.time_end);

          for (int i = 0; i < newMatches.length; i++) {
            final match = newMatches[i];
            final index = gameMatches
                .indexWhere((element) => element.match_id == match.match_id);
            if (index != -1) {
              gameMatches[index] = match;
            } else {
              gameMatches.add(match);
              if (matchesBox.get(match.match_id) == null &&
                  match.creator_id != myId) {
                gameList.unseen = (gameList.unseen ?? 0) + 1;
              }
            }

            matchesBox.put(match.match_id, match.toJson());
          }
          gameMatches.sortList((match) => match.time_modified, true);

          listenForMatches(gameList.game_id,
              timeStart: gameMatches.firstOrNull?.time_modified ??
                  gameList.time_seen ??
                  gameList.time_start ??
                  gameList.time_created,
              timeEnd: gameList.time_end);

          gameMatches.sortList((match) => match.time_created, true);

          if (gameMatches.length < matchesLimit) {
            final previousMatches = await getPreviousMatches(gameList.game_id,
                time: gameMatches.lastOrNull?.time_created ??
                    gameList.time_seen ??
                    gameList.time_start,
                limit: matchesLimit - gameMatches.length);
            for (int i = 0; i < previousMatches.length; i++) {
              final match = previousMatches[i];
              matchesBox.put(match.match_id, match.toJson());
            }
          }
          if (gameMatches.isNotEmpty) {
            gameList.match = gameMatches.firstOrNull;
          }
        } else {
          final index = gameLists
              .indexWhere((element) => element.game_id == gameList.game_id);

          if (index != -1) {
            final prevGameList = gameLists[index];
            gameList = gameList.copyWith(
                game: prevGameList.game,
                match: prevGameList.match,
                unseen: prevGameList.unseen);
            // gameLists[index] = gameList;
          } else {
            //gameLists.insert(0, gameList);
          }
          if (gameList.time_end != null) {
            unlistenForMatches(gameList.game_id);
          }
        }

        gameListsBox.put(gameList.game_id, gameList.toJson());
      }
    }

    var lastGamelistTime = gameLists.firstOrNull?.time_modified;

    //List<GameList> addedGameLists = gameLists.sublist(0);
    if (myId.isEmpty) return;

    await getGameListMatchesAndDetails(gameLists);

    final newGameLists = await getGameLists(time: lastGamelistTime);
    await getGameListMatchesAndDetails(newGameLists);

    gameLists.sortList((gamelist) => gamelist.time_modified, true);

    lastGamelistTime = gameLists.firstOrNull?.time_modified;

    gameListsSub = getGameListsChange(time: lastGamelistTime)
        .listen((gameListsChange) async {
      List<GameList> gottenGameLists = [];
      for (int i = 0; i < gameListsChange.length; i++) {
        final change = gameListsChange[i];
        final gameList = change.value;

        if (change.removed) {
          if (gameListsBox.get(gameList.game_id) != null) {
            unlistenForMatches(gameList.game_id);
            // gameLists
            //     .removeWhere((element) => element.game_id == gameList.game_id);
            gameListsBox.delete(gameList.game_id);
          }

          continue;
        }
        gottenGameLists.add(gameList);
      }
      //adding matches
      getGameListMatchesAndDetails(gottenGameLists);
    });
  }

  void listenForMatches(String gameId, {String? timeStart, String? timeEnd}) {
    // if (isAndroidAndIos) {
    //   firebaseNotification.subscribeToTopic(gameId);
    //   return;
    // }
    if (matchesSubs[gameId] != null) return;
    final gameListsBox = Hive.box<String>("gamelists");
    final matchesBox = Hive.box<String>("matches");

    final gameListJson = gameListsBox.get(gameId);
    if (gameListJson == null) return;
    final gameList = GameList.fromJson(gameListJson);

    final sub = getMatchesChange(gameId).listen((matchesChanges) {
      for (int i = 0; i < matchesChanges.length; i++) {
        final matchesChange = matchesChanges[i];
        final match = matchesChange.value;

        if (matchesChange.removed) {
          matchesBox.delete(match.match_id);
        } else {
          if (matchesBox.get(match.match_id) == null) {
            gameList.unseen =
                match.creator_id == myId ? 0 : (gameList.unseen ?? 0) + 1;
            gameList.match = match;
            gameListsBox.put(gameList.game_id, gameList.toJson());
          }
          matchesBox.put(match.match_id, match.toJson());
        }
      }
    });
    matchesSubs[gameId] = sub;
    // if (gameIds.length == 10 || isLast) {
    //   final sub = getAllMatchesChange(gameIds)
    //   gameIds.clear();
    //   return;
    // }
    // gameIds.add(gameId);
  }

  void unlistenForMatches(String gameId) {
    // if (isAndroidAndIos) {
    //   firebaseNotification.unsubscribeFromTopic(gameId);
    //   return;
    // }
    matchesSubs[gameId]?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (myId.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login to Play Online Games"),
            AppButton(
              title: "Login",
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AuthPage(),
                ));
              },
              wrapped: true,
            )
          ],
        ),
      );
    }
    final searchString = ref.watch(searchMatchesProvider);

    return ValueListenableBuilder(
        valueListenable: Hive.box<String>("gamelists").listenable(),
        builder: (context, value, child) {
          final gameLists = value.values
              .map((e) => GameList.fromJson(e))
              .where((gameList) => (gameList.game?.groupName != null
                      ? gameList.game!.groupName!.toLowerCase()
                      : gameList.game?.players != null
                          ? getOtherPlayersUsernames(
                                  playersToUsersLocal(gameList.game!.players!))
                              .toLowerCase()
                          : "")
                  .contains(searchString.toLowerCase()))
              .toList();

          if (gameLists.isEmpty) {
            return const EmptyListView(message: "No match");
          }

          // if (gameLists.isEmpty) {
          //   return SizedBox(
          //     width: double.infinity,
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         const Text("No matches"),
          //         AppButton(
          //           title: "Play Games",
          //           onPressed: () {
          //             widget.playGameCallback();
          //           },
          //           wrapped: true,
          //         )
          //       ],
          //     ),
          //   );
          // }

          gameLists.sortList(
              (gameList) =>
                  gameList.match?.time_created ?? gameList.time_created,
              true);
          return ListView.builder(
              itemCount: gameLists.length,
              itemBuilder: (context, index) {
                final gameList = gameLists[index];

                return GameListItem(
                  key: Key(gameList.game_id),
                  gameList: gameList,
                  onPressed: () {
                    context.pushTo(GameRecordsPage(
                        gameList: gameList,
                        game_id: gameList.game_id,
                        id: "",
                        type: ""));
                  },
                );
              });
        });

    // return StreamBuilder<List<GameList>>(
    //     stream: gameListStream,
    //     builder: (context, snapshot) {
    //       if (snapshot.hasError) {
    //         return const Center(
    //           child: Text("Something went wrong"),
    //         );
    //       }
    //       if (snapshot.hasData) {
    //         gameLists = snapshot.data!;
    //         if (gameLists.isEmpty) {
    //           return Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: [
    //               const Text("No matches"),
    //               AppButton(
//title:
    //                 "Play Games",
    //                 onPressed: () {
    //                   widget.playGameCallback();
    //                 },
    //                 wrapped: true,
    //               )
    //             ],
    //           );
    //         }
    //         gameLists.sortList((gameList) => gameList.time, true);
    //         return ListView.builder(
    //             itemCount: gameLists.length,
    //             itemBuilder: (context, index) {
    //               final gameList = gameLists[index];
    //               return GameListItem(
    //                 key: Key(gameList.game_id),
    //                 gameList: gameList,
    //                 onPressed: () {
    //                   context.pushTo(GameRecordsPage(
    //                       game_id: gameList.game_id, id: "", type: ""));
    //                 },
    //               );
    //             });
    //       }
    //       return const Center(
    //         child: CircularProgressIndicator(),
    //       );
    //     });
  }
}
