// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../match/providers/match_provider.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/utils.dart';
import '../services.dart';
import '../utils.dart';
import '../widgets/players_profile_photo.dart';

class NewOnlineGamePage extends ConsumerStatefulWidget {
  final String game;
  final String matchId;
  final String gameId;
  final String creatorId;
  final String creatorName;
  final List<User> users;
  final List<Player> players;
  final Match? match;
  final bool isBottomSheet;

  const NewOnlineGamePage({
    super.key,
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
  ConsumerState<NewOnlineGamePage> createState() => _NewOnlineGamePageState();
}

class _NewOnlineGamePageState extends ConsumerState<NewOnlineGamePage> {
  String matchId = "";
  String gameId = "";
  String game = "";
  String type = "";
  String profilePhoto = "";
  String name = "";
  String creatorId = "";
  bool creatorIsMe = false;
  List<Player> players = [];
  List<User?> users = [];
  List<String> otherUsernames = [];
  Timer? timer;
  StreamSubscription? playingSub;
  int playersSize = 2;
  bool loaded = false;
  late AudioPlayer audioPlayer;
  late StreamSubscription<PlayerState> audioPlayerStateSub;
  Match? match;
  bool addedAllPlayers = false;
  bool isGroup = false;

  @override
  void initState() {
    super.initState();
    playRingTone();
    gameId = widget.gameId;
    matchId = widget.matchId;
    match = widget.match;
    creatorId = widget.creatorId;
    game = widget.game;

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

    getPlayersPlaying();
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
    timer?.cancel();
    super.dispose();
  }

  User? get creator =>
      users.firstWhereNullable((user) => user?.user_id == creatorId);

  void playRingTone() {
    audioPlayer = AudioPlayer();
    audioPlayer.play(AssetSource("audios/game_ringtone.mp3"));
    audioPlayerStateSub = audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        audioPlayer.play(AssetSource("audios/game_ringtone.mp3"));
      }
    });
  }

  void cancel() async {
    if (match == null) return;

    playingSub?.cancel();
    playingSub = null;

    match = await cancelMatch(match!, players);
    // saveMatch(match!);
    context.pop();
  }

  void leave() async {
    if (match == null) return;
    playingSub?.cancel();
    playingSub = null;

    match = await leaveMatch(match!, players);
    // saveMatch(match!);
    context.pop();
  }

  void join() async {
    if (match == null) return;

    match = await joinMatch(match!, game, players);
    saveMatch(match!);
    final index = players.indexWhere((element) => element.id == myId);
    if (index != -1) {
      players[index] = players[index].copyWith(action: "pause");
    }
    showToast("You joined");
    gotoGameIfAllPlayersReady();
    if (!mounted) return;
    setState(() {});
  }

  void saveMatch(Match match) {
    ref.read(matchProvider.notifier).updateMatch(match);
  }

  void gotoGame() {
    if (users.length < 2) {
      showToast("Need at least 2 players to play");
      return;
    }
    players.sortList((player) => player.order ?? 0, false);
    gotoGamePage(context, game, gameId, matchId,
        users: users, players: players, playersSize: playersSize, match: match);
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

    if (players.indexWhere((element) => element.id == myId) == -1) {
      final myPlayer = await getPlayer(gameId, myId);
      if (myPlayer != null) {
        players.add(myPlayer);
      }
    }
    if (users.indexWhere((element) => element?.user_id == myId) == -1) {
      final user = await getUser(myId);
      if (user != null) {
        users.add(user);
      }
    }

    playingSub = getPlayersChange(gameId, matchId: matchId)
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
              "${user?.username} ${value.action == null || value.action == "" ? "added" : "joined"}");
        }
      }

      // if (addedAllPlayers && players.length < 2) {
      //   context.pop();
      //   return;
      // }
      if (addedAllPlayers && players.length == 1 && players.first.id == myId) {
        context.pop();
        return;
      }
      gotoGameIfAllPlayersReady();
      if (match?.players != null && players.length == match!.players!.length) {
        addedAllPlayers = true;
      }

      if (!mounted) return;
      setState(() {});
    });
  }

  void readGame() async {
    if (match == null || match!.players == null) return;

    if (match!.users == null && match!.players != null) {
      List<User> users = await playersToUsers(match!.players!);
      match!.users = users;
    }

    if (match!.game_id == getGameId(match!.players!)) {
      name = getOtherPlayersUsernames(match!.users!);
    } else {
      isGroup = true;
      match!.game ??= await getGame(match!.game_id!);
      name = match!.game!.groupName!;
      profilePhoto = match!.game!.profilePhoto ?? "";
    }

    if (!mounted) return;
    setState(() {});
  }

  void goBack() async {
    final comfirmationType = creatorIsMe ? "cancel" : "dismiss";
    final comfirm = await context.showComfirmationDialog(
        title: "${comfirmationType.capitalize} match",
        message: "Are you sure you want to $comfirmationType game?");
    if (comfirm != true) return;

    if (comfirmationType == "cancel") {
      cancel();
    } else if (comfirmationType == "dismiss") {
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
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isGroup)
                                ProfilePhoto(
                                    profilePhoto: profilePhoto,
                                    name: name,
                                    size: 100)
                              else if (match?.users != null)
                                PlayersProfilePhoto(
                                  users: match!.users!,
                                  withoutMyId: true,
                                  size: 100,
                                ),
                              Text(
                                name,
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 200,
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
        bottomNavigationBar: SizedBox(
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
                  child: AppButton(title: "Join", onPressed: join),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
