import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/features/home/views/home_drawer.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/features/app_info/pages/app_info_page.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/features/home/tabs/matches_page.dart';
import 'package:gamesarena/features/home/tabs/games_page.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/models/models.dart';

import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../theme/colors.dart';
import '../../contact/services/services.dart';
import '../../game/services.dart';
import '../../user/services.dart';
import '../providers/search_games_provider.dart';
import '../providers/search_matches_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String gameType = "";
  String name = "";
  int currentIndex = 0;
  User? user;
  StreamSubscription? subscription, authSub;
  List<String> actions = ["Profile, Settings, About Games"];
  bool selectedGame = false;
  StreamSubscription<User?>? userSub;
  GlobalKey<GamesPageState> gamesPageKey = GlobalKey();
  Match? currentMatch;
  bool isSearch = false;
  final searchController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  AuthMethods am = AuthMethods();

  @override
  void initState() {
    super.initState();
    readAuthUserChange();
  }

  @override
  void dispose() {
    authSub?.cancel();
    userSub?.cancel();
    subscription?.cancel();
    searchController.dispose();

    super.dispose();
  }

  void updateTheme(int value) async {
    sharedPref.setInt("theme", value);
  }

  void readAuthUserChange() {
    authSub = auth.FirebaseAuth.instance.authStateChanges().listen((authUser) {
      if (authUser != null) {
        currentUserId = authUser.uid;
        //FirebaseNotification().updateFirebaseToken();
        readUser();
      } else {
        currentUserId = "";
        userSub?.cancel();
        userSub = null;
        name = "";
        user = null;
        final gameListsBox = Hive.box<String>("gamelists");
        final matchesBox = Hive.box<String>("matches");
        final usersBox = Hive.box<String>("users");

        final playersBox = Hive.box<String>("players");
        final contactsBox = Hive.box<String>("contacts");

        final gameLists = gameListsBox.values.toList();

        for (int i = 0; i < gameLists.length; i++) {
          final value = gameLists[i];
          final gamelist = GameList.fromJson(value);
          FirebaseNotification().unsubscribeFromTopic(gamelist.game_id);
        }

        gameListsBox.clear();
        matchesBox.clear();
        usersBox.clear();
        playersBox.clear();
        contactsBox.clear();
      }
      sharedPref.setString("currentUserId", currentUserId);
      if (!mounted) return;
      setState(() {});
    });
  }

  void logOut() {
    am.logOut().then((value) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: ((context) => const AuthPage())),
          (route) => false);
    }).onError((error, stackTrace) {
      showErrorToast("Unable to logout");
    });
  }

  void readUser() async {
    userSub = getStreamUser(myId).listen((user) {
      name = user?.username ?? "";
      this.user = user;
      if (name.isEmpty) {
        context.pushTo(const AuthPage(mode: AuthMode.username));
        return;
      }
      if (user?.time_deleted != null) {
        logOut();
        return;
      }
      if (user != null && user.answeredRequests != true) {
        acceptPlayersRequests(user.phone);
      }
      if (!mounted) return;
      setState(() {});
    });

    print("getPlayerRequestStream");

    subscription = getPlayerRequestStream().listen((playerChanges) async {
      print("playerChanges = $playerChanges");
      // for (int i = 0; i < playerChanges.length; i++) {}
      final playerChange = playerChanges.lastOrNull;
      if (playerChange != null) {
        final player = playerChange.value;
        if (player.matchId == "" || playerChange.removed) return;
        final match = await getMatch(player.gameId!, player.matchId!);
        if (match != null) {
          if (match.users == null && match.players != null) {
            List<User> users = await playersToUsers(match.players!);
            match.users = users;
          } else if (match.players == null || match.players!.isEmpty) {
            final game = await getGame(match.game_id!);
            match.game = game;
          }
        }
        print("player = $player, match = $match");
        if (match == null || !mounted) return;

        final page = NewOnlineGamePage(
          indices: "",
          players: const [],
          users: const [],
          game: match.games?.firstOrNull ?? "",
          matchId: match.match_id!,
          gameId: match.game_id!,
          creatorId: match.creator_id!,
          match: match,
          creatorName: "",
        );

        if (currentMatch == null) {
          currentMatch = match;
          await context.pushTo(page);
          currentMatch = null;
        } else {
          showModalBottomSheet(context: context, builder: (context) => page);
        }
      }
    });

    // subscription = getRequestedMatchesStream().listen((matchesChange) async {
    //   //print("matchesChange = $matchesChange");
    //   for (int i = 0; i < matchesChange.length; i++) {
    //     final matchChange = matchesChange[i];
    //     final match = matchChange.value;
    //     if (matchChange.added) {
    //       currentMatch ??= match;
    //     } else {
    //       if (currentMatch != null &&
    //           (matchChange.removed || !match.players!.contains(myId))) {
    //         context.pop();
    //       }
    //     }
    //   }
    //   if (currentMatch != null) {
    //     await context.pushTo(NewOnlineGamePage(
    //       indices: "",
    //       players: const [],
    //       users: const [],
    //       game: currentMatch!.game ?? "",
    //       matchId: currentMatch!.match_id!,
    //       gameId: currentMatch!.game_id!,
    //       creatorId: currentMatch!.creator_id!,
    //       creatorName: "",
    //     ));
    //     currentMatch = null;
    //   }
    // });
    // final gameRequestStream = getGameRequest();
    // subscription = gameRequestStream.listen((request) async {
    //   if (!mounted || request == null) return;
    //   context.pushTo(NewOnlineGamePage(
    //     indices: "",
    //     players: const [],
    //     users: const [],
    //     game: request.game,
    //     matchId: request.match_id,
    //     gameId: request.game_id,
    //     creatorId: request.creator_id,
    //     creatorName: "",
    //   ));
    //   // if (request != null) {
    //   //   if (!mounted) return;
    //   //   // String gameId = request.game_id;
    //   //   // String matchId = request.match_id;

    //   //   context.pushTo(NewOnlineGamePage(
    //   //     indices: "",
    //   //     players: const [],
    //   //     users: const [],
    //   //     game: request.game,
    //   //     matchId: request.match_id,
    //   //     gameId: request.game_id,
    //   //     creatorId: request.creator_id,
    //   //     creatorName: "",
    //   //   ));
    //   //   //   final players = await readPlayers(gameId, matchId);
    //   //   //   //if (players.length == 1) return;
    //   //   //   if (players.length == 1 && players.first.id == myId) {
    //   //   //     leaveMatch(gameId, matchId, players, false, 0, 0);
    //   //   //     //removeGamedetails(gameId, matchId);
    //   //   //     return;
    //   //   //   }
    //   //   //   if (players.isEmpty ||
    //   //   //       players.indexWhere((element) => element.id == myId) == -1) {
    //   //   //     removeGameRequest();
    //   //   //     if (players.isEmpty) {
    //   //   //       //removeGamedetails(gameId, matchId);
    //   //   //     }
    //   //   //     return;
    //   //   //   }
    //   //   //   players.sort((a, b) => a.order?.compareTo(b.order ?? 0) ?? 0);
    //   //   //   final users = await playersToUsers(players.map((e) => e.id).toList());
    //   //   //   if (players.length != users.length) {
    //   //   //     return;
    //   //   //   }
    //   //   //   final game = request.game;
    //   //   //   String indices = "";
    //   //   //   // if (game == "Ludo") {
    //   //   //   //   indices = await getLudoIndices(gameId);
    //   //   //   //   if (indices == "") return;
    //   //   //   // } else if (game == "Whot") {
    //   //   //   //   indices = await getWhotIndices(gameId);
    //   //   //   //   if (indices == "") return;
    //   //   //   // }
    //   //   //   final creatorIndex = users
    //   //   //       .indexWhere((element) => element.user_id == request.creator_id);
    //   //   //   String creatorName = "";
    //   //   //   if (creatorIndex != -1) {
    //   //   //     creatorName = users[creatorIndex].username;
    //   //   //   } else {
    //   //   //     creatorName = (await getUser(request.creator_id))?.username ?? "";
    //   //   //   }
    //   //   //   if (!mounted) return;

    //   //   //   context.pushTo(NewOnlineGamePage(
    //   //   //     indices: indices,
    //   //   //     players: players,
    //   //   //     users: users,
    //   //   //     game: request.game,
    //   //   //     matchId: request.match_id,
    //   //   //     gameId: request.game_id,
    //   //   //     creatorId: request.creator_id,
    //   //   //     creatorName: creatorName,
    //   //   //   ));
    //   // }
    // });
  }

  void gotoLoginPage() {
    context.pushTo(const AuthPage());
  }

  void gotoProfilePage() {
    context.pushTo(ProfilePage(id: myId));
  }

  void gotoAppInfoPage(String type) {
    context.pushTo(AppInfoPage(
      type: type,
    ));
  }

  void gotoNewGroup() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => myId == ""
            ? const AuthPage()
            : const PlayersSelectionPage(type: "group")));
  }

  void startSearch() {
    isSearch = true;
    setState(() {});
  }

  void updateSearch(String value) {
    if (currentIndex == 0) {
      ref
          .read(searchGamesProvider.notifier)
          .updateSearch(value.trim().toLowerCase());
    } else {
      ref
          .read(searchMatchesProvider.notifier)
          .updateSearch(value.trim().toLowerCase());
    }
  }

  void stopSearch() {
    if (currentIndex == 0) {
      ref.read(searchGamesProvider.notifier).updateSearch("");
    } else {
      ref.read(searchMatchesProvider.notifier).updateSearch("");
    }

    searchController.clear();
    isSearch = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !selectedGame || currentIndex != 0,
      onPopInvoked: (pop) {
        if (pop) return;
        if (isSearch) {
          stopSearch();
        } else if (selectedGame && currentIndex == 0) {
          gamesPageKey.currentState?.goBackToGames();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: (isSearch
            ? AppSearchBar(
                hint: "Search ${currentIndex == 0 ? "Games" : "Matches"}",
                controller: searchController,
                onChanged: updateSearch,
                onCloseSearch: stopSearch,
              )
            : AppAppBar(
                title: "Games Arena",
                subtitle: currentIndex == 0 ? "Games" : "Matches",
                // style: GoogleFonts.merienda(
                //   fontWeight: FontWeight.bold,
                //   fontSize: 24,
                //   color: tint,
                // ),
                leading: IconButton(
                  onPressed: () {
                    if (selectedGame && currentIndex == 0) {
                      gamesPageKey.currentState?.goBackToGames();
                    } else {
                      scaffoldKey.currentState?.openDrawer();
                    }
                  },
                  icon: Icon(selectedGame && currentIndex == 0
                      ? EvaIcons.arrow_back
                      : EvaIcons.menu_outline),
                  color: tint,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        gotoNewGroup();
                      },
                      icon: const Icon(EvaIcons.person_add_outline),
                      color: tint,
                    ),
                    IconButton(
                      onPressed: () {
                        startSearch();
                      },
                      icon: const Icon(EvaIcons.search),
                      color: tint,
                    ),
                  ],
                ),
              )) as PreferredSizeWidget?,
        // appBar: AppBar(
        //   centerTitle: true,

        //   leading: selectedGame && currentIndex == 0
        //       ? IconButton(
        //           icon: Icon(
        //             EvaIcons.arrow_back,
        //             color: tint,
        //           ),
        //           onPressed: () {
        //             gamesPageKey.currentState?.goBackToGames();
        //           },
        //         )
        //       : null,
        //   //  IconButton(
        //   //     icon: const Icon(EvaIcons.menu_2),
        //   //     onPressed: () {
        //   //       Scaffold.of(context).openDrawer();
        //   //     },
        //   //   ),
        //   title: Text(
        //     "Games Arena",
        //     style: GoogleFonts.merienda(
        //       fontSize: 18,
        //       color: tint,
        //     ),
        //     textAlign: TextAlign.center,
        //   ),
        //   actions: [
        //     IconButton(
        //       icon: Icon(
        //         EvaIcons.search,
        //         color: tint,
        //       ),
        //       onPressed: () {},
        //     ),
        //   ],
        // ),
        drawer:
            selectedGame && currentIndex == 0 ? null : HomeDrawer(name: name),
        body: IndexedStack(
          index: currentIndex,
          children: [
            GamesPage(
              key: gamesPageKey,
              isTab: true,
              gameCallback: (game) {
                selectedGame = game != "";
                setState(() {});
              },
            ),
            MatchesPage(
              playGameCallback: () {
                currentIndex = 0;
                setState(() {});
              },
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: Colors.blue,
            currentIndex: currentIndex,
            onTap: (index) {
              if (currentIndex == index) return;
              setState(() {
                currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.gamepad),
                label: "Games",
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.play_arrow), label: "Matches"),
            ]),
      ),
    );
  }
}
