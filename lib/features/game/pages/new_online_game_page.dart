// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import '../../../shared/dialogs/comfirmation_dialog.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../group/services.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/utils/utils.dart';
import '../models/player.dart';
import '../services.dart';
import '../utils.dart';
import '../widgets/players_profile_photo.dart';

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
  final bool isBottomSheet;

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
    this.isBottomSheet = false,
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
  String profilePhoto = "";
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
  bool addedAllPlayers = false;

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

  User? get creator =>
      users.firstWhereNullable((user) => user?.user_id == myId);

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
    await playingSub?.cancel();
    cancelMatch(gameId, matchId, match, players);
    context.pop();
  }

  void leave() async {
    playingSub?.cancel();
    await leaveMatch(gameId, matchId, match, players);
    context.pop();
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
      user?.checked = (player?.action ?? "") != "";
    }

    if (playersRequested == 0 && players.length > 1) {
      gotoGame();
    }
  }

  void getPlayersPlaying() async {
    match ??= await getMatch(gameId, matchId);
    readGame();

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
      } else if (addedAllPlayers &&
          players.length == 1 &&
          players.first.id == myId) {
        leave();
      }
      gotoGameIfAllPlayersReady();
      if (match?.players != null && players.length == match!.players!.length) {
        addedAllPlayers = true;
      }

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
    if (match == null) return;
    if (match!.users == null && match!.players != null) {
      List<User> users = await playersToUsers(match!.players!);
      match!.users = users;
    } else if (match!.players == null || match!.players!.isEmpty) {
      final game = await getGame(match!.game_id!);
      match!.game = game;
    }
    if (match!.users != null && match!.users!.isNotEmpty) {
      name = getOtherPlayersUsernames(match!.users!);
    } else if (match!.game != null) {
      name = match!.game!.groupName!;
      profilePhoto = match!.game!.profilePhoto ?? "";
      //game = match!.game ?? "";
    }

    if (!mounted) return;
    setState(() {});
  }

  void goBack() async {
    final comfirmationType = creatorIsMe ? "cancel" : "leave";
    final comfirm = await context.showComfirmationDialog(
        title: "${comfirmationType.capitalize} match",
        message: "Are you sure you want to $comfirmationType game?");
    if (comfirm == null) return;

    if (comfirmationType == "cancel") {
      cancel();
    } else if (comfirmationType == "leave") {
      leave();
    }
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
        appBar: widget.isBottomSheet
            ? null
            : AppAppBar(title: "New Game", onBackPressed: goBack),
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
                            if (match?.users != null)
                              PlayersProfilePhoto(
                                users: match!.users!,
                                withoutMyId: true,
                              )
                            else
                              ProfilePhoto(
                                  profilePhoto: profilePhoto, name: name),
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Online $game game",
                                    style: context.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "From ${creator?.username ?? ""}",
                                    style: context.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
                                    showCheck: false, user: user, type: "");
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
          //height: 50,
          width: double.infinity,
          //margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AppButton(
                  title: creatorIsMe ? "Cancel" : "Dismiss",
                  onPressed: goBack,
                  bgColor: Colors.red,
                ),
              ),
              if (!creatorIsMe) ...[
                // const SizedBox(
                //   width: 20,
                // ),
                Expanded(
                  child: AppButton(
                    title: "Join",
                    onPressed: join,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
