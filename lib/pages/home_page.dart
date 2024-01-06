import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/pages/app_info_page.dart';
import 'package:gamesarena/pages/pages.dart';
import 'package:gamesarena/pages/tabs/matches_page.dart';
import 'package:gamesarena/pages/tabs/games_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blocs/firebase_service.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../styles/colors.dart';
import '../utils/utils.dart';
import 'about_game_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String gameType = "";
  String myId = "";
  String name = "";
  FirebaseService fs = FirebaseService();
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
    if (fs.myId != "") {
      myId = fs.myId;
      getUser();
    }
  }

  @override
  void dispose() {
    userSub?.cancel();
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    builder: (context) => fs.myId == ""
                        ? const LoginPage(login: true)
                        : const OnlinePlayersSelectionPage(type: "oneonone")));
              },
            ),
          ],
        ),
        drawer: selectedGame && currentIndex == 0
            ? null
            : Drawer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView(
                      shrinkWrap: true,
                      children: [
                        DrawerHeader(
                            child: fs.myId == ""
                                ? ActionButton(
                                    "Login",
                                    onPressed: () {
                                      gotoLoginPage();
                                    },
                                    wrap: true,
                                  )
                                : Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: darkMode
                                            ? lightestWhite
                                            : lightestBlack,
                                        child: Text(
                                          name.firstChar ?? "",
                                          style: const TextStyle(
                                              fontSize: 30, color: Colors.blue),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )),
                        if (fs.myId != "") ...[
                          ListTile(
                            title: const Text(
                              "Profile",
                              style: TextStyle(fontSize: 16),
                            ),
                            onTap: () {
                              gotoProfilePage();
                            },
                          ),
                          //const Divider(),
                        ],
                        ...List.generate(
                          games.length,
                          (index) {
                            return ListTile(
                              title: Text(
                                "About ${games[index]}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: ((context) => AboutGamePage(
                                          game: games[index],
                                        ))));
                              },
                            );
                          },
                        ),
                        ListTile(
                          title: const Text(
                            "Terms and Conditions and Privacy Policy",
                            style: TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            gotoAppInfoPage(
                                "Terms and Conditions and Privacy Policy");
                          },
                        ),
                        ListTile(
                          title: const Text(
                            "About Us",
                            style: TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            gotoAppInfoPage("About Us");
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Light Theme",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Switch.adaptive(
                              activeColor: Colors.blue,
                              value: themeValue == 0,
                              onChanged: (value) {
                                themeValue = value ? 0 : 1;
                                updateTheme(themeValue);
                                setState(() {});
                                ref
                                    .read(themeNotifierProvider.notifier)
                                    .toggleTheme(themeValue);
                                // Provider.of<ThemeNotifier>(context,
                                //         listen: false)
                                //     .toggleTheme(themeValue);
                              }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
    );
  }

  void updateTheme(int value) async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("theme", value);
  }

  void getUser() async {
    userSub = fs.getStreamUser(myId).listen((user) {
      if (user != null) {
        if (!mounted) return;
        name = user.username;
        this.user = user;
      }
      setState(() {});
    });
    final gameRequestStream = fs.getGameRequest();
    subscription = gameRequestStream.listen((request) async {
      if (request != null) {
        if (!mounted) return;
        String gameId = request.game_id;
        String matchId = request.match_id;
        final playing = await fs.getPlaying(gameId);
        //if (playing.length == 1) return;
        if (playing.length == 1 && playing.first.id == myId) {
          fs.leaveGame(gameId, matchId, playing, false, 0, 0);
          fs.removeGameDetails(gameId);
          return;
        }
        if (playing.isEmpty ||
            playing.indexWhere((element) => element.id == myId) == -1) {
          fs.removeGameRequest();
          if (playing.isEmpty) {
            fs.removeGameDetails(gameId);
          }
          return;
        }
        final users =
            await fs.playersToUsers(playing.map((e) => e.id).toList());
        if (playing.length != users.length) {
          return;
        }
        final game = request.game;
        String indices = "";
        if (game == "Ludo") {
          indices = await fs.getLudoIndices(gameId);
          if (indices == "") return;
        } else if (game == "Whot") {
          indices = await fs.getWhotIndices(gameId);
          if (indices == "") return;
        }
        final creatorIndex = users
            .indexWhere((element) => element.user_id == request.creator_id);
        String creatorName = "";
        if (creatorIndex != -1) {
          creatorName = users[creatorIndex].username;
        } else {
          creatorName = (await fs.getUser(request.creator_id))?.username ?? "";
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NewOnlineGamePage(
              indices: indices,
              playing: playing,
              users: users,
              game: request.game,
              groupId: "",
              matchId: request.match_id,
              gameId: request.game_id,
              creatorId: request.creator_id,
              creatorName: creatorName,
            ),
          ),
        );
      }
    });
  }

  void gotoLoginPage() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LoginPage(login: true)));
  }

  void gotoSettingPage() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LoginPage(login: true)));
  }

  void gotoProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProfilePage(
              id: myId,
              type: "user",
            )));
  }

  void gotoAppInfoPage(String type) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AppInfoPage(
              type: type,
            )));
  }
}
