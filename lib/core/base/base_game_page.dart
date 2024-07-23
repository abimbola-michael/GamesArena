import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/utils/constants.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../features/game/services.dart';
import '../../features/game/utils.dart';
import '../../features/games/whot/widgets/whot_card.dart';
import '../../features/records/services.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/game_timer.dart';
import '../../main.dart';
import '../../shared/models/models.dart';
import '../../theme/colors.dart';
import '../../shared/utils/utils.dart';
import '../../features/game/pages/paused_game_page.dart';
import '../../features/home/tabs/games_page.dart';

abstract class BaseGamePage extends StatefulWidget {
  // final String? matchId;
  // final String? gameId;
  // final List<User?>? users;
  // final int? playersSize;
  // final String? indices;
  // final int? id;
  const BaseGamePage({
    super.key,
    // this.matchId,
    // this.gameId,
    // this.users,
    // this.playersSize,
    // this.indices,
    // this.id
  });

  @override
  State<BaseGamePage> createState();
  //State<BaseGamePage> createState() => _BaseGamePageState();
}

abstract class BaseGamePageState<T extends BaseGamePage> extends State<T>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  void onStart();
  void onPause();
  void onConcede(int index);
  void onLeave(int index);
  void onPlayerTimeEnd();
  void onTimeEnd();
  void onKeyEvent(KeyEvent event);
  void onSpaceBarPressed();
  void onDetailsChange(Map<String, dynamic>? map);
  void onPlayerChange();
  Widget buildBody(BuildContext context);
  Widget buildBottomOrLeftChild(int index);

  abstract String gameName;
  abstract int maxGameTime;

  int pauseIndex = 0;

  String matchId = "";
  String gameId = "";
  List<User?>? users;
  int playersSize = 2;
  String? indices;
  int id = 0;
  String myId = "";

  //Call
  StreamSubscription? signalSub;
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  //final Map<String, List<RTCIceCandidate>> _rtcIceCandidates = {};
  MediaStream? _localStream;

  //Playing
  //StreamSubscription<List<Playing>>? playingSub;
  StreamSubscription? playingSub;
  StreamSubscription? detailsSub;
  StreamSubscription? signalsSub;
  List<Playing> playing = [];

  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool changingGame = false;
  String reason = "";
  late StreamController<int> timerController;
  StreamController<int>? timerController2;

  //Time
  Timer? timer;
  int duration = 0, gameTime = 0, gameTime2 = 0;

  //Ads
  int adsTime = 0;
  bool adLoaded = false;
  bool awaiting = false;

  InterstitialAd? _interstitialAd;

  bool paused = true,
      finishedRound = false,
      checkout = false,
      pausePlayerTime = false;

  String currentPlayerId = "";
  int currentPlayer = 0;
  int myPlayer = 0;
  int playerTime = maxPlayerTime;

  //Sizing
  double padding = 0;
  double minSize = 0, maxSize = 0;
  bool landScape = false;

  //Card
  double cardWidth = 0, cardHeight = 0;

  String message = "", hintMessage = "";

  List<int> playersCounts = [];
  List<int> playersScores = [];
  List<int> players = [];
  List<int> concedePlayers = [];

  List<String> playersToasts = [];
  List<String> playersMessages = [];

  bool gottenDependencies = false;
  bool isCard = false;
  bool showMessage = true;
  bool isChessOrDraught = false;
  bool needsPlayertime = false;
  bool isMyTurn = false;
  bool detailsSent = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    isCard = gameName == "Whot";
    myId = myId;
    isChessOrDraught = gameName == chessGame || gameName == draughtGame;
    needsPlayertime =
        gameName == ludoGame || gameName == whotGame || gameName == xandoGame;
    isMyTurn = currentPlayerId == myId;

    timerController = StreamController.broadcast();
    if (isChessOrDraught) {
      timerController2 = StreamController.broadcast();
    }

    // if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    //   ServicesBinding.instance.keyboard.addHandler(_onKey);
    // }
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    landScape = context.isLandscape;
    minSize = context.minSize;
    maxSize = context.maxSize;
    padding = context.remainingSize;
    cardHeight = (minSize - 80) / 3;
    cardWidth = cardHeight.percentValue(65);
    // padding = (context.screenHeight - context.screenWidth).abs() / 2;
    if (!gottenDependencies) {
      if (context.args != null) {
        matchId = context.args["matchId"] ?? "";
        gameId = context.args["gameId"] ?? "";
        users = context.args["users"];
        playersSize = context.args["playersSize"] ?? 2;
        indices = context.args["indices"];
        id = context.args["id"] ?? 0;
      }
      // print(
      //     "matchId = $matchId, gameId = $gameId, users = $users, playersSize = $playersSize, indices = $indices, id = $id");

      gottenDependencies = true;
      init();
    }
  }

  @override
  void dispose() {
    timerController.close();
    timerController2?.close();
    // if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    //   ServicesBinding.instance.keyboard.removeHandler(_onKey);
    // }
    WidgetsBinding.instance.removeObserver(this);
    if (!changingGame) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
    detailsSub?.cancel();
    playingSub?.cancel();
    disposeForCall();

    stopTimer();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      if (!paused) {
        pause();
      }
    }
  }

  void stopTimer() {
    paused = true;
    timer?.cancel();
    timer = null;
  }

  void startTimer() {
    pausePlayerTime = false;
    paused = false;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || awaiting) return;

      if (adsTime >= maxAdsTime) {
        loadAd();
        adsTime = 0;
      } else {
        adsTime++;
      }

      duration++;

      if (currentPlayer == 1 && isChessOrDraught) {
        if (gameTime2 <= 0) {
          timer.cancel();
          onTimeEnd();
          updateWin(0);
        }

        gameTime2--;
        timerController2?.sink.add(gameTime2);
      } else {
        if (gameTime <= 0) {
          timer.cancel();
          onTimeEnd();
          if (isChessOrDraught) {
            updateWin(1);
          }
        }

        gameTime--;
        timerController.sink.add(gameTime);
      }
      if (needsPlayertime) {
        if (playerTime <= 0) {
          onPlayerTimeEnd();
          //changePlayer();
          setState(() {});
        } else {
          playerTime--;
        }
      }
    });
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if ((key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.escape) &&
          !paused) {
        pause();
      } else if (key == LogicalKeyboardKey.enter && paused) {
        start();
      } else if (key == LogicalKeyboardKey.space && !paused) {
        onSpaceBarPressed();
      } else {
        onKeyEvent(event);
      }
    }
    return false;
  }

  void getCurrentPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      currentPlayerId = playerIds.last;
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      currentPlayer = currentPlayerIndex;
    } else {
      currentPlayer = playersSize - 1;
    }
  }

  void changePlayer([bool suspend = false]) {
    playerTime = maxPlayerTime;
    onPlayerChange();
    //message = "Your Turn";
    getNextPlayer();
    if (suspend) getNextPlayer();
  }

  // void getNextPlayer() {
  //   final lastIndex = players.indexWhere((element) => element == currentPlayer);
  //   final nextIndex = lastIndex == players.length - 1 ? 0 : lastIndex + 1;
  //   currentPlayer = players[nextIndex];
  // }

  void getNextPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      int nextPlayerIndex = nextIndex(playersSize, currentPlayerIndex);
      String playerId = playerIds[nextPlayerIndex];
      while (playing.indexWhere((element) => element.id == playerId) == -1) {
        nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
        playerId = playerIds[nextPlayerIndex];
      }
      currentPlayer = nextPlayerIndex;
      currentPlayerId = playerId;
    } else {
      currentPlayer = nextIndex(playersSize, currentPlayer);
    }
  }

  int getPartnerPlayer() {
    if (playersSize == 2) return -1;
    return myPlayer == 0
        ? 1
        : myPlayer == 1
            ? 0
            : myPlayer == 2
                ? 3
                : 2;
  }

  void getFirstPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      currentPlayerId = playerIds.last;
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      currentPlayer = currentPlayerIndex;
    } else {
      currentPlayer = playersSize - 1;
    }
  }

  void readPlayersPlaying() {
    if (gameId == "" || matchId == "") return;
    final users = this.users!;
    if (playingSub != null) return;
    getFirstPlayer();

    playingSub = readPlayingChange(gameId).listen((playingChanges) {
      for (int i = 0; i < playingChanges.length; i++) {
        final playingChange = playingChanges[i];
        final value = playingChange.value;
        final playingIndex =
            playing.indexWhere((element) => element.id == value.id);
        final userIndex =
            users.indexWhere((element) => element?.user_id == value.id);
        final username =
            userIndex == -1 ? "" : users[userIndex]?.username ?? "";
        if (playingChange.added) {
          playing.add(value);
          Fluttertoast.showToast(msg: "$username joined");
        } else if (playingChange.modified) {
          if (playingIndex != -1) {
            playing[playingIndex] = value;
            final message = value.game != gameName
                ? "changed to ${value.game}"
                : playing[playingIndex].action != value.action
                    ? value.action
                    : "";
            if (message.isNotEmpty) {
              Fluttertoast.showToast(msg: "$username $message");
            }
          }
        } else if (playingChange.removed) {
          Fluttertoast.showToast(msg: "$username left");

          if (value.id == myId) {
            leave(true);
          }
          if (currentPlayer == userIndex) {
            getNextPlayer();
          }

          if (playingIndex != -1) {
            playing.removeAt(playingIndex);
          }
        }
        String action = getAction(playing);
        if (action == "pause") {
          if (!paused) {
            pause(true);
          }
        } else if (action == "start") {
          if (paused) {
            start(true);
          }
        } else if (action == "restart") {
          restart(true);
        }
        String newgame = getChangedGame(playing);
        if (newgame.isNotEmpty && newgame != gameName) {
          change(newgame, true);
        }
        //playing.sortList((value) => value.order, false);
        setState(() {});
      }
    });
    // playingSub = readPlaying(gameId).listen((playing) async {
    //   playing.sortList((value) => value.order, false);
    //   if (playing.indexWhere((element) => element.id == myId) == -1) {
    //     leave(true);
    //     return;
    //   } else if (playing.length == 1 && playing.first.id == myId) {
    //     leave();
    //     return;
    //   }
    //   final playersToRemove = getPlayersToRemove(users, playing);
    //   if (playersToRemove.isNotEmpty) {
    //     List<String> playersLeft = [];
    //     for (int i = 0; i < playersToRemove.length; i++) {
    //       final playerIndex = playersToRemove[i];
    //       final user = users[playerIndex];
    //       if (user != null) {
    //         playersLeft.add(user.username);
    //       }
    //       if (currentPlayer == playerIndex) {
    //         getNextPlayer();
    //       }
    //     }
    //     Fluttertoast.showToast(
    //         msg: "${playersLeft.toStringWithCommaandAnd((name) => name)} left");
    //   }
    //   String newActionMessage = "";
    //   String actionUsername = "";
    //   for (int i = 0; i < users.length; i++) {
    //     final user = users[i];
    //     if (user != null) {
    //       final index =
    //           playing.indexWhere((element) => element.id == user.user_id);
    //       if (index == -1) {
    //         user.action = "left";
    //         continue;
    //       }
    //       final value = playing[index];
    //       if (value.game != gameName) {
    //         final changeAction = "changed to ${value.game}";
    //         if (user.action != changeAction) {
    //           user.action = changeAction;
    //           newActionMessage = user.action;
    //           actionUsername = user.username;
    //         }
    //       } else if (user.action != value.action) {
    //         user.action = value.action;
    //         newActionMessage = user.action;
    //         actionUsername = user.username;
    //       }
    //     }
    //   }
    //   if (newActionMessage != "") {
    //     Fluttertoast.showToast(
    //         msg: "$actionUsername ${getActionString(newActionMessage)}");
    //   }
    //   String action = getAction(playing);
    //   if (action == "pause") {
    //     if (!paused) {
    //       pause(true);
    //     }
    //   } else if (action == "start") {
    //     if (paused) {
    //       start(true);
    //     }
    //   } else if (action == "restart") {
    //     restart(true);
    //   }
    //   String newgame = getChangedGame(playing);
    //   if (newgame != "" && newgame != gameName) {
    //     change(newgame, true);
    //   }
    //   this.playing = playing;
    //   setState(() {});
    // });
  }

  void checkFirstime() async {
    int playTimes = sharedPref.getInt(gameName) ?? 0;
    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref.setInt(gameName, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void init() {
    pauseIndex = playersSize - 1;
    checkFirstime();
    initScores();
    initPlayers();
    initMessages();
    initPlayersCounts();
    initToasts();
    getCurrentPlayer();
    start();
    readDetails();
  }

  void readDetails() {
    if (matchId != "" && gameId != "" && users != null) {
      final index = users!
          .indexWhere((element) => element != null && element.user_id == myId);
      myPlayer = index;

      readPlayersPlaying();
      detailsSub = getGameDetailsChange(gameId).listen((detailsChanges) {
        for (int i = 0; i < detailsChanges.length; i++) {
          final detailsChange = detailsChanges[i];
          if (detailsChange.added) {
            onDetailsChange(detailsChange.value);
          }
        }
      });
      // detailsSub =
      //     getGameDetails(gameId).listen((details) => onDetailsChange(details));
    }
  }

  void loadAd() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    final key = await getPrivateKey();
    if (kIsWeb || key == null) return;
    final mobileAdUnit = key.mobileAdUnit;
    InterstitialAd.load(
        adUnitId: mobileAdUnit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {
                  stopTimer();
                },
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  // startTimer();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  // startTimer();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
            _interstitialAd!.show();
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            // startTimer();
          },
        ));
  }

  void resetIfPlayerLeave() {
    if (users != null) {
      final playersToRemove = getPlayersToRemove(users!, playing);
      if (playersToRemove.isNotEmpty) {
        for (int i = 0; i < playersToRemove.length; i++) {
          final playerIndex = playersToRemove[i];
          users!.removeAt(playerIndex);
          playersScores.removeAt(playerIndex);
          final index = users!.indexWhere(
              (element) => element != null && element.user_id == myId);
          myPlayer = index;
        }
      }
    }
  }

  void initPlayersCounts() {
    playersCounts = List.generate(playersSize, (index) => -1);
  }

  void initPlayers() {
    players = List.generate(playersSize, (index) => index);
  }

  void initScores() {
    playersScores = List.generate(playersSize, (index) => 0);
  }

  void initToasts() {
    playersToasts = List.generate(playersSize, (index) => "");
  }

  void initMessages() {
    playersMessages = List.generate(playersSize, (index) => "");
  }

  void showToast(int playerIndex, String message) {
    setState(() {
      playersToasts[playerIndex] = message;
    });
  }

  int getTurn(int index) {
    int turn = 0;
    if (index == 0) {
      turn = 2;
    } else if (index == 1 && playersSize > 2) {
      turn = 3;
    } else if (index == 3) {
      turn = 1;
    }
    return turn;
  }

  String getMessage(int index) {
    String message = playersMessages[index];
    String fullMessage = "";
    // fullMessage =
    //     "${message != "" ? "$message${message.endsWith("\n") ? "" : "\n"}" : ""}${index != currentPlayer ? "" : playersSize > 2 ? "${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s Turn" : "Your Turn"}";
    //  fullMessage = "$message${index == currentPlayer ? "-Your Turn" : ""}";
    fullMessage = message != ""
        ? message
        : currentPlayer == index
            ? "Your Turn"
            : "";
    if (currentPlayer == index) {
      return "$fullMessage - $playerTime";
    } else {
      return fullMessage;
    }
  }

  void updateTie(List<int> players, {String? reason}) {
    reason ??= this.reason;
    finishedRound = true;
    updateRecord();
    toastWinners(players, reason: reason);
    pause();
    if (concedePlayers.isNotEmpty) {
      concedePlayers.clear();
    }
  }

  void updateWin(int player, {String? reason}) {
    reason ??= this.reason;

    finishedRound = true;
    playersScores[player]++;
    updateRecord();
    toastWinner(player, reason: reason);
    pause();
    if (concedePlayers.isNotEmpty) {
      concedePlayers.clear();
    }
  }

  void updateDraw({String? reason}) {
    reason ??= this.reason;
    finishedRound = true;
    //updateRecord();
    toastDraw(reason: reason);
    pause();
    if (concedePlayers.isNotEmpty) {
      concedePlayers.clear();
    }
  }

  void toastDraw({String? reason}) {
    String message = "It's a draw";
    if (reason != null) {
      message += " with $reason";
    }
    if (isCard) {
      for (int i = 0; i < playersSize; i++) {
        showToast(i, message);
      }
    } else {
      showToast(0, message);
      showToast(1, message);
    }
  }

  void toastWinner(int player, {String? reason}) {
    String message =
        "${users != null ? users![player]?.username ?? "" : "Player $player"} won";
    if (reason != null) {
      message += " with $reason";
    }
    if (isCard) {
      for (int i = 0; i < playersSize; i++) {
        showToast(i, message);
      }
    } else {
      showToast(0, message);
      showToast(1, message);
    }
  }

  void toastWinners(List<int> players, {String? reason}) {
    String message = "";
    String name = "";
    if (users != null) {
      final usernames = players.map((e) => users![e]!.username).toList();
      name = usernames.toStringWithCommaandAnd((username) => username);
    } else {
      name = players.toStringWithCommaandAnd(
          (player) => "${player + 1}", "Player ");
    }
    if (players.length == 1) {
      playersScores[players.first]++;
      message = "$name won";
    } else {
      message = "It's a tie between $name";
    }
    if (reason != null) {
      message += " with $reason";
    }

    for (int i = 0; i < playersSize; i++) {
      showToast(i, message);
    }
  }

  List<int> convertToGrid(int pos, int gridSize) {
    return [pos % gridSize, pos ~/ gridSize];
  }

  int convertToPosition(List<int> grids, int gridSize) {
    return grids[0] + (grids[1] * gridSize);
  }

  String getUsername(String userId) =>
      users
          ?.firstWhere(
              (element) => element != null && element.user_id == userId)
          ?.username ??
      "";

  void startOrRestart(bool start) {
    if (gameId != "" && matchId != "") {
      updateAction(
          context,
          playing,
          users!,
          gameId,
          matchId,
          myId,
          start ? "start" : "restart",
          gameName,
          gameTime < maxGameTime,
          id,
          gameTime);
    }
  }

  void pause([bool act = false]) {
    if (act || gameId == "") {
      stopTimer();
      onPause();
      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        pauseGame(gameId, matchId, playing, id, duration);
      }
    }
  }

  void concede([bool act = false]) {
    if (pauseIndex == currentPlayer) {
      changePlayer();
    }
    pauseIndex = currentPlayer;

    if (playersSize == 2) {
      updateWin(pauseIndex);
    } else {
      concedePlayers.add(pauseIndex);
      onConcede(pauseIndex);
    }
  }

  void start([bool act = false]) {
    if (act || gameId == "") {
      if (finishedRound || gameTime == 0) {
        reason = "";
        message = "Your Turn";
        gameTime = maxGameTime;
        timerController.sink.add(gameTime);
        if (isChessOrDraught) {
          gameTime2 = maxGameTime;
          timerController2!.sink.add(gameTime);
        }
        checkFirstime();
        onStart();
        finishedRound = false;
      }
      resetIfPlayerLeave();

      startTimer();
      if (!mounted) return;

      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        startOrRestart(true);
      }
    }
  }

  void restart([bool act = false]) {
    if (act || gameId == "") {
      id++;
      finishedRound = true;
      initScores();
      start(act);
    } else {
      if (gameId != "" && matchId != "") {
        startOrRestart(false);
      }
    }
  }

  void change(String game, [bool act = false]) async {
    if (game == gameName) {
      Fluttertoast.showToast(
          msg:
              "You are currently playing $game. Choose another game to change to");
      return;
    }
    if (act || gameId == "") {
      //changingGame = true;
      //id++;
      if (gameId != "") {
        resetIfPlayerLeave();
      }
      gotoGamePage(context, game, gameId, matchId, users,
          users?.length ?? playersSize, null, id);
    } else {
      changeGame(game, gameId, matchId, playing, id, maxGameTime - gameTime);
    }
  }

  void leave([bool act = false]) {
    onLeave(pauseIndex);
    if (act || gameId == "") {
      if (players.length == 2) {}
      context.pop();
    } else {
      if (gameId != "" && matchId != "") {
        leaveGame(gameId, matchId, playing, gameTime < maxGameTime, id,
            maxGameTime - gameTime);
      }
    }
  }

  void resetUsers() {
    if (gameId != "" && users != null) {
      List<User?> users = this.users!.sortWithStringList(
          playing.map((e) => e.id).toList(), (user) => user?.user_id ?? "");
      this.users = users;
    }
  }

  void selectNew() async {
    final newgame = await (Navigator.of(context).push(MaterialPageRoute(
        builder: ((context) => const GamesPage(isCallback: true))))) as String?;
    if (newgame != null) {
      if (newgame == gameName) {
        Fluttertoast.showToast(
            msg:
                "You are currently playing $newgame. Choose another game to change to");
        return;
      }
      change(newgame);
    }
  }

  void updateRecord() {
    if (matchId != "" && gameId != "" && currentPlayerId == myId) {
      int score = playersScores[myPlayer];
      updateMatchRecord(gameId, matchId, myPlayer, id, score);
    }
  }

  void disposeForCall() {
    signalSub?.cancel();
    _localRenderer?.dispose();
    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    for (var pc in _peerConnections.values) {
      pc.dispose();
    }
    _localStream?.dispose();

    _remoteRenderers.clear();
    _peerConnections.clear();
    signalSub = null;
    _localStream = null;
    _localRenderer = null;
  }

  void _disposeForUser(String peerId) {
    _remoteRenderers[peerId]?.dispose();
    _peerConnections[peerId]?.dispose();
    _remoteRenderers.remove(peerId);
    _peerConnections.remove(peerId);

    if (_peerConnections.isEmpty) {
      signalSub?.cancel();
      _localRenderer?.dispose();
      _localStream?.dispose();
      signalSub = null;
      _localStream = null;
      _localRenderer = null;
    }
  }

  Future initForVideoCall() async {
    await _initializeRenderers();
  }

  Future initForCall() async {
    await _initializeLocalStream();
  }

  Future<void> _initializeRenderers() async {
    if (_localRenderer != null) return;
    _localRenderer = RTCVideoRenderer();
    await _localRenderer?.initialize();
  }

  Future<void> _initializeLocalStream() async {
    if (_localStream != null) return;
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });
    _localRenderer?.srcObject = _localStream;
  }

  void startCall() {
    if (gameId == "") return;
    // _selfId = _signalingCollection.doc().id;
    // _signalingCollection.doc(_selfId).set({'type': 'register'});
    addSignal(gameId, myId, {'type': 'register', "id": myId});
    _listenForSignalingMessages();
  }

  void _listenForSignalingMessages() async {
    if (gameId == "") return;
    await signalSub?.cancel();
    signalSub = streamChangeSignals(gameId).listen((signalsChanges) {
      for (int i = 0; i < signalsChanges.length; i++) {
        final signalChange = signalsChanges[i];
        final data = signalChange.value;
        final type = data["type"];
        final id = data["id"];

        if (id != myId) {
          if (signalChange.added || signalChange.modified) {
            switch (type) {
              case 'offer':
                _handleOffer(id, data['sdp']);
                break;
              case 'answer':
                _handleAnswer(id, data['sdp']);
                break;
              case 'candidate':
                _handleCandidate(id, data['candidate']);
                break;
              case 'register':
                _createPeerConnection(id);
                break;
            }
          } else if (signalChange.removed) {
            _disposeForUser(id);
          }
        }
      }
    });
    // _signalingCollection = FirebaseFirestore.instance
    //     .collection("watch")
    //     .doc(currentWatchId!)
    //     .collection("signaling");
    // _signalingCollection.snapshots().listen((snapshot) {
    //   for (var change in snapshot.docChanges) {
    //     if (change.type == DocumentChangeType.added &&
    //         change.doc.id != _selfId) {
    //       var data = change.doc.map;
    //       if (data == null) return;
    //       switch (data['type']) {
    //         case 'offer':
    //           _handleOffer(change.doc.id, data['sdp']);
    //           break;
    //         case 'answer':
    //           _handleAnswer(change.doc.id, data['sdp']);
    //           break;
    //         case 'candidate':
    //           _handleCandidate(change.doc.id, data['candidate']);
    //           break;
    //         case 'register':
    //           _createPeerConnection(change.doc.id);
    //           break;
    //       }
    //     }
    //   }
    // });
  }

  Future<void> _createPeerConnection(String peerId) async {
    await initForCall();
    var pc = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });
    _peerConnections[peerId] = pc;

    pc.onIceCandidate = (candidate) {
      if (gameId == "") return;
      addSignal(gameId, peerId,
          {'type': 'candidate', "id": peerId, 'candidate': candidate.toMap()});
      // _signalingCollection.doc(peerId).set(
      //     {'type': 'candidate', 'candidate': candidate.toMap()},
      //     SetOptions(merge: true));
    };

    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        if (!_remoteRenderers.containsKey(peerId)) {
          var renderer = RTCVideoRenderer();
          renderer.initialize();
          _remoteRenderers[peerId] = renderer;
        }
        _remoteRenderers[peerId]?.srcObject = event.streams[0];
      }
    };

    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    if (_peerConnections.keys.length == 1) {
      var offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      if (gameId == "") return;
      addSignal(
          gameId, peerId, {'type': 'offer', "id": peerId, 'sdp': offer.sdp});
      // _signalingCollection
      //     .doc(peerId)
      //     .set({'type': 'offer', 'sdp': offer.sdp}, SetOptions(merge: true));
    }
  }

  Future<void> _handleOffer(String from, String sdp) async {
    await initForCall();
    var pc = _peerConnections[from];
    if (pc == null) {
      await _createPeerConnection(from);
      pc = _peerConnections[from];
    }
    await pc?.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    var answer = await pc?.createAnswer();
    await pc?.setLocalDescription(answer!);

    if (gameId == "") return;
    addSignal(gameId, from, {'type': 'answer', "id": from, 'sdp': answer!.sdp});
    // _signalingCollection
    //     .doc(from)
    //     .set({'type': 'answer', 'sdp': answer!.sdp}, SetOptions(merge: true));
  }

  Future<void> _handleAnswer(String from, String sdp) async {
    await initForCall();
    var pc = _peerConnections[from];
    await pc?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> _handleCandidate(
      String from, Map<String, dynamic> candidate) async {
    await initForCall();
    var pc = _peerConnections[from];
    var rtcCandidate = RTCIceCandidate(candidate['candidate'],
        candidate['sdpMid'], candidate['sdpMLineIndex']);
    await pc?.addCandidate(rtcCandidate);
  }

  _leaveCall() {
    context.pop();
  }

  _toggleMic() {
    isAudioOn = !isAudioOn;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    isVideoOn = !isVideoOn;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    _localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  Widget getPlayerBottomWidget(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          width: 20,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                users != null
                    ? users![index]?.username ?? ""
                    : "Player ${index + 1}",
                style: TextStyle(
                    fontSize: 18,
                    color: currentPlayer == index ? Colors.blue : tint),
                textAlign: TextAlign.center,
              ),
            ),
            if (playersCounts.isNotEmpty &&
                index < playersCounts.length &&
                playersCounts[index] != -1)
              CountWidget(count: playersCounts[index])
          ],
        ),
        IconButton(
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
          ),
          onPressed: () {
            pauseIndex = index;
            pause();
          },
          icon: Icon(
            EvaIcons.menu_outline,
            color: tint,
          ),
        )
      ],
    );
  }

  int getPausedGameTurn() {
    if (gameId != "") return 0;
    return isCard
        ? pauseIndex == 0
            ? 2
            : pauseIndex == 1 && playersSize > 2
                ? 3
                : pauseIndex == 3
                    ? 1
                    : 0
        : pauseIndex == 0 || (pauseIndex == 1 && playersSize > 2)
            ? 2
            : 0;
  }

  int getLayoutTurn() {
    return isCard
        ? (gameId != ""
            ? myPlayer == 0
                ? 2
                : myPlayer == 1 && playersSize > 2
                    ? 1
                    : myPlayer == 3
                        ? 3
                        : 0
            : 0)
        : (gameId != "" && (myPlayer == 0 || (myPlayer == 1 && playersSize > 2))
            ? 2
            : 0);
  }

  String getFirstHint() {
    String hint = "";
    switch (gameName) {
      case chessGame:
        hint = "Tap on any chess piece\nMake your move";
        break;
      case draughtGame:
        hint = "Tap on any draught piece\nMake your move";
        break;
      case whotGame:
        hint =
            "Tap any card to open\nLong press any card to hide\nPlay a matching card";
        // hint =
        //     "Tap on any card you want to play or tap the general card if you don't have the matching card\nMake your move";
        break;
      case ludoGame:
        hint = "Tap on roll dice button to roll dice\nPlay your dice value";
        // hint =
        //     "Tap on any start ludo piece and tap on the spot you want it to move to\nMake your move";
        break;
      case xandoGame:
        hint =
            "Tap on any grid to play till you have a complete 3 match pattern in any direction\nMake your move";
        break;
      case wordPuzzleGame:
        hint =
            "Tap on any start character and tap on the end character or start dragging from the start character to end char to match your word\nGet your word";
        break;
    }
    return hint;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double padding = (context.screenHeight - context.screenWidth).abs() / 2;
    bool landScape = context.isLandscape;
    double minSize = context.minSize;

    return PopScope(
      canPop: false,
      onPopInvoked: (pop) async {
        if (!paused) {
          pause();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          body: RotatedBox(
            quarterTurns: getLayoutTurn(),
            child: Stack(
              children: [
                if (isCard) ...[
                  ...List.generate(playersSize, (index) {
                    final mindex = (playersSize / 2).ceil();
                    bool isEdgeTilt = gameId != "" &&
                        playersSize > 2 &&
                        (myPlayer == 1 || myPlayer == 3);
                    final value = isEdgeTilt ? !landScape : landScape;
                    return Positioned(
                        top: index < mindex ? 0 : null,
                        bottom: index >= mindex ? 0 : null,
                        left: index == 0 || index == 3 ? 0 : null,
                        right: index == 1 || index == 2 ? 0 : null,
                        child: Container(
                          width: value
                              ? padding
                              : playersSize > 2
                                  ? minSize / 2
                                  : minSize,
                          height: value ? minSize / 2 : padding,
                          alignment: value
                              ? index == 0
                                  ? Alignment.topRight
                                  : index == 1
                                      ? playersSize > 2
                                          ? Alignment.topLeft
                                          : Alignment.bottomLeft
                                      : index == 2
                                          ? Alignment.bottomLeft
                                          : Alignment.bottomRight
                              : index == 0
                                  ? Alignment.bottomLeft
                                  : index == 1
                                      ? playersSize > 2
                                          ? Alignment.bottomRight
                                          : Alignment.topRight
                                      : index == 2
                                          ? Alignment.topRight
                                          : Alignment.topLeft,
                          child: RotatedBox(
                            quarterTurns: index == 0
                                ? 2
                                : index == 1 && playersSize > 2
                                    ? 3
                                    : index == 3
                                        ? 1
                                        : 0,
                            child: RotatedBox(
                              quarterTurns:
                                  gameId != "" && myPlayer != index ? 2 : 0,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0, bottom: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 70,
                                      child: Text(
                                        '${playersScores[index]}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 60,
                                            color: darkMode
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.black
                                                    .withOpacity(0.5)),
                                      ),
                                    ),
                                    GameTimer(
                                      timerStream: index == 1 &&
                                              isChessOrDraught &&
                                              timerController2 != null
                                          ? timerController2!.stream
                                          : timerController.stream,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ));
                  }),
                  ...List.generate(playersSize, (index) {
                    return Positioned(
                      top: index == 0 ||
                              (!landScape && index == 1 && playersSize > 2)
                          ? 0
                          : null,
                      bottom: (index == 1 && playersSize == 2) ||
                              index == 2 ||
                              (!landScape && index == 3)
                          ? 0
                          : null,
                      left: index == 3 || (landScape && index == 0) ? 0 : null,
                      right: (index == 1 && playersSize > 2) ||
                              (landScape &&
                                  ((index == 1 && playersSize == 2) ||
                                      index == 2))
                          ? 0
                          : null,
                      child: RotatedBox(
                        quarterTurns: index == 0
                            ? 2
                            : index == 1 && playersSize > 2
                                ? 3
                                : index == 3
                                    ? 1
                                    : 0,
                        child: Container(
                          width: (landScape &&
                                      ((index == 1 && playersSize > 2) ||
                                          index == 3)) ||
                                  (!landScape &&
                                      (index == 0 ||
                                          index == 2 ||
                                          (index == 1 && playersSize == 2)))
                              ? minSize
                              : padding,
                          alignment: Alignment.center,
                          child: RotatedBox(
                            quarterTurns:
                                gameId != "" && myPlayer != index ? 2 : 0,
                            child: getPlayerBottomWidget(index),
                          ),
                        ),
                      ),
                    );
                  }),
                  buildBody(context),
                  ...List.generate(playersSize, (index) {
                    // bool isEdgeTilt = gameId != "" &&
                    //     playersSize > 2 &&
                    //     (myPlayer == 1 || myPlayer == 3);
                    // final value = isEdgeTilt ? !landScape : landScape;

                    // if (playersCounts.isEmpty ||
                    //     index > playersCounts.length - 1) {
                    //   return Container();
                    // }
                    return Positioned(
                      top: index == 0 ||
                              ((index == 1 || index == 3) && playersSize > 2)
                          ? 0
                          : null,
                      bottom: index != 0 ? 0 : null,
                      left: playersSize > 2 && index == 1 ? null : 0,
                      right: index < 3 ? 0 : null,
                      child: RotatedBox(
                        quarterTurns: getTurn(index),
                        child: Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RotatedBox(
                                quarterTurns:
                                    gameId != "" && myPlayer != index ? 2 : 0,
                                child: StreamBuilder<int>(
                                    stream: currentPlayer == index
                                        ? timerController.stream
                                        : null,
                                    builder: (context, snapshot) {
                                      return Text(
                                        getMessage(index),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: darkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      );
                                    }),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    // height: cardHeight,
                                    width: minSize,
                                    alignment: Alignment.center,
                                    margin: EdgeInsets.only(
                                        left: 24,
                                        right: 24,
                                        bottom: (landScape &&
                                                    (index == 1 ||
                                                        index == 3) &&
                                                    playersSize > 2) ||
                                                (!landScape &&
                                                    (index == 0 ||
                                                        (index == 2 &&
                                                            playersSize > 2) ||
                                                        (index == 1 &&
                                                            playersSize == 2)))
                                            ? 20
                                            : 8),
                                    child: buildBottomOrLeftChild(index),
                                  ),
                                  if (index < playersToasts.length &&
                                      playersToasts[index] != "") ...[
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AppToast(
                                        message: playersToasts[index],
                                        onComplete: () {
                                          playersToasts[index] = "";
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  ...List.generate(
                    playersSize,
                    (index) {
                      final mindex = (playersSize / 2).ceil();
                      return Positioned(
                          top: index < mindex ? 0 : null,
                          bottom: index >= mindex ? 0 : null,
                          left: index == 0 || index == 3 ? 0 : null,
                          right: index == 1 || index == 2 ? 0 : null,
                          child: Container(
                            width: landScape
                                ? padding
                                : playersSize > 2
                                    ? minSize / 2
                                    : minSize,
                            height: landScape ? minSize / 2 : padding,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(4),
                            child: RotatedBox(
                              quarterTurns: index < mindex ? 2 : 0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      RotatedBox(
                                        quarterTurns: gameId != "" &&
                                                myPlayer != index &&
                                                getPartnerPlayer() != index
                                            ? 2
                                            : 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 70,
                                              child: Text(
                                                '${playersScores[index]}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 60,
                                                    color: lighterTint),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            GameTimer(
                                              timerStream: index == 1 &&
                                                      isChessOrDraught &&
                                                      timerController2 != null
                                                  ? timerController2!.stream
                                                  : timerController.stream,
                                            ),
                                            if (currentPlayer == index &&
                                                showMessage) ...[
                                              const SizedBox(height: 4),
                                              StreamBuilder<int>(
                                                  stream:
                                                      timerController.stream,
                                                  builder: (context, snapshot) {
                                                    return Text(
                                                      isChessOrDraught
                                                          ? message
                                                          : "Your Turn - $playerTime",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: tint),
                                                      textAlign:
                                                          TextAlign.center,
                                                    );
                                                  }),
                                            ],
                                          ],
                                        ),
                                      ),
                                      RotatedBox(
                                        quarterTurns: gameId != "" &&
                                                myPlayer != index &&
                                                getPartnerPlayer() != index
                                            ? 2
                                            : 0,
                                        child: getPlayerBottomWidget(index),
                                      ),
                                    ],
                                  ),
                                  if (playersToasts[index] != "") ...[
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AppToast(
                                        message: playersToasts[index],
                                        onComplete: () {
                                          playersToasts[index] = "";
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ));
                    },
                  ),
                  ...List.generate(playersSize, (playerIndex) {
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: playerIndex == 1 ? 0 : null,
                      top: playerIndex == 0 ? 0 : null,
                      child: RotatedBox(
                        quarterTurns: playerIndex == 0 ? 2 : 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 80,
                            width: context.isLandscape
                                ? context.remainingSize
                                : double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: buildBottomOrLeftChild(playerIndex),
                          ),
                        ),
                      ),
                    );
                  }),
                  buildBody(context),
                ],
                if (paused)
                  RotatedBox(
                    quarterTurns: getPausedGameTurn(),
                    child: PausedGamePage(
                      context: context,
                      reason: reason,
                      readAboutGame: readAboutGame,
                      game: gameName,
                      playersScores: playersScores,
                      users: users,
                      playersSize: playersSize,
                      finishedRound: finishedRound,
                      startingRound: gameTime == maxGameTime,
                      playing: gameTime <= maxGameTime - 60,
                      onStart: start,
                      onRestart: restart,
                      onChange: change,
                      onLeave: leave,
                      onConcede: concede,
                      onReadAboutGame: () {
                        if (readAboutGame) {
                          setState(() {
                            readAboutGame = false;
                          });
                        }
                      },
                    ),
                  ),
                if (firstTime && !paused && !seenFirstHint) ...[
                  RotatedBox(
                    quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      color: lighterBlack,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            getFirstHint(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            seenFirstHint = true;
                          });
                        },
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
