import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/components/games/xando_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/game_timer.dart';
import '../../components/custom_toast.dart';
import '../../custom_paint/line_paint.dart';
import '../../models/games/xando.dart';
import '../../models/models.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../paused_game_page.dart';
import '../tabs/games_page.dart';

class XandOGamePage extends StatefulWidget {
  final String? matchId;
  final String? gameId;
  final List<User?>? users;
  final int? id;
  const XandOGamePage({
    super.key,
    this.matchId,
    this.gameId,
    this.users,
    this.id,
  });

  @override
  State<XandOGamePage> createState() => _XandOGamePageState();
}

class _XandOGamePageState extends State<XandOGamePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool played = false;
  XandODetails? prevDetails;
  int gridSize = 3;
  List<List<XandO>> xandos = [];
  List<String> players = [];
  List<int> playersScores = [];
  List<String> playersToasts = [];

  XandOWinDirection? winDirection;
  XandOChar? winChar;
  int winIndex = -1;
  int playedCount = 0;
  bool awaiting = false;
  String message = "Your Turn";

  List<XandOWinDirection> directions = [
    XandOWinDirection.vertical,
    XandOWinDirection.horizontal,
    XandOWinDirection.lowerDiagonal,
    XandOWinDirection.upperDiagonal
  ];

  int currentPlayer = -1;
  int myPlayer = 0;
  String matchId = "";
  String gameId = "";
  int id = 0;
  String myId = "";
  String opponentId = "";
  String pauseId = "";
  String currentPlayerId = "";
  String updatePlayerId = "";
  int currentPlayerIndex = 0;
  List<User?>? users;
  List<User?> notReadyUsers = [];
  List<Playing> playing = [];
  FirebaseService fs = FirebaseService();
  StreamSubscription? detailsSub;
  StreamSubscription<List<Playing>>? playingSub;

  Timer? timer, perTimer;
  int playerTime = 30, gameTime = 0, adsTime = 0, roundsCount = 0;
  bool adLoaded = false;
  bool paused = true,
      finishedRound = false,
      checkout = false,
      pausePlayerTime = false;
  InterstitialAd? _interstitialAd;
  double padding = 0;
  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool changingGame = false;
  String hintMessage = "";
  SharedPreferences? sharedPref;
  bool landScape = false;
  double minSize = 0, maxSize = 0;
  String reason = "";
  late StreamController<int> timerController;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    landScape = context.screenWidth > context.screenHeight;
    minSize = context.screenWidth < context.screenHeight
        ? context.screenWidth
        : context.screenHeight;
    maxSize = context.screenWidth > context.screenHeight
        ? context.screenWidth
        : context.screenHeight;
    padding = (context.screenHeight - context.screenWidth).abs() / 2;
  }

  @override
  void initState() {
    super.initState();
    timerController = StreamController.broadcast();
    gameTime = maxGameTime;
    timerController.sink.add(gameTime);
    if (kIsWeb) ServicesBinding.instance.keyboard.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    currentPlayer = Random().nextInt(2);
    id = widget.id ?? 0;
    myId = fs.myId;
    users = widget.users;
    matchId = widget.matchId ?? "";
    gameId = widget.gameId ?? "";
    initDetails();
    checkFirstime();
    resetScores();
    readDetails();
    getCurrentPlayer();
    initGrids();
  }

  void initDetails() {
    playersToasts = List.generate(2, (index) => "");
  }

  @override
  void dispose() {
    timerController.close();
    if (kIsWeb) ServicesBinding.instance.keyboard.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);

    if (!changingGame) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
    detailsSub?.cancel();
    playingSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      if (!paused) {
        pauseGame();
      }
    }
  }

  @override
  void deactivate() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    stopTimer();
    super.deactivate();
  }

  void stopTimer() {
    paused = true;
    perTimer?.cancel();
    timer?.cancel();
    perTimer = null;
    timer = null;
  }

  void startTimer() {
    pausePlayerTime = false;
    paused = false;
    timer?.cancel();
    perTimer?.cancel();
    timer = null;
    perTimer = null;
    perTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      this.timer = timer;
      if (!mounted) return;
      if (gameTime <= 0) {
        updateWingame();
      } else {
        //if (!pausePlayerTime) {
        if (playerTime <= 0) {
          playerTime = maxPlayerTime;
          if (gameId != "") {
            if (currentPlayerId == myId) {
              updateDetails(-1);
            }
          } else {
            changePlayer();
          }
          setState(() {});
        } else {
          playerTime--;
        }
        //}
        if (adsTime >= maxAdsTime) {
          loadAd();
          adsTime = 0;
        } else {
          adsTime++;
        }
        gameTime--;
      }
      timerController.sink.add(gameTime);
      //setState(() {});
    });
  }

  void restartPlayertime() {
    playerTime = maxPlayerTime;
  }

  void updateWingame() {
    pauseGame();
    roundsCount++;
    updateMatchRecord();
    pausePlayerTime = true;
    finishedRound = true;
    setState(() {});
  }

  void toastDraw() {
    String message = "It's a draw";
    showToast(0, message);
    showToast(1, message);
  }

  void toastWinner(int player) {
    String message =
        "${users != null ? users![player]?.username ?? "" : "Player ${getChar(player).name.capitalize}"} Won";
    showToast(0, message);
    showToast(1, message);
  }

  void loadAd() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    final key = await fs.getPrivateKey();
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
                  pauseGame();
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

  @override
  bool get wantKeepAlive => true;
  void changePlayer() {
    playerTime = maxPlayerTime;
    message = "Your Turn";
    getNextPlayer();
  }

  void getNextPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      final nextPlayerIndex = nextIndex(2, currentPlayerIndex);
      currentPlayer = nextPlayerIndex;
      final playerId = playerIds[nextPlayerIndex];
      currentPlayerId = playerId;
    } else {
      currentPlayer = nextIndex(2, currentPlayer);
    }
  }

  void getCurrentPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      currentPlayerId = playerIds.last;
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      currentPlayer = currentPlayerIndex;
    } else {
      currentPlayer = 1;
    }
  }

  void readPlaying() {
    final users = this.users!;
    if (playingSub != null) return;
    playingSub = fs.readPlaying(gameId).listen((playing) async {
      playing.sortList((value) => value.order, false);
      if (playing.indexWhere((element) => element.id == myId) == -1) {
        leaveGame(true);
        return;
      } else if (playing.length == 1 && playing.first.id == myId) {
        leaveGame();
        return;
      }
      final playersToRemove = getPlayersToRemove(users, playing);
      if (playersToRemove.isNotEmpty) {
        List<String> playersLeft = [];
        for (int i = 0; i < playersToRemove.length; i++) {
          final playerIndex = playersToRemove[i];
          final user = users[playerIndex];
          if (user != null) {
            playersLeft.add(user.username);
          }
        }
        Fluttertoast.showToast(
            msg: "${playersLeft.toStringWithCommaandAnd((name) => name)} left");
      }
      String newActionMessage = "";
      String actionUsername = "";
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        if (user != null) {
          final index =
              playing.indexWhere((element) => element.id == user.user_id);
          if (index == -1) {
            user.action = "left";
            continue;
          }
          final value = playing[index];
          if (value.game != xandoGame) {
            final changeAction = "changed to ${value.game}";
            if (user.action != changeAction) {
              user.action = changeAction;
              newActionMessage = user.action;
              actionUsername = user.username;
            }
          } else if (user.action != value.action) {
            user.action = value.action;
            newActionMessage = user.action;
            actionUsername = user.username;
          }
        }
      }
      if (newActionMessage != "") {
        Fluttertoast.showToast(
            msg: "$actionUsername ${getActionString(newActionMessage)}");
      }
      String action = getAction(playing);
      if (action == "pause") {
        if (!paused) {
          pauseGame(true);
        }
      } else if (action == "start") {
        if (paused) {
          startGame(true);
        }
      } else if (action == "restart") {
        restartGame(true);
      }
      String newgame = getChangedGame(playing);
      if (newgame != "" && newgame != xandoGame) {
        changeGame(newgame, true);
      }
      this.playing = playing;
      setState(() {});
    });
  }

  void readDetails() {
    if (!mounted) return;
    if (matchId != "" && gameId != "" && users != null) {
      final index = users!
          .indexWhere((element) => element != null && element.user_id == myId);
      myPlayer = index;
      readPlaying();

      detailsSub = fs.getXandODetails(gameId).listen((details) async {
        if (!mounted) return;
        if (details != null) {
          played = false;
          pausePlayerTime = false;
          if (details.currentPlayerId == updatePlayerId) {
            return;
          }
          updatePlayerId = details.currentPlayerId;
          final playPos = details.playPos;
          if (playPos != -1) {
            playChar(playPos);
          } else {
            changePlayer();
          }
          pausePlayerTime = false;
          setState(() {});
        }
      });
    }
  }

  XandOChar getChar(int index) => index == 0 ? XandOChar.x : XandOChar.o;

  void checkFirstime() async {
    sharedPref = await SharedPreferences.getInstance();
    int playTimes = sharedPref!.getInt(playedXandoGame) ?? 0;
    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref!.setInt(playedXandoGame, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void updateDetails(int playPos) {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = XandODetails(playPos: playPos, currentPlayerId: myId);
      fs.setXandODetails(
        gameId,
        details,
        prevDetails,
      );
      prevDetails = details;
    }
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
          fs,
          playing,
          users!,
          gameId,
          matchId,
          myId,
          start ? "start" : "restart",
          xandoGame,
          gameTime < maxGameTime,
          id,
          gameTime);
    }
  }

  void pauseGame([bool act = false]) {
    if (act || gameId == "") {
      stopTimer();
      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        fs.pauseGame(gameId, matchId, playing, id, maxGameTime - gameTime);
      }
    }
  }

  void startGame([bool act = false]) {
    if (act || gameId == "") {
      if (finishedRound) {
        gameTime = maxGameTime;
        timerController.sink.add(gameTime);
        initGrids();
      }
      startTimer();
      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        startOrRestart(true);
      }
    }
  }

  void restartGame([bool act = false]) {
    if (act || gameId == "") {
      id++;
      gameTime = maxGameTime;
      timerController.sink.add(gameTime);
      resetScores();
      initGrids();
      startTimer();
      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        startOrRestart(false);
      }
    }
  }

  void changeGame(String game, [bool act = false]) async {
    if (act || gameId == "") {
      changingGame = true;
      id++;
      if (gameId != "") {
        gotoOnlineGamePage(context, game, gameId, matchId, users!, null, id);
      } else {
        gotoOfflineGamePage(context, game, 2, id);
      }
    } else {
      fs.changeGame(game, gameId, matchId, playing, id, maxGameTime - gameTime);
    }
  }

  void leaveGame([bool act = false]) {
    if (act || gameId == "") {
      Navigator.of(context).pop();
    } else {
      if (gameId != "" && matchId != "") {
        fs.leaveGame(gameId, matchId, playing, gameTime < maxGameTime, id,
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

  void selectNewGame() async {
    final newgame = await (Navigator.of(context).push(MaterialPageRoute(
        builder: ((context) => const GamesPage(isCallback: true))))) as String?;
    if (newgame != null) {
      if (newgame == xandoGame) {
        Fluttertoast.showToast(
            msg:
                "You are currently playing $newgame. Choose another game to change to");
        return;
      }
      changeGame(newgame);
    }
  }

  void updateMatchRecord() {
    if (matchId != "" && gameId != "" && currentPlayerId == myId) {
      int score = playersScores[1];
      fs.updateMatchRecord(gameId, matchId, myPlayer, id, score);
    }
  }

  void showToast(int playerIndex, String message) {
    setState(() {
      playersToasts[playerIndex] = message;
    });
  }

  List<int> convertToGrid(int pos, int gridSize) {
    return [pos % gridSize, pos ~/ gridSize];
  }

  int convertToPosition(List<int> grids, int gridSize) {
    return grids[0] + (grids[1] * gridSize);
  }

  void playChar(int index) {
    if (awaiting) return;
    final coordinates = convertToGrid(index, gridSize);
    final rowindex = coordinates[0];
    final colindex = coordinates[1];
    final xando = xandos[colindex][rowindex];
    if (xando.char == XandOChar.empty) {
      xandos[colindex][rowindex].char = getChar(currentPlayer);
      checkIfMatch(xando);
      //getHintMessage();
      setState(() {});
    }
  }

  void checkIfMatch(XandO xando) {
    // if (awaiting) return;
    final x = xando.x;
    final y = xando.y;
    final char = xando.char;
    int vertCount = 0, horCount = 0, lowerDiagCount = 0, upperDiagCount = 0;
    bool foundMatch = false;

    for (int i = 0; i < 3; i++) {
      final vertXandO = xandos[i][x];
      if (vertXandO.char == char) {
        vertCount++;
      }
      if (vertCount == 3) {
        winIndex = x;
        winDirection = XandOWinDirection.vertical;
        foundMatch = true;
        break;
      }

      final horXandO = xandos[y][i];
      if (horXandO.char == char) {
        horCount++;
      }
      if (horCount == 3) {
        winIndex = y;
        winDirection = XandOWinDirection.horizontal;
        foundMatch = true;
        break;
      }
    }
    if ((x + y).isEven) {
      for (int i = 0; i < 3; i++) {
        if ((x + y) == 2) {
          final lowerdiagXandO = xandos[2 - i][i];
          if (lowerdiagXandO.char == char) {
            lowerDiagCount++;
          }
          if (lowerDiagCount == 3) {
            winIndex = 0;
            winDirection = XandOWinDirection.lowerDiagonal;
            foundMatch = true;
            break;
          }
        }
        if (x == y) {
          final upperdiagXandO = xandos[i][i];
          if (upperdiagXandO.char == char) {
            upperDiagCount++;
          }
          if (upperDiagCount == 3) {
            winIndex = 1;
            winDirection = XandOWinDirection.upperDiagonal;
            foundMatch = true;
            break;
          }
        }
      }
    }
    playedCount++;
    message = "Your Turn";

    if (foundMatch || playedCount == (gridSize * gridSize)) {
      if (foundMatch) {
        winChar = xando.char;
        message = "You Won";
        //Fluttertoast.showToast(msg: "Player ${xando.char.name.capitalize} Won");
        playersScores[currentPlayer]++;
        updateMatchRecord();
        toastWinner(winChar!.index);
      }
      awaiting = true;
      Future.delayed(const Duration(seconds: 1)).then((value) {
        playedCount = 0;
        resetChars();
      });
    }
    changePlayer();
    setState(() {});
  }

  Future resetChars() async {
    playerTime = maxPlayerTime;
    awaiting = false;
    xandos.clear();
    winDirection = null;
    winChar = null;
    winIndex = -1;
    message = "Your Turn";
    setState(() {
      initGrids();
    });
  }

  void resetScores() {
    playersScores = List.generate(2, (index) => 0);
  }

  void initGrids() {
    pausePlayerTime = false;
    finishedRound = false;
    xandos = List.generate(
        gridSize,
        (colindex) => List.generate(gridSize, (rowindex) {
              final index = convertToPosition([rowindex, colindex], gridSize);
              return XandO(XandOChar.empty, rowindex, colindex, "$index");
            }));
  }

  void getHintMessage() {
    if (!firstTime) return;

    hintMessage =
        "Tap on any grid to play till you have a complete 3 match pattern in any direction";
    message = hintMessage;
    setState(() {});
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if ((key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.escape) &&
          !paused) {
        pauseGame();
      } else if (key == LogicalKeyboardKey.enter && paused) {
        startGame();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (pop) async {
        if (!paused) {
          pauseGame();
        }
      },
      child: Scaffold(
        body: RotatedBox(
          quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
          child: Stack(
            children: [
              ...List.generate(2, (index) {
                return Positioned(
                    top: landScape || index == 0 ? 0 : null,
                    bottom: landScape || index == 1 ? 0 : null,
                    left: !landScape || index == 0 ? 0 : null,
                    right: !landScape || index == 1 ? 0 : null,
                    child: Container(
                        width: landScape ? padding : minSize,
                        height: landScape ? minSize : padding,
                        padding: const EdgeInsets.all(4),
                        child: RotatedBox(
                          quarterTurns: index == 0 ? 2 : 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (landScape) ...[
                                Expanded(
                                  child: Container(),
                                ),
                              ],
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    RotatedBox(
                                      quarterTurns:
                                          gameId != "" && myPlayer != index
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
                                                  color: darkMode
                                                      ? Colors.white
                                                          .withOpacity(0.5)
                                                      : Colors.black
                                                          .withOpacity(0.5)),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          GameTimer(
                                            timerStream: timerController.stream,
                                          ),
                                          if (currentPlayer == index) ...[
                                            const SizedBox(
                                              height: 4,
                                            ),
                                            StreamBuilder<int>(
                                                stream: timerController.stream,
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    "$message - $playerTime",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: darkMode
                                                            ? Colors.white
                                                            : Colors.black),
                                                    textAlign: TextAlign.center,
                                                  );
                                                }),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RotatedBox(
                                           quarterTurns:
                                          gameId != "" && myPlayer != index
                                              ? 2
                                              : 0,
                                          child: Text(
                                            users != null
                                                ? users![index]?.username ?? ""
                                                : "Player ${index + 1}",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: currentPlayer == index
                                                    ? Colors.blue
                                                    : darkMode
                                                        ? Colors.white
                                                        : Colors.black),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )));
              }),
              Center(
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: CustomPaint(
                    foregroundPainter: winDirection == null
                        ? null
                        : XandOLinePainter(
                            direction: winDirection!,
                            index: winIndex,
                            color: winChar! == XandOChar.x
                                ? Colors.blue
                                : Colors.red,
                            thickness: 3),
                    child: GridView(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize),
                      children: List.generate(gridSize * gridSize, (index) {
                        final coordinates = convertToGrid(index, gridSize);
                        final rowindex = coordinates[0];
                        final colindex = coordinates[1];
                        final xando = xandos[colindex][rowindex];
                        return XandOTile(
                          key: Key(xando.id),
                          blink: firstTime && xando.char == XandOChar.empty,
                          xando: xando,
                          onPressed: () {
                            if (gameId != "" && currentPlayerId != myId) {
                              showToast(1,
                                  "Its ${getUsername(currentPlayerId)}'s turn");
                              return;
                            }
                            if (gameId != "") {
                              updateDetails(index);
                            } else {
                              playChar(index);
                            }
                          },
                        );
                      }),
                    ),
                  ),
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
                      child: const Center(
                        child: Text(
                            "Tap on any part of the grid\nTap till you get a three matching pattern\nPattern can be vertically or diagonally",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center),
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
              if (paused) ...[
                RotatedBox(
                  quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
                  child: PausedGamePage(
                    context: context,
                    readAboutGame: readAboutGame,
                    game: "X and O",
                    playersScores: playersScores,
                    users: users,
                    playersSize: 2,
                    finishedRound: finishedRound,
                    startingRound: gameTime == maxGameTime,
                    onStart: startGame,
                    onRestart: restartGame,
                    onChange: selectNewGame,
                    onLeave: leaveGame,
                    onReadAboutGame: () {
                      if (readAboutGame) {
                        setState(() {
                          readAboutGame = false;
                        });
                      }
                    },
                  ),
                ),
              ],
              if (playersToasts[0] != "") ...[
                Align(
                  alignment: Alignment.topCenter,
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: CustomToast(
                      message: playersToasts[0],
                      onComplete: () {
                        playersToasts[0] = "";
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
              if (playersToasts[1] != "") ...[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CustomToast(
                    message: playersToasts[1],
                    onComplete: () {
                      playersToasts[1] = "";
                      setState(() {});
                    },
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
