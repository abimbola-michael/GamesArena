import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:hive/hive.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/constants.dart';
import '../../../shared/dialogs/infos_dialog.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/models/app_message.dart';
import '../../../shared/models/models.dart';

import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/hinting_widget.dart';
import '../../../theme/colors.dart';
import '../../contact/constants.dart';
import '../../contact/services/services.dart';
import '../../game/providers/search_games_provider.dart';
import '../../game/services.dart';
import '../../onboarding/services.dart';
import '../../user/services.dart';
import '../../match/providers/search_matches_provider.dart';
import '../services.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  String gameType = "";
  String name = "";
  int currentIndex = 0;
  User? user;
  auth.User? authUser;
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
  StreamSubscription? connectivitySub, appMessageSub;
  final Connectivity _connectivity = Connectivity();
  int maxVersionCheckCount = 5;

  @override
  void initState() {
    super.initState();
    readAuthUserChange();
    listenForInternetConnection();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    isHomeResumed = state != AppLifecycleState.inactive;
  }

  @override
  void dispose() {
    authSub?.cancel();
    userSub?.cancel();
    subscription?.cancel();
    searchController.dispose();
    connectivitySub?.cancel();
    appMessageSub?.cancel();
    appMessageSub = null;
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void subscribeForGamesArenaNotification() async {
    appMessageSub = getAppMessageStream().listen((appMessage) {
      showAppMessage(appMessage);
    });
  }

  void showAppMessage(AppMessages? appMessages) async {
    if (appMessages == null || user == null) return;

    String announcement = "";
    final appMessage = appMessages.appMessage;
    final generalAppMessage = appMessages.generalAppMessage;

    if (appMessage != null && generalAppMessage != null) {
      announcement = appMessage.time.toInt > generalAppMessage.time.toInt
          ? appMessage.announcement!
          : generalAppMessage.announcement!;
    } else if (appMessage != null) {
      announcement = appMessage.announcement!;
    } else if (generalAppMessage != null) {
      announcement = generalAppMessage.announcement!;
    }
    if (announcement.isEmpty) return;
    // final announcement = appMessages.general != null && AppMessage.fromMap(appMessages.general!).time.toInt >

    if (announcement != user!.announcement) {
      user!.announcement = announcement;
      saveUserProperty(myId, user!.toMap());
      updateSeenAnnouncement(announcement);
      await showDialog(
          context: context,
          builder: (context) {
            return InfosDialog(
                title: "Hi ${user!.username}", message: announcement);
          });
    }
    if (!mounted) return;

    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted || appMessage == null) return;

    String appVersion = packageInfo.version;
    final lastVersion = sharedPref.getString("appVersion");
    // int? lastVersionCount = sharedPref.getInt("appVersionCount") ;
    // if (lastVersionCount == null || lastVersionCount == maxVersionCheckCount) {
    //   lastVersionCount = 0;
    // } else {
    //   lastVersionCount++;
    //   sharedPref.setInt("appVersionCount", lastVersionCount);
    // }

    if (appMessage.version != null &&
        appMessage.version != appVersion &&
        appMessage.version != lastVersion) {
      sharedPref.setString("appVersion", appMessage.version!);

      final result = await showDialog(
          context: context,
          builder: (context) {
            return InfosDialog(
                title: "Update App",
                message:
                    "Hi ${user!.username}, A new verison of Games Arena is now available on Play Store",
                messages: appMessage.features,
                actions: const ["Close", "Update"]);
          });
      if (result == true) {
        launchUrlIfCan(PLAYSTORELINK);
      }
    }
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
      this.authUser = authUser;
      if (authUser != null) {
        currentUserId = authUser.uid;
        readUser(authUser);
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

        gameListsBox.clear();
        matchesBox.clear();
        usersBox.clear();
        playersBox.clear();
        contactsBox.clear();

        sharedPref.remove(TAPPED_LOGIN);
        sharedPref.remove(TAPPED_PLAY);
        sharedPref.remove(TAPPED_SEARCH_USER);
        sharedPref.remove(TAPPED_SHARE);
        sharedPref.remove(TAPPED_CREATE_GROUP);
        sharedPref.remove(TAPPED_FIND_PLAYERS);
        sharedPref.remove(TAPPED_SEARCH_GAMES_AND_MATCHES);
        sharedPref.remove(TAPPED_SEARCH_CONTACTS);
        sharedPref.remove(TAPPED_SEARCH_MATCHES);
        sharedPref.remove(TAPPED_MATCHES_MORE);
        sharedPref.remove(TAPPED_GAME_PROFILE_MORE);
        sharedPref.remove("token");
      }
      sharedPref.setString("currentUserId", currentUserId);
      if (!mounted) return;
      setState(() {});
      // Future.delayed(const Duration(seconds: 3)).then((value) {
      //   authSub?.cancel();
      //   authSub = null;
      // });
    });
  }

  void readUser(auth.User authUser) async {
    String userId = authUser.uid;
    // || loading
    if (userId.isEmpty) return;
    loading = true;

    if (this.user != null) return;

    var user = await getUser(userId, useCache: false);
    if (this.authUser == null) return;

    if (user == null) {
      if (!mounted) return;
      context.showLoading(message: "Creating user...");

      user = await createUserFromAuthUser(authUser);
      if (!mounted) return;
      context.pop();
      context.showSuccessToast("User created successfully");
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
      if (result == null) {
        logout();
        loading = false;
        setState(() {});
        return;
      }
    }
    if (!mounted) return;
    if (user.username.isEmpty && user.phone.isEmpty) {
      mode = AuthMode.usernameAndPhoneNumber;
      result = await context.pushTo(AuthPage(mode: mode));

      if (result is Map<String, dynamic>) {
        user.username = result["username"];
        user.phone = result["phone"];
        user.country_code = result["country_code"];
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
        user.country_code = result["country_code"];
      }
    }
    if (mode != null) {
      if (result == null) {
        logout();
        loading = false;
        setState(() {});
      } else {
        if (!mounted) return;

        context.showLoading(message: "Saving...");

        await updateUser(userId, result);
        if (!mounted) return;

        context.pop();
        context.showSuccessToast("Details saved successfully");
        saveUserProperty(userId, user.toMap().removeNull());
      }
    }

    if (user.time_deleted != null) {
      showToast("Account Deleted");

      logout();
      loading = false;
      setState(() {});

      return;
    }

    if (isAndroidAndIos || kIsWeb) {
      analytics.logEvent(
        name: 'active',
        parameters: {
          'id': user.user_id,
          'country': user.country_code ?? "",
          "datetime": DateTime.now().datetime,
        },
      );
    }

    name = user.username;
    this.user = user;
    loading = false;

    firebaseNotification.updateFirebaseToken();
    subscribeForGamesArenaNotification();
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
    if (sharedPref.getBool(TAPPED_PLAY) != true) {
      sharedPref.setBool(TAPPED_PLAY, true).then((value) {
        setState(() {});
      });
    }
  }

  void startSearch() {
    isSearch = true;
    setState(() {});
    if (sharedPref.getBool(TAPPED_SEARCH_GAMES_AND_MATCHES) != true) {
      sharedPref.setBool(TAPPED_SEARCH_GAMES_AND_MATCHES, true).then((value) {
        setState(() {});
      });
    }
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

  // void showAnnouncement() {
  //   showAppMessage(
  //       AppMessage(announcement: "Welcome to Games Arena 2", time: timeNow));
  // }

  // void showVersionUpdate() {
  //   showAppMessage(AppMessage(
  //       version: "3.1.2",
  //       features: ["Calling", "Video Call", "Live call", "More Games"],
  //       time: timeNow));
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !selectedGame || currentIndex != 0,
      onPopInvoked: (pop) {
        if (pop) return;
        if (isSearch) {
          stopSearch();
        } else if (selectedGame && currentIndex == 0) {
          gamesPageKey.currentState?.executeBackPressed();
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
                leading: HintingWidget(
                  showHint: sharedPref.getBool(TAPPED_LOGIN) == null,
                  hintText: "Tap to login, view profile and more",
                  bottom: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: () {
                      if (selectedGame && currentIndex == 0) {
                        gamesPageKey.currentState?.executeBackPressed();
                      } else {
                        if (sharedPref.getBool(TAPPED_LOGIN) != true) {
                          sharedPref.setBool(TAPPED_LOGIN, true).then((value) {
                            setState(() {});
                          });
                        }
                        scaffoldKey.currentState?.openDrawer();
                      }
                    },
                    icon: Icon(selectedGame && currentIndex == 0
                        ? EvaIcons.arrow_back
                        : EvaIcons.menu_outline),
                    color: tint,
                  ),
                ),
                trailing: HintingWidget(
                  showHint:
                      sharedPref.getBool(TAPPED_SEARCH_GAMES_AND_MATCHES) ==
                          null,
                  hintText: "Tap to search games and matches",
                  bottom: sharedPref.getBool(TAPPED_LOGIN) == true ? 0 : 40,
                  right: 0,
                  child: IconButton(
                    onPressed: startSearch,
                    icon: const Icon(EvaIcons.search),
                    color: tint,
                  ),
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
            user == null
                ? SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Login to Play Online Match"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppButton(
                              title: "Sign Up",
                              onPressed: () {
                                context.pushTo(
                                    const AuthPage(mode: AuthMode.signUp));
                              },
                              wrapped: true,
                              bgColor: lightestTint,
                              color: tint,
                            ),
                            AppButton(
                              title: "Login",
                              onPressed: () {
                                context.pushTo(const AuthPage());
                              },
                              wrapped: true,
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                : const MatchesPage(),
          ],
        ),
        floatingActionButton: user == null
            ? null
            : HintingWidget(
                showHint: sharedPref.getBool(TAPPED_PLAY) == null,
                hintText: "Tap to play with someone",
                top: 0,
                right: 0,
                child: FloatingActionButton(
                  onPressed: gotoSelectPlayers,
                  child: const Icon(EvaIcons.play_circle_outline),
                  // child: const Icon(IonIcons.play),
                ),
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
      ),
    );
  }
}
