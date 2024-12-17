import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/widgets/action_button.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/records/pages/game_records_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../../shared/utils/utils.dart';
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
  FirebaseNotification fn = FirebaseNotification();
  int matchesLimit = 10;
  @override
  void initState() {
    super.initState();
    //gameListStream = getGameLists();
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

    gameLists.sortList((gamelist) => gamelist.time, true);
    matches.sortList((match) => match.time_modified, true);

    var lastGamelistTime = gameLists.firstOrNull?.time;
    var lastMatchTime = matches.firstOrNull?.time_created;
    //List<String> gameListIds = gameLists.map((e) => e.game_id).toList();
    List<GameList> addedGameLists = gameLists.sublist(0);

    gameListsSub = getGameListsChange(time: lastGamelistTime)
        .listen((gameListsChange) async {
      for (int i = 0; i < gameListsChange.length; i++) {
        final change = gameListsChange[i];
        final gameList = change.value;
        if (gameList.time_end != null) continue;

        if (change.added) {
          addedGameLists.add(gameList);
          gameLists.add(gameList);
          fn.subscribeToTopic(gameList.game_id);
          gameListsBox.put(gameList.game_id, gameList.toJson());
        } else if (change.modified) {
          final index = gameLists
              .indexWhere((element) => element.game_id == gameList.game_id);
          if (index != -1) {
            gameLists[index] = gameList;
          }
          gameListsBox.put(gameList.game_id, gameList.toJson());
        } else {
          final index = gameLists
              .indexWhere((element) => element.game_id == gameList.game_id);
          if (index != -1) {
            gameLists.removeAt(index);
          }
          fn.unsubscribeFromTopic(gameList.game_id);
          gameListsBox.delete(gameList.game_id);
        }
      }

      //adding matches
      //if (lastGamelistTime == null) {
      for (int i = 0; i < addedGameLists.length; i++) {
        final gameList = addedGameLists[i];

        gameList.game ??= await getGame(gameList.game_id);

        final newMatches = await getMatches(gameList.game_id,
            time: gameList.match?.time_created ?? gameList.lastSeen);

        for (int i = 0; i < newMatches.length; i++) {
          final match = newMatches[i];
          if (matchesBox.get(match.match_id) == null) {
            gameList.unseen =
                match.creator_id == myId ? 0 : (gameList.unseen ?? 0) + 1;
          }
          matchesBox.put(match.match_id, match.toJson());
        }
        if (newMatches.isNotEmpty) {
          gameList.match = newMatches.last;
        }
        final previousMatches = matches
            .where((element) => element.game_id == gameList.game_id)
            .toList();

        if (previousMatches.isEmpty && matches.length < matchesLimit) {
          final previousMatches = await getPreviousMatches(gameList.game_id,
              time: matches.lastOrNull?.time_created,
              limit: matchesLimit - matches.length);
          for (int i = 0; i < previousMatches.length; i++) {
            final match = previousMatches[i];
            matchesBox.put(match.match_id, match.toJson());
          }
          if (matches.isEmpty && previousMatches.isNotEmpty) {
            gameList.match = previousMatches.last;
          }
        }
        gameListsBox.put(gameList.game_id, gameList.toJson());
      }
      addedGameLists.clear();
      // } else {
      //   while (addedGameLists.isNotEmpty) {
      //     List<GameList> currentGameLists = addedGameLists.sublist(
      //         0, addedGameLists.length >= 10 ? 10 : addedGameLists.length);

      //     List<String> currentGameListIds =
      //         currentGameLists.map((e) => e.game_id).toList();
      //     for (int i = 0; i < currentGameLists.length; i++) {
      //       final gameList = currentGameLists[i];

      //       gameList.game ??= await getGame(gameList.game_id);
      //       gameListsBox.put(gameList.game_id, gameList.toJson());
      //     }
      //     print("addedGameLists = $addedGameLists");
      //     final newMatches = await getMatchesFromGameIds(currentGameListIds,
      //         time: lastMatchTime);
      //     print("newMatches = $newMatches");

      //     for (int i = 0; i < newMatches.length; i++) {
      //       final match = newMatches[i];
      //       final gameListJson = gameListsBox.get(match.game_id);
      //       final gameList =
      //           gameListJson != null ? GameList.fromJson(gameListJson) : null;
      //       if (gameList != null) {
      //         gameList.game ??= await getGame(gameList.game_id);
      //         final prevMatch = matchesBox.get(match.match_id);
      //         if (prevMatch == null) {
      //           gameList.unseen = (gameList.unseen ?? 0) + 1;
      //         }

      //         gameList.match = match;
      //         gameListsBox.put(gameList.game_id, gameList.toJson());
      //       }

      //       matches.add(match);
      //       matchesBox.put(match.match_id, match.toJson());
      //     }
      //     addedGameLists.removeRange(
      //         0, addedGameLists.length >= 10 ? 10 : addedGameLists.length);
      //   }
      // }
    });

    // print(
    //     "gameLists = $gameLists, matches = $matches, lastGamelistTime = $lastGamelistTime");

    // bool isInitial = true;

    // gameListsSub =
    //     getGameListsChange(time: lastGamelistTime).listen((gamelistsChange) {
    //   List<GameList> addedGameLists = [];
    //   for (int i = 0; i < gamelistsChange.length; i++) {
    //     final change = gamelistsChange[i];
    //     final gameList = change.value;
    //     final prevGamelistValue = gameListsBox.get(gameList.game_id);
    //     final prevGamelist = prevGamelistValue == null
    //         ? null
    //         : GameList.fromJson(prevGamelistValue);

    //     if (gameList.left == true || change.removed) {
    //       if (!kIsWeb && Platform.isWindows) {
    //         matchesSubs[gameList.game_id]?.cancel();
    //       }
    //       fn.unsubscribeFromTopic(gameList.game_id);
    //       if (change.removed) {
    //         final gameMatches = matches
    //             .where((match) => match.game_id == gameList.game_id)
    //             .toList();
    //         for (int i = 0; i < gameMatches.length; i++) {
    //           final match = gameMatches[i];
    //           matchesBox.delete(match.match_id);
    //         }
    //         gameListsBox.delete(gameList.game_id);
    //         continue;
    //       }
    //     } else {
    //       fn.subscribeToTopic(gameList.game_id);
    //     }
    //     if (prevGamelist == null) {
    //       gameLists.add(gameList);
    //       gameListsBox.put(gameList.game_id, gameList.toJson());
    //       addedGameLists.add(gameList);
    //       modifiedBox.put("gamelists", gameList.time);
    //     } else {
    //       if (!change.removed && prevGamelist.left != gameList.left) {
    //         prevGamelist.left = gameList.left;
    //         gameListsBox.put(gameList.game_id, prevGamelist.toJson());
    //       }
    //     }
    //   }
    //   readGameAndMatches(isInitial ? gameLists : addedGameLists);

    //   if (isInitial) isInitial = false;
    // });
  }

  // void readGameAndMatches(List<GameList> gameLists) async {
  //   for (int i = 0; i < gameLists.length; i++) {
  //     final gameList = gameLists[i];
  //     if (gameList.left == true) continue;
  //     if (!kIsWeb && Platform.isWindows) {
  //       final matchesSub = getMatchesChange(gameList.game_id,
  //               time: gameList.match?.time_modified ??
  //                   gameList.lastSeen ??
  //                   gameList.time)
  //           .listen(
  //         (changes) {
  //           final matches = changes.map((change) => change.value).toList();
  //           storeMatches(matches, gameList);
  //         },
  //       );
  //       matchesSubs[gameList.game_id] = matchesSub;
  //     } else {
  //       final matches = await getMatches(gameList.game_id,
  //           time: gameList.match?.time_modified ??
  //               gameList.lastSeen ??
  //               gameList.time);
  //       storeMatches(matches, gameList);
  //     }
  //   }
  // }

  // void storeMatches(List<Match> matches, GameList gameList) async {
  //   final matchesBox = Hive.box<String>("matches");
  //   final gameListsBox = Hive.box<String>("gamelists");
  //   for (int i = 0; i < matches.length; i++) {
  //     final match = matches[i];
  //     if (matchesBox.get(match.match_id) == null) {
  //       gameList.unseen =
  //           match.creator_id == myId ? 0 : (gameList.unseen ?? 0) + 1;
  //     }
  //     matchesBox.put(match.match_id, match.toJson());
  //   }
  //   if (gameList.game?.firstMatchTime == null) {
  //     gameList.game = await getGame(gameList.game_id);
  //   }

  //   matches.sortList((match) => match.time_modified, false);
  //   final lastMatch = matches.lastOrNull;
  //   gameList.match = lastMatch;

  //   bool update = false;

  //   if (gameList.game != null &&
  //       gameList.game!.groupName == null &&
  //       gameList.game!.players != null &&
  //       gameList.game!.users == null) {
  //     final players = gameList.game!.players!;
  //     List<User> users = await playersToUsers(players);

  //     //players.remove(myId);
  //     // List<String> usernames = [];
  //     // List<String> profilePhotos = [];
  //     // List<User> users = [];

  //     // for (int i = 0; i < players.length; i++) {
  //     //   final player = players[i];
  //     //   if (player == myId) continue;
  //     //   final userBox = Hive.box<String>("users");
  //     //   final userValue = userBox.get(player);
  //     //   User? user = userValue == null ? null : User.fromJson(userValue);
  //     //   user ??= await getUser(player);
  //     //   if (user != null) {
  //     //     users.add(user);
  //     //     usernames.add(user.username);
  //     //     profilePhotos.add(user.profile_photo ?? "");
  //     //     userBox.put(player, user.toJson());
  //     //   }
  //     // }
  //     gameList.game!.users = users;
  //     // gameList.game!.groupName = usernames.join(",");
  //     // gameList.game!.profilePhoto = profilePhotos.join(",");
  //     update = true;
  //   }
  //   if (gameList.match != null &&
  //       gameList.match!.users == null &&
  //       gameList.match!.players != null) {
  //     List<User> users =
  //         await playersToUsers(gameList.match!.players!, withHiveCache: true);
  //     gameList.match!.users = users;
  //     update = true;
  //   }
  //   if (update) {
  //     gameListsBox.put(gameList.game_id, gameList.toJson());
  //   }
  //   print("matchesToStore = $matches, gameList = $gameList");
  // }

  @override
  Widget build(BuildContext context) {
    if (myId.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login to Play Online Games"),
            ActionButton(
              "Login",
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AuthPage(),
                ));
              },
              wrap: true,
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
              .where((gameList) => (gameList.game?.users != null
                      ? getOtherPlayersUsernames(gameList.game!.users!)
                          .toLowerCase()
                      : gameList.game?.groupName != null
                          ? gameList.game!.groupName!.toLowerCase()
                          : "")
                  .contains(searchString))
              .toList();
          if (gameLists.isEmpty) {
            return SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No matches"),
                  ActionButton(
                    "Play Games",
                    onPressed: () {
                      widget.playGameCallback();
                    },
                    wrap: true,
                  )
                ],
              ),
            );
          }

          gameLists.sortList(
              (gameList) => gameList.match?.time_created ?? gameList.time,
              false);
          // print("sstoredGamelists = $gameLists");
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
    //               ActionButton(
    //                 "Play Games",
    //                 onPressed: () {
    //                   widget.playGameCallback();
    //                 },
    //                 wrap: true,
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
