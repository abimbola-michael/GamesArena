import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/features/home/views/home_drawer.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/features/app_info/pages/app_info_page.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/features/match/pages/matches_page.dart';
import 'package:gamesarena/features/game/pages/games_page.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/providers/internet_connection_provider.dart';
import 'package:gamesarena/shared/utils/country_code_utils.dart';
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
import '../../game/providers/search_games_provider.dart';
import '../../game/services.dart';
import '../../onboarding/services.dart';
import '../../user/services.dart';
import '../../match/providers/search_matches_provider.dart';

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
  List<String> tabs = ["Games", "Matches"];

  bool selectedGame = false;
  StreamSubscription<User?>? userSub;
  GlobalKey<GamesPageState> gamesPageKey = GlobalKey();
  Match? currentMatch;
  bool isSearch = false;
  final searchController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  AuthMethods am = AuthMethods();
  bool loading = false;
  StreamSubscription? connectivitySub;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    readAuthUserChange();
    listenForInternetConnection();
  }

  @override
  void dispose() {
    authSub?.cancel();
    userSub?.cancel();
    subscription?.cancel();
    searchController.dispose();
    connectivitySub?.cancel();
    super.dispose();
  }

  void updateTheme(int value) async {
    sharedPref.setInt("theme", value);
  }

  void listenForInternetConnection() {
    connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      isConnectedToInternet = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
      ref
          .read(internetConnectionProvider.notifier)
          .updateConnection(isConnectedToInternet);
    });
  }

  void readAuthUserChange() {
    authSub = auth.FirebaseAuth.instance.authStateChanges().listen((authUser) {
      // print("authUser = $authUser");
      if (authUser != null) {
        currentUserId = authUser.uid;
        readUser(authUser);
        authSub?.cancel();
        authSub = null;
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
          firebaseNotification.unsubscribeFromTopic(gamelist.game_id);
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

  void readUser(auth.User authUser) async {
    if (myId.isEmpty) return;
    var user = this.user;
    loading = true;

    user ??= await getUser(myId, useCache: false);
    if (user == null) {
      am.logOut();
      return;
    }

    if (user.answeredRequests != true && user.phone.isNotEmpty) {
      acceptPlayersRequests(user.phone);
    }
    if (!mounted) return;

    AuthMode? mode;
    dynamic result;
    if (!authUser.emailVerified) {
      mode = AuthMode.verifyEmail;
      result = await context.pushTo(AuthPage(mode: mode));
    } else if (user.username.isEmpty && user.phone.isEmpty) {
      mode = AuthMode.usernameAndPhoneNumber;
      result = await context.pushTo(AuthPage(mode: mode));

      if (result is Map<String, dynamic>) {
        user.username = result["username"];
        user.phone = result["phone"];
      }
    } else if (user.username.isEmpty) {
      mode = AuthMode.username;
      result = await context.pushTo(AuthPage(mode: mode));

      if (result is Map<String, dynamic>) {
        user.username = result["username"];
      }
    } else if (user.phone.isEmpty) {
      mode = AuthMode.phone;
      result = await context.pushTo(AuthPage(mode: mode));

      if (result is Map<String, dynamic>) {
        user.phone = result["phone"];
      }
    }
    if (mode != null) {
      if (result == null) {
        logout();
      } else {
        saveUserProperty(myId, user.toMap().removeNull());
      }

      return;
    }
    if (user.time_deleted != null) {
      showToast("Account Deleted");
      logout();
      return;
    }

    name = user.username;
    this.user = user;
    loading = false;

    readPlayingRequest();
    setState(() {});
  }

  Future logout() async {
    try {
      await logoutUser();
      am.logOut();
    } catch (e) {}
  }

  void readPlayingRequest() {
    subscription = getPlayerRequestStream().listen((playerChanges) async {
      //print("playerChanges = $playerChanges");
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
        if (match == null || !mounted) return;

        final page = NewOnlineGamePage(
          players: const [],
          users: const [],
          game: match.games?.firstOrNull ?? "",
          matchId: match.match_id!,
          gameId: match.game_id!,
          creatorId: match.creator_id!,
          match: match,
          creatorName: "",
          isBottomSheet: currentMatch != null,
        );
        //await context.pushTo(page);

        if (currentMatch == null) {
          currentMatch = match;
          await context.pushTo(page);
          currentMatch = null;
        } else {
          await showModalBottomSheet(
              context: context, builder: (context) => page);
          currentMatch = null;
        }
      }
    });
  }

  void gotoLoginPage() {
    context.pushTo(const AuthPage());
  }

  void gotoProfilePage() {
    context.pushTo(ProfilePage(id: myId));
  }

  void gotoAppInfoPage(String type) {
    context.pushTo(AppInfoPage(type: type));
  }

  void gotoNewGroup() {
    if (myId.isEmpty) {
      context.pushTo(const AuthPage());
    } else {
      context.pushTo(const PlayersSelectionPage(type: "group"));
    }
  }

  void gotoSelectPlayers() {
    if (myId.isEmpty) {
      context.pushTo(const AuthPage());
    } else {
      context.pushTo(const PlayersSelectionPage(type: "user"));
    }
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
                //subtitle: currentIndex == 0 ? "Games" : "Matches",
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
                      onPressed: startSearch,
                      icon: const Icon(EvaIcons.search),
                      color: tint,
                    ),
                    // if (myId.isNotEmpty)
                    //   IconButton(
                    //     onPressed: gotoNewGroup,
                    //     icon: SizedBox(
                    //       height: 30,
                    //       width: 30,
                    //       child: Stack(
                    //         // alignment: Alignment.topRight,
                    //         children: [
                    //           const Positioned(
                    //               left: 0,
                    //               bottom: 0,
                    //               child: Icon(OctIcons.people, size: 24)),
                    //           // Icon(OctIcons.plus, size: 10),
                    //           Positioned(
                    //             right: 0,
                    //             top: 0,
                    //             child: Text("+",
                    //                 style: context.bodySmall?.copyWith(
                    //                     fontWeight: FontWeight.bold,
                    //                     fontSize: 16)),
                    //           )
                    //         ],
                    //       ),
                    //     ),
                    //     color: tint,
                    //   ),
                  ],
                ),
              )) as PreferredSizeWidget?,
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
            const MatchesPage()
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: gotoSelectPlayers,
          child: const Icon(EvaIcons.play_circle_outline),
          // child: const Icon(IonIcons.play),
        ),
        bottomNavigationBar: SizedBox(
          height: 50,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (currentIndex == index) return;
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  child: Center(
                    child: Text(
                      tab,
                      style: context.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentIndex == index ? primaryColor : tint),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //     selectedItemColor: Colors.blue,
        //     currentIndex: currentIndex,
        //     onTap: (index) {
        //       if (currentIndex == index) return;
        //       setState(() {
        //         currentIndex = index;
        //       });
        //     },
        //     items: const [
        //       BottomNavigationBarItem(
        //         icon: Icon(Icons.gamepad),
        //         label: "Games",
        //       ),
        //       BottomNavigationBarItem(
        //           icon: Icon(Icons.play_arrow), label: "Matches"),
        //     ]),
      ),
    );
  }
}
