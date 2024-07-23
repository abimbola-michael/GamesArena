import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/features/home/views/home_drawer.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/features/app_info/pages/app_info_page.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/features/home/tabs/matches_page.dart';
import 'package:gamesarena/features/home/tabs/games_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../about/pages/about_game_page.dart';
import '../../game/services.dart';
import '../../games/ludo/services.dart';
import '../../games/whot/services.dart';
import '../../user/services.dart';

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
  StreamSubscription? subscription;
  List<String> actions = ["Profile, Settings, About Games"];
  bool selectedGame = false;
  StreamSubscription<User?>? userSub;
  GlobalKey<GamesPageState> gamesPageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //AuthMethods().logOut();
    // if (myId != "") {
    //   readUser();
    // }
    readAuthUserChange();
  }

  @override
  void dispose() {
    userSub?.cancel();
    subscription?.cancel();
    super.dispose();
  }

  void updateTheme(int value) async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("theme", value);
  }

  void readAuthUserChange() {
    auth.FirebaseAuth.instance.authStateChanges().listen((authUser) {
      if (authUser != null) {
        currentUserId = authUser.uid;
        readUser();
      } else {
        currentUserId = "";
        userSub?.cancel();
        userSub = null;
        name = "";
        user = null;
      }
      setState(() {});
    });
  }

  void readUser() async {
    userSub = getStreamUser(myId).listen((user) {
      name = user?.username ?? "";
      this.user = user;

      // if (user == null) {
      //   AuthMethods().logOut();
      // }
      if (!mounted) return;
      setState(() {});
    });
    final gameRequestStream = getGameRequest();
    subscription = gameRequestStream.listen((request) async {
      if (request != null) {
        if (!mounted) return;
        String gameId = request.game_id;
        String matchId = request.match_id;
        final playing = await getPlaying(gameId);
        //if (playing.length == 1) return;
        if (playing.length == 1 && playing.first.id == myId) {
          leaveGame(gameId, matchId, playing, false, 0, 0);
          removeGameDetails(gameId);
          return;
        }
        if (playing.isEmpty ||
            playing.indexWhere((element) => element.id == myId) == -1) {
          removeGameRequest();
          if (playing.isEmpty) {
            removeGameDetails(gameId);
          }
          return;
        }
        playing.sort((a, b) => a.order.compareTo(b.order));
        final users = await playersToUsers(playing.map((e) => e.id).toList());
        if (playing.length != users.length) {
          return;
        }
        final game = request.game;
        String indices = "";
        // if (game == "Ludo") {
        //   indices = await getLudoIndices(gameId);
        //   if (indices == "") return;
        // } else if (game == "Whot") {
        //   indices = await getWhotIndices(gameId);
        //   if (indices == "") return;
        // }
        final creatorIndex = users
            .indexWhere((element) => element.user_id == request.creator_id);
        String creatorName = "";
        if (creatorIndex != -1) {
          creatorName = users[creatorIndex].username;
        } else {
          creatorName = (await getUser(request.creator_id))?.username ?? "";
        }
        if (!mounted) return;

        context.pushTo(NewOnlineGamePage(
          indices: indices,
          playing: playing,
          users: users,
          game: request.game,
          groupId: "",
          matchId: request.match_id,
          gameId: request.game_id,
          creatorId: request.creator_id,
          creatorName: creatorName,
        ));
      }
    });
  }

  void gotoLoginPage() {
    context.pushTo(const AuthPage());
    // Navigator.of(context).push(
    //     MaterialPageRoute(builder: (context) => const LoginPage(login: true)));
  }

  // void gotoSettingPage() {
  //   Navigator.of(context).push(
  //       MaterialPageRoute(builder: (context) => const LoginPage(login: true)));
  // }

  void gotoProfilePage() {
    context.pushTo(ProfilePage(
      id: myId,
      type: "user",
    ));

    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => ProfilePage(
    //           id: myId,
    //           type: "user",
    //         )));
  }

  void gotoAppInfoPage(String type) {
    context.pushTo(AppInfoPage(
      type: type,
    ));
    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => AppInfoPage(
    //           type: type,
    //         )));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !selectedGame || currentIndex != 0,
      onPopInvoked: (pop) {
        if (selectedGame && currentIndex == 0) {
          gamesPageKey.currentState?.goBackToGames();
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: selectedGame && currentIndex == 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      gamesPageKey.currentState?.goBackToGames();
                    },
                  )
                : null,
            title: Text(
              "Games Arena",
              style: GoogleFonts.merienda(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => myId == ""
                          ? const LoginPage(login: true)
                          : const OnlinePlayersSelectionPage(
                              type: "oneonone")));
                },
              ),
            ],
          ),
          drawer:
              selectedGame && currentIndex == 0 ? null : HomeDrawer(name: name),
          // : Drawer(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Expanded(
          //           child: ListView(
          //             children: [
          //               DrawerHeader(
          //                   child: myId == ""
          //                       ? ActionButton(
          //                           "Login",
          //                           onPressed: () {
          //                             gotoLoginPage();
          //                           },
          //                           wrap: true,
          //                         )
          //                       : Column(
          //                           children: [
          //                             CircleAvatar(
          //                               radius: 40,
          //                               backgroundColor: darkMode
          //                                   ? lightestWhite
          //                                   : lightestBlack,
          //                               child: Text(
          //                                 name.firstChar ?? "",
          //                                 style: const TextStyle(
          //                                     fontSize: 30,
          //                                     color: Colors.blue),
          //                               ),
          //                             ),
          //                             const SizedBox(
          //                               height: 8,
          //                             ),
          //                             Text(
          //                               name,
          //                               style: const TextStyle(
          //                                   fontSize: 18,
          //                                   fontWeight: FontWeight.bold),
          //                             ),
          //                           ],
          //                         )),
          //               if (myId != "") ...[
          //                 ListTile(
          //                   title: const Text(
          //                     "Profile",
          //                     style: TextStyle(fontSize: 16),
          //                   ),
          //                   onTap: () {
          //                     gotoProfilePage();
          //                   },
          //                 ),
          //                 //const Divider(),
          //               ],
          //               ...List.generate(
          //                 allGames.length,
          //                 (index) {
          //                   return ListTile(
          //                     title: Text(
          //                       "About ${allGames[index]}",
          //                       style: const TextStyle(fontSize: 16),
          //                     ),
          //                     onTap: () {
          //                       Navigator.of(context).push(
          //                           MaterialPageRoute(
          //                               builder: ((context) =>
          //                                   AboutGamePage(
          //                                     game: allGames[index],
          //                                   ))));
          //                     },
          //                   );
          //                 },
          //               ),
          //               ListTile(
          //                 title: const Text(
          //                   "Terms and Conditions and Privacy Policy",
          //                   style: TextStyle(fontSize: 16),
          //                 ),
          //                 onTap: () {
          //                   gotoAppInfoPage(
          //                       "Terms and Conditions and Privacy Policy");
          //                 },
          //               ),
          //               ListTile(
          //                 title: const Text(
          //                   "About Us",
          //                   style: TextStyle(fontSize: 16),
          //                 ),
          //                 onTap: () {
          //                   gotoAppInfoPage("About Us");
          //                 },
          //               ),
          //             ],
          //           ),
          //         ),
          //         Padding(
          //           padding: const EdgeInsets.only(bottom: 8.0, left: 16),
          //           child: Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               const Text(
          //                 "Light Theme",
          //                 style: TextStyle(fontSize: 16),
          //               ),
          //               const SizedBox(
          //                 width: 8,
          //               ),
          //               Switch.adaptive(
          //                   activeColor: Colors.blue,
          //                   value: themeValue == 0,
          //                   onChanged: (value) {
          //                     themeValue = value ? 0 : 1;
          //                     updateTheme(themeValue);
          //                     setState(() {});
          //                     ref
          //                         .read(themeNotifierProvider.notifier)
          //                         .toggleTheme(themeValue);
          //                     // Provider.of<ThemeNotifier>(context,
          //                     //         listen: false)
          //                     //     .toggleTheme(themeValue);
          //                   }),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
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
      ),
    );
  }
}
