// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/styles/colors.dart';
import '../blocs/firebase_service.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class NewOnlineGamePage extends StatefulWidget {
  final String game;
  final String groupId;
  final String matchId;
  final String gameId;
  final String creatorId;
  final String creatorName;
  final List<User> users;
  final List<Playing> playing;
  final String indices;

  const NewOnlineGamePage({
    super.key,
    required this.indices,
    required this.users,
    required this.playing,
    required this.gameId,
    required this.matchId,
    required this.game,
    required this.groupId,
    required this.creatorId,
    required this.creatorName,
  });

  @override
  State<NewOnlineGamePage> createState() => _NewOnlineGamePageState();
}

class _NewOnlineGamePageState extends State<NewOnlineGamePage> {
  String matchId = "";
  String gameId = "";
  String game = "";
  String myId = "";
  String type = "";
  String groupId = "";
  String name = "", creatorName = "";
  String creatorId = "";
  FirebaseService fs = FirebaseService();
  bool creatorIsMe = false;
  List<Playing> playing = [];
  List<User?> users = [];
  List<String> otherUsernames = [];
  Timer? timer;
  StreamSubscription<List<Playing>>? playingSub;
  int playersSize = 2;
  String indices = "";
  bool loaded = false;
  late AudioPlayer audioPlayer;
  late StreamSubscription<PlayerState> audioPlayerStateSub;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioPlayer.play(AssetSource("audios/game_ringtone.mp3"));
    audioPlayerStateSub = audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        audioPlayer.play(AssetSource("audios/game_ringtone.mp3"));
      }
    });
    myId = fs.myId;
    groupId = widget.groupId;
    gameId = widget.gameId;
    matchId = widget.matchId;
    creatorId = widget.creatorId;
    creatorName = widget.creatorName;
    game = widget.game;
    indices = widget.indices;
    playing = widget.playing;
    playing.sortList((value) => value.order, false);
    users = widget.users.sortWithStringList(
        playing.map((e) => e.id).toList(), (user) => user.user_id);
    if (creatorId == myId) {
      creatorIsMe = true;
      timer = Timer(const Duration(minutes: 2), () async {
        if (!mounted) return;
        if (playing.isNotEmpty) {
          cancelGame();
        }
      });
    }
    List<User?> otherUsers =
        users.where((user) => user != null && user.user_id != myId).toList();
    if (!creatorIsMe) {
      otherUsers
          .removeWhere((user) => user != null && user.user_id == creatorId);
    }
    otherUsernames = otherUsers.isEmpty
        ? []
        : otherUsers.map((e) => e?.username ?? "").toList();
    if (!creatorIsMe) {
      otherUsernames.insert(0, "you");
    }
    getGame();
  }

  @override
  void deactivate() {
    timer?.cancel();
    timer = null;
    super.deactivate();
  }

  @override
  void dispose() {
    audioPlayerStateSub.cancel();
    audioPlayer.dispose();

    playingSub?.cancel();
    //timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (creatorIsMe) {
          cancelGame();
        } else {
          leaveGame();
        }
        return playing.isEmpty ||
            playing.indexWhere((element) => element.id == myId) == -1;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("New Game"),
            leading: BackButton(
              onPressed: () {
                if (creatorIsMe) {
                  cancelGame();
                } else {
                  leaveGame();
                }
                if (playing.isEmpty ||
                    playing.indexWhere((element) => element.id == myId) == -1) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: playing.isEmpty || users.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Center(
                  child: SingleChildScrollView(
                    primary: true,
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  darkMode ? lightestWhite : lightestBlack,
                              child: Text(
                                creatorName.firstChar ?? "",
                                style: const TextStyle(
                                    fontSize: 30, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                creatorIsMe
                                    ? "You created a $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}"
                                    : "$creatorName will like to play $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return UserItem(
                                  user: user,
                                  type: "",
                                  onPressed: () {},
                                );
                              }),
                        ),
                      ],
                    ),
                  ),
                ),
          //    playing.isEmpty || users.isEmpty
          // ? null
          // :
          bottomNavigationBar: Container(
            height: 50,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionButton(
                  creatorIsMe ? "Cancel" : "Dismiss",
                  onPressed: () {
                    if (creatorIsMe) {
                      cancelGame();
                    } else {
                      leaveGame();
                    }
                  },
                  height: 50,
                  width:
                      context.screenWidth.percentValue(creatorIsMe ? 50 : 40),
                  margin: 0,
                  color: darkMode ? lightestWhite : lightestBlack,
                  textColor: darkMode ? white : black,
                ),
                if (!creatorIsMe) ...[
                  ActionButton(
                    "Join",
                    onPressed: () {
                      joinGame();
                    },
                    height: 50,
                    width: context.screenWidth.percentValue(40),
                    margin: 0,
                    color: Colors.blue,
                    textColor: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void cancelGame() async {
    await fs.cancelGame(gameId, matchId, playing);
  }

  void leaveGame() async {
    await fs.leaveGame(gameId, matchId, playing, false, 0, 0);
  }

  void joinGame() async {
    await fs.joinGame(gameId, matchId);
  }

  void gotoGamePage() {
    if (users.length < 2) {
      Fluttertoast.showToast(msg: "Need 2 players to play");
      return;
    }
    gotoOnlineGamePage(context, game, gameId, matchId, users, indices, 0);
  }

  void getGame() async {
    playingSub = fs.readPlaying(gameId).listen((playing) async {
      if (playing.isEmpty ||
          playing.indexWhere((element) => element.id == myId) == -1) {
        Navigator.of(context).pop();
        return;
      } else if (playing.length == 1 && playing.first.id == myId) {
        leaveGame();
      }
      playing.sortList((value) => value.order, false);
      final playersToRemove = getPlayersToRemove(users, playing);
      if (playersToRemove.isNotEmpty) {
        for (int i = 0; i < playersToRemove.length; i++) {
          final index = playersToRemove[i];
          final user = users[index];
          Fluttertoast.showToast(msg: "${user?.username} left");
          users.removeAt(index);
        }
      }
      if (playing.isNotEmpty) {
        int playersRequested = 0;
        for (int i = 0; i < playing.length; i++) {
          final player = playing[i];
          if (!player.accept) {
            playersRequested++;
          }
        }
        for (int i = 0; i < users.length; i++) {
          final user = users[i];
          final player = playing[i];
          user?.checked = player.accept;
        }

        if (playersRequested == 0) {
          gotoGamePage();
        }
        if (!mounted) return;
        setState(() {});
      }
    });
  }

  void getGroup() async {
    final group = await fs.getGroup(groupId);
    if (group != null) {
      name = group.groupname;
    }
    if (!mounted) return;
    setState(() {});
  }
}
