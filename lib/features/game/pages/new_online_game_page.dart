// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import '../../../shared/dialogs/comfirmation_dialog.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../group/services.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/utils/utils.dart';
import '../models/player.dart';
import '../services.dart';
import '../utils.dart';

class NewOnlineGamePage extends StatefulWidget {
  final String game;
  final String matchId;
  final String gameId;
  final String creatorId;
  final String creatorName;
  final List<User> users;
  final List<Player> players;
  final String indices;
  final Match? match;

  const NewOnlineGamePage({
    super.key,
    required this.indices,
    required this.users,
    required this.players,
    required this.gameId,
    required this.matchId,
    required this.game,
    required this.creatorId,
    required this.creatorName,
    this.match,
  });

  @override
  State<NewOnlineGamePage> createState() => _NewOnlineGamePageState();
}

class _NewOnlineGamePageState extends State<NewOnlineGamePage> {
  String matchId = "";
  String gameId = "";
  String game = "";
  String type = "";
  String name = "" /*, creatorName = ""*/;
  String creatorId = "";
  bool creatorIsMe = false;
  List<Player> players = [];
  List<User?> users = [];
  List<String> otherUsernames = [];
  Timer? timer;
  StreamSubscription? playingSub;
  int playersSize = 2;
  String indices = "";
  bool loaded = false;
  late AudioPlayer audioPlayer;
  late StreamSubscription<PlayerState> audioPlayerStateSub;
  // String comfirmationType = "";
  Match? match;

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
    gameId = widget.gameId;
    matchId = widget.matchId;
    creatorId = widget.creatorId;
    match = widget.match;
    //creatorName = widget.creatorName;
    game = widget.game;
    indices = widget.indices;
    if (widget.players.isNotEmpty) {
      players = widget.players;
      players.sortList((value) => value.order, false);
    }
    if (widget.users.isNotEmpty && widget.players.isNotEmpty) {
      users = widget.users.sortWithStringList(
          players.map((e) => e.id).toList(), (user) => user.user_id);
    }

    if (creatorId == myId) {
      creatorIsMe = true;
      timer = Timer(const Duration(minutes: 2), () async {
        if (!mounted) return;
        if (players.isNotEmpty) {
          cancel();
        }
      });
    }
    // List<User?> otherUsers =
    //     users.where((user) => user != null && user.user_id != myId).toList();
    // if (!creatorIsMe) {
    //   otherUsers
    //       .removeWhere((user) => user != null && user.user_id == creatorId);
    // }
    // otherUsernames = otherUsers.isEmpty
    //     ? []
    //     : otherUsers.map((e) => e?.username ?? "").toList();
    // if (!creatorIsMe) {
    //   otherUsernames.insert(0, "you");
    // }
    //readGame();
    getPlayersPlaying();
  }

  String get creatorName =>
      users
          .firstWhere(
            (user) => user?.user_id == myId,
            orElse: () => null,
          )
          ?.username ??
      "";

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

  void cancel() async {
    await cancelMatch(gameId, matchId, players);
  }

  void leave() async {
    await leaveMatch(gameId, matchId, match, players, false, 0, 0);
  }

  void join() async {
    await joinMatch(gameId, matchId, game, players);
  }

  void gotoGame() {
    if (users.length < 2) {
      showToast("Need at least 2 players to play");
      return;
    }
    gotoGamePage(context, game, gameId, matchId,
        users: users,
        players: players,
        playersSize: playersSize,
        indices: indices,
        match: match);
  }

  void gotoGameIfAllPlayersReady() {
    int playersRequested = 0;
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      if (player.action == null || player.action == "") {
        playersRequested++;
      }
    }
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final player = players.firstWhereNullable((t) => t.id == user?.user_id);
      user?.checked = player?.action != "";
    }

    if (playersRequested == 0 && players.length > 1) {
      gotoGame();
    }
  }

  void getPlayersPlaying() async {
    match ??= await getMatch(gameId, matchId);

    playingSub = getPlayersChange(gameId, matchId: matchId, excludingMe: false)
        .listen((playersChanges) async {
      for (int i = 0; i < playersChanges.length; i++) {
        final playersChange = playersChanges[i];
        final value = playersChange.value;

        final index = players.indexWhere((element) => element.id == value.id);
        final userIndex =
            users.indexWhere((element) => element?.user_id == value.id);
        User? user;
        if (userIndex == -1) {
          user = await getUser(value.id);
          users.add(user);
        } else {
          user = users[userIndex];
        }
        if (playersChange.removed ||
            value.matchId == null ||
            value.matchId == "") {
          if (index != -1) {
            players.removeAt(index);
          }
          showToast("${user?.username} left");
        } else {
          if (index != -1) {
            players[index] = value;
          } else {
            players.add(value);
          }
          showToast(
              "${user?.username} ${value.action == null || value.action == "" ? "added" : "accepted"}");
        }
      }

      if (players.isEmpty ||
          players.indexWhere((element) => element.id == myId) == -1) {
        context.pop();
        return;
      }
      // else if (players.length == 1 && players.first.id == myId) {
      //   leave();
      //   context.pop();
      // }
      gotoGameIfAllPlayersReady();

      if (!mounted) return;
      setState(() {});
    });
    // playingSub = readPlayersStream(gameId, matchId).listen((players) async {
    //   if (players.isEmpty ||
    //       players.indexWhere((element) => element.id == myId) == -1) {
    //     Navigator.of(context).pop();
    //     return;
    //   } else if (players.length == 1 && players.first.id == myId) {
    //     leave();
    //   }
    //   //players.sortList((value) => value.order, false);
    //   final playersToRemove = getPlayersToRemove(users, players);
    //   if (playersToRemove.isNotEmpty) {
    //     for (int i = 0; i < playersToRemove.length; i++) {
    //       final index = playersToRemove[i];
    //       final user = users[index];
    //       Fluttertoast.showToast(msg: "${user?.username} left");
    //       users.removeAt(index);
    //     }
    //   }
    //   if (players.isNotEmpty) {
    //     int playersRequested = 0;
    //     for (int i = 0; i < players.length; i++) {
    //       final player = players[i];
    //       if (player.action == null) {
    //         playersRequested++;
    //       }
    //     }
    //     for (int i = 0; i < users.length; i++) {
    //       final user = users[i];
    //       final player = players[i];
    //       user?.checked = player.action != null;
    //     }

    //     if (playersRequested == 0) {
    //       gotoGame();
    //     }
    //     if (!mounted) return;
    //     setState(() {});
    //   }
    // });
  }

  void readGame() async {
    final game = await getGame(gameId);
    if (game != null) {
      if (game.groupName != null) {
        name = game.groupName!;
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  void goBack() async {
    // if (comfirmationType.isEmpty) {
    //   comfirmationType = "cancel";
    // } else {
    //   comfirmationType = "leave";
    // }
    // setState(() {});

    final comfirmationType = creatorIsMe ? "cancel" : "leave";

    await showDialog(
        context: context,
        builder: (context) {
          return ComfirmationDialog(
            title: "Are you sure you want to $comfirmationType game?",
            message: getMoreInfoOnComfirmation(comfirmationType),
            onPressed: (positive) {
              if (positive) {
                if (comfirmationType == "cancel") {
                  cancel();
                } else if (comfirmationType == "leave") {
                  leave();
                }
              }
              if (!mounted) return;
              // setState(() {
              //   comfirmationType = "";
              // });
            },
          );
        });

    context.pop();
  }

  String getMoreInfoOnComfirmation(String comfirmationType) {
    String message = "";
    switch (comfirmationType) {
      case "cancel":
        message = "This means this game ends";
        break;
      case "leave":
        message = "This means you are out of the game";
        break;
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: players.isEmpty ||
          players.indexWhere((element) => element.id == myId) == -1,
      onPopInvoked: (pop) {
        if (pop) return;
        goBack();
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: "New Game",
          onBackPressed: goBack,
        ),
        body: players.isEmpty || users.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            //:
            // comfirmationType.isNotEmpty
            //     ? Center(
            //         child: ComfirmationDialog(
            //           title:
            //               "Are you sure you want to $comfirmationType game?",
            //           message: getMoreInfoOnComfirmation(),
            //           onPressed: (positive) {
            //             if (positive) {
            //               if (comfirmationType == "cancel") {
            //                 cancel();
            //               } else if (comfirmationType == "leave") {
            //                 leave();
            //               }
            //               context.pop();
            //             }
            //             if (!mounted) return;
            //             setState(() {
            //               comfirmationType = "";
            //             });
            //           },
            //         ),
            //       )
            : Center(
                child: SingleChildScrollView(
                  primary: true,
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
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
                            Text(
                              creatorName,
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Online $game game",
                                // players.isEmpty
                                //     ? ""
                                //     : creatorIsMe
                                //         ? "You created a $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}"
                                //         : "$creatorName will like to play $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}",
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
              ),
        //    players.isEmpty || users.isEmpty
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
                onPressed: goBack,
                // onPressed: () {
                //   if (creatorIsMe) {
                //     cancel();
                //   } else {
                //     leave();
                //   }
                // },
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
    );
  }
}
