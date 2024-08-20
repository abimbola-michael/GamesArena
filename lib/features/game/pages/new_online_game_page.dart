// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/theme/colors.dart';
import '../../group/services.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/utils/utils.dart';
import '../services.dart';
import '../utils.dart';

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
  // String myId = "";
  String type = "";
  String groupId = "";
  String name = "", creatorName = "";
  String creatorId = "";
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
    //myId = myId;
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
          cancel();
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
    get();
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
          cancel();
        } else {
          leave();
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
                  cancel();
                } else {
                  leave();
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
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 200,
                          // width: double.infinity,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionButton(
                  creatorIsMe ? "Cancel" : "Dismiss",
                  onPressed: () {
                    if (creatorIsMe) {
                      cancel();
                    } else {
                      leave();
                    }
                  },
                  height: 50,
                  width: 150,
                  margin: 0,
                  color: darkMode ? lightestWhite : lightestBlack,
                  textColor: darkMode ? white : black,
                ),
                if (!creatorIsMe) ...[
                  const SizedBox(
                    width: 20,
                  ),
                  ActionButton(
                    "Join",
                    onPressed: () {
                      join();
                    },
                    height: 50,
                    width: 150,
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

  void cancel() async {
    await cancelGame(gameId, matchId, playing);
  }

  void leave() async {
    await leaveGame(gameId, matchId, playing, false, 0, 0);
  }

  void join() async {
    await joinGame(gameId, matchId);
  }

  void gotoGame() {
    if (users.length < 2) {
      Fluttertoast.showToast(msg: "Need at least 2 players to play");
      return;
    }
    gotoGamePage(context, game, gameId, matchId, users, playing, playersSize,
        indices, 0);
    //gotoOnlineGamePage(context, game, gameId, matchId, users, indices, 0);
  }

  void get() async {
    playingSub = readPlaying(gameId).listen((playing) async {
      if (playing.isEmpty ||
          playing.indexWhere((element) => element.id == myId) == -1) {
        Navigator.of(context).pop();
        return;
      } else if (playing.length == 1 && playing.first.id == myId) {
        leave();
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
          gotoGame();
        }
        if (!mounted) return;
        setState(() {});
      }
    });
  }

  void readGroup() async {
    final group = await getGroup(groupId);
    if (group != null) {
      name = group.groupname;
    }
    if (!mounted) return;
    setState(() {});
  }
}
