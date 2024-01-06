import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/components/games/draught_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/firebase_service.dart';
import '../../components/game_timer.dart';
import '../../components/custom_grid.dart';
import '../../components/custom_toast.dart';
import '../../models/games/draught.dart';
import '../../models/models.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../paused_game_page.dart';
import '../tabs/games_page.dart';

class DraughtGamePage extends StatefulWidget {
  final String? matchId;
  final String? gameId;
  final List<User?>? users;
  final int? id;

  const DraughtGamePage({
    super.key,
    this.matchId,
    this.gameId,
    this.users,
    this.id,
  });

  @override
  State<DraughtGamePage> createState() => _DraughtGamePageState();
}

class _DraughtGamePageState extends State<DraughtGamePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  DraughtDetails? prevDetails;
  bool awaiting = false;
  bool? iWin;
  int gridSize = 10, playersWonSize = 0;
  double size = 0, wonDraughtSize = 0;
  double padding = 0, messagePadding = 0, wonDraughtsPadding = 60;
  int playersSize = 2;
  DraughtTile? selectedDraughtTile;
  List<DraughtTile> draughtTiles = [];
  List<List<Draught>> playersDraughts = [];
  List<List<Draught>> playersWonDraughts = [];
  List<int> playersScores = [];
  List<String> playersToasts = [];
  List<String> gamePatterns = [];
  List<int> hintPositions = [];

  int currentPlayer = -1;
  int myPlayer = 0, opponentPlayer = 1;
  String pauseId = "";
  String currentPlayerId = "";
  String updatePlayerId = "";

  int currentPlayerIndex = 0;
  int drawMoveCount = 0;
  int maxDrawMoveCount = 25;

  List<int> playPositions = [];
  String message = "Your Turn";
  bool multiSelect = false;
  bool mustcapture = false;

  String matchId = "";
  String gameId = "";
  int id = 0;
  String myId = "";
  String opponentId = "";
  List<User?>? users;
  List<User?> notReadyUsers = [];
  List<Playing> playing = [];

  FirebaseService fs = FirebaseService();
  StreamSubscription? detailsSub;
  StreamSubscription<List<Playing>>? playingSub;

  Timer? timer, perTimer;
  int player1Time = 0,
      player2Time = 0,
      gameTime = 0,
      adsTime = 0,
      roundsCount = 0;
  bool adLoaded = false;
  bool paused = true,
      finishedRound = false,
      checkout = false,
      completedPlayertime = false;
  InterstitialAd? _interstitialAd;
  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool won = false;
  bool changingGame = false;
  String hintMessage = "";
  SharedPreferences? sharedPref;
  bool landScape = false;
  double minSize = 0, maxSize = 0;
  String lastPlayerId = "";
  String reason = "", reasonMessage = "";
  late StreamController<int> timerController1, timerController2;
  @override
  void initState() {
    super.initState();
    timerController1 = StreamController.broadcast();
    timerController2 = StreamController.broadcast();
    player1Time = maxChessDraughtTime;
    player2Time = maxChessDraughtTime;
    timerController1.sink.add(player1Time);
    timerController2.sink.add(player2Time);

    if (kIsWeb) ServicesBinding.instance.keyboard.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    playersWonSize = (gridSize ~/ 2) * ((gridSize ~/ 2) - 1);
    id = widget.id ?? 0;
    myId = fs.myId;
    users = widget.users;
    matchId = widget.matchId ?? "";
    gameId = widget.gameId ?? "";
    initDetails();
    checkFirstime();
    resetScores();
    readDetails();
    addInitialDraughts();
    showPossiblePlayPositions();
  }

  void initDetails() {
    playersToasts = List.generate(2, (index) => "");
  }

  @override
  void dispose() {
    timerController1.close();
    timerController2.close();
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
    size = minSize / 8;
    wonDraughtSize = padding / 10;
    wonDraughtsPadding = padding - size - 20;
    messagePadding = wonDraughtsPadding - 30;
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
    stopTimer();
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
    completedPlayertime = false;
    paused = false;
    timer?.cancel();
    perTimer?.cancel();
    timer = null;
    perTimer = null;
    perTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      this.timer = timer;
      if (!mounted) return;
      if (!completedPlayertime) {
        if (player1Time <= 0 || player2Time <= 0) {
          reason = "time";
          if (player1Time == 0 && player2Time == 0) {
            updateDrawgame();
          } else {
            updateWingame(true);
          }
        } else {
          if (currentPlayer == 0) {
            player1Time--;
          } else {
            player2Time--;
          }
        }
      }
      if (adsTime >= maxAdsTime) {
        loadAd();
        adsTime = 0;
      } else {
        adsTime++;
      }
      gameTime++;
      if (currentPlayer == 0) {
        timerController1.sink.add(player1Time);
      } else {
        timerController2.sink.add(player2Time);
      }
      //setState(() {});
    });
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

  void resetScores() {
    playersScores = List.generate(2, (index) => 0);
  }

  void addInitialDraughts() {
    getCurrentPlayer();
    won = false;
    reason = "";
    reasonMessage = "";
    mustcapture = false;
    finishedRound = false;
    hintPositions.clear();
    playersDraughts.clear();
    playersWonDraughts.clear();
    draughtTiles.clear();
    for (int i = 0; i < 2; i++) {
      playersDraughts.add([]);
      playersWonDraughts.add([]);
    }
    draughtTiles = List.generate(gridSize * gridSize, (index) {
      Draught? draught;
      final coordinates = convertToGrid(index, gridSize);
      final x = coordinates[0];
      final y = coordinates[1];
      if (y != (gridSize / 2) && y != (gridSize / 2) - 1) {
        if ((x.isEven && y.isOdd) || (y.isEven && x.isOdd)) {
          if (y < (gridSize / 2) - 1) {
            draught = Draught(x, y, "$index", 0, 0, false);
            playersDraughts[0].add(draught);
          } else if (y > (gridSize / 2)) {
            draught = Draught(x, y, "$index", 1, 1, false);
            playersDraughts[1].add(draught);
          }
        }
      }
      return DraughtTile(x, y, "$index", draught);
    });
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
          if (value.game != draughtGame) {
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
      if (newgame != "" && newgame != draughtGame) {
        changeGame(newgame, true);
      }
      this.playing = playing;
      setState(() {});
    });
  }

  void readDetails() {
    if (matchId != "" && gameId != "" && users != null) {
      final index = users!
          .indexWhere((element) => element != null && element.user_id == myId);
      myPlayer = index;
      readPlaying();

      detailsSub = fs.getDraughtDetails(gameId).listen((details) async {
        if (details != null) {
          final playPos = details.playPos;
          if (playPos != -1) {
            //int actualPos = convertPos(playPos, currentPlayerId);
            playDraught(playPos);
          } else {
            if (multiSelect) {
              if (playPositions.isNotEmpty) {
                moveMultipleDraughts();
              }
              playPositions.clear();
              showPossiblePlayPositions();
              multiSelect = false;
            } else {
              selectedDraughtTile = null;
              changePlayer();
            }
          }
          completedPlayertime = false;
          setState(() {});
        }
      });
    }
  }

  void updateDetails(int playPos) {
    if (matchId != "" && gameId != "" && users != null) {
      final details = DraughtDetails(currentPlayerId: myId, playPos: playPos);
      fs.setDraughtDetails(
        gameId,
        details,
        prevDetails,
      );
      prevDetails = details;
    }
  }

  int convertPos(int pos, String userId) {
    if (userId == myId) return pos;
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    // return convertToPosition([x, (gridSize - 1) - y], gridSize);
    return convertToPosition(
        [(gridSize - 1) - x, (gridSize - 1) - y], gridSize);
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
          draughtGame,
          player1Time < maxChessDraughtTime ||
              player2Time < maxChessDraughtTime,
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
        fs.pauseGame(gameId, matchId, playing, id, gameTime);
      }
    }
  }

  void startGame([bool act = false]) {
    if (act || gameId == "") {
      if (finishedRound) {
        gameTime = 0;
        player1Time = maxChessDraughtTime;
        player2Time = maxChessDraughtTime;
        timerController1.sink.add(player1Time);
        timerController2.sink.add(player2Time);
        addInitialDraughts();
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
      gameTime = 0;
      player1Time = maxChessDraughtTime;
      player2Time = maxChessDraughtTime;
      timerController1.sink.add(player1Time);
      timerController2.sink.add(player2Time);
      resetScores();
      addInitialDraughts();
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
      fs.changeGame(game, gameId, matchId, playing, id, gameTime);
    }
  }

  void leaveGame([bool act = false]) {
    if (act || gameId == "") {
      Navigator.of(context).pop();
    } else {
      if (gameId != "" && matchId != "") {
        fs.leaveGame(
            gameId,
            matchId,
            playing,
            player1Time < maxChessDraughtTime ||
                player2Time < maxChessDraughtTime,
            id,
            gameTime);
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
      if (newgame == draughtGame) {
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

  bool checkSelection(int x, int y, DraughtDirection capDirection,
      [Draught? capdraught]) {
    List<DraughtDirection> directions = [
      DraughtDirection.topRight,
      DraughtDirection.topLeft,
      DraughtDirection.bottomRight,
      DraughtDirection.bottomLeft,
    ];
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    final draught = capdraught ?? draughtTile.draught;
    if (draught == null) return false;
    int player = draught.player;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      if (direction == getOppositeDirection(capDirection)) continue;
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);
      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) {
        return true;
      }
    }
    return false;
  }

  List<int> getPositions(int from, int to) {
    List<int> foundDraughtPositions = [];
    final selectedDraught = selectedDraughtTile!.draught!;
    final coordinates = convertToGrid(to, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    final fromcoordinates = convertToGrid(from, gridSize);
    final selX = fromcoordinates[0];
    final selY = fromcoordinates[1];
    final diffX = (x - selX).abs();
    final diffY = (y - selY).abs();
    final direction = getDraughtDirection(x - selX, y - selY);
    if (diffX == diffY) {
      int foundPos = -1;
      if (diffX >= 2) {
        for (int i = 1; i < diffX + 1; i++) {
          final middleX = getX(direction, selX, i);
          final middleY = getY(direction, selY, i);
          final middleDraughtPos =
              convertToPosition([middleX, middleY], gridSize);
          final middleDraughtTile = draughtTiles[middleDraughtPos];

          if (middleDraughtTile.draught != null) {
            if (middleDraughtTile.draught!.player != selectedDraught.player) {
              if (foundPos != -1) {
                return [];
              } else {
                foundPos = middleDraughtPos;
              }
            } else {
              return [];
            }
          } else {
            if (foundPos != -1) {
              foundDraughtPositions.add(foundPos);
              foundPos = -1;
            } else {
              if (!selectedDraught.king) {
                return [];
              }
            }
          }
        }
      }
    }
    return foundDraughtPositions;
  }

  bool isValidMovement(int from, int to) {
    final coordinates = convertToGrid(to, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    final fromcoordinates = convertToGrid(from, gridSize);
    final selX = fromcoordinates[0];
    final selY = fromcoordinates[1];
    final diffX = (x - selX).abs();
    final diffY = (y - selY).abs();
    final direction = getDraughtDirection(x - selX, y - selY);
    if (diffX == diffY) {
      for (int i = 1; i < diffX + 1; i++) {
        final middleX = getX(direction, selX, i);
        final middleY = getY(direction, selY, i);
        final middleDraughtPos =
            convertToPosition([middleX, middleY], gridSize);
        final middleDraughtTile = draughtTiles[middleDraughtPos];
        if (middleDraughtTile.draught != null) {
          return false;
        }
      }
    }
    return true;
  }

  void showPossiblePlayPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    final playerDraughts = playersDraughts[currentPlayer];
    for (int i = 0; i < playerDraughts.length; i++) {
      final draught = playerDraughts[i];
      int pos = convertToPosition([draught.x, draught.y], gridSize);
      hintPositions.add(pos);
    }
    //getHintMessage(true);
    setState(() {});
  }

  void selectDraught(int pos) {
    int lastPos = -1;
    if (selectedDraughtTile == null) return;
    if (playPositions.isNotEmpty) {
      if (playPositions.contains(pos)) {
        final index = playPositions.indexWhere((element) => element == pos);
        playPositions.removeRange(index, playPositions.length);
      } else {
        lastPos = playPositions.last;
        final positions = getPositions(lastPos, pos);
        if (positions.isNotEmpty) {
          playPositions.add(pos);
        }
      }
    } else {
      lastPos = int.parse(selectedDraughtTile!.id);
      final positions = getPositions(lastPos, pos);
      if (positions.isNotEmpty) {
        playPositions.add(pos);
      }
    }
    if (playPositions.isNotEmpty) {
      if (!multiSelect) multiSelect = true;
    } else {
      multiSelect = false;
    }
    setState(() {});
  }

  void playDraught(int pos) {
    final draughtTile = draughtTiles[pos];
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];

    if (draughtTile.draught != null) {
      if (draughtTile.draught!.player != currentPlayer) {
        final color = currentPlayer == 0 ? "black" : "white";
        showToast(currentPlayer,
            "This is not your draught piece. Your draught piece color is $color");
        return;
      }
      if (selectedDraughtTile != null && selectedDraughtTile == draughtTile) {
        if (playPositions.isNotEmpty) {
          multiSelect = false;
          playPositions.clear();
        }
        hintPositions.clear();
        selectedDraughtTile = null;
        showPossiblePlayPositions();
      } else {
        if (mustcapture && !canCapture(x, y)) {
          showToast(currentPlayer, "You must capture your opponent");
          return;
        }
        selectedDraughtTile = draughtTile;
        getHintPositions(pos);
      }
      setState(() {});
    } else {
      if (selectedDraughtTile != null) {
        if (mustcapture) {
          DraughtDirection? direction;
          if (playPositions.isEmpty) {
            final selPos = convertToPosition(
                [selectedDraughtTile!.x, selectedDraughtTile!.y], gridSize);
            direction = getDirection(selPos, pos);
          } else {
            direction = getDirection(playPositions.last, pos);
          }
          final can =
              checkSelection(x, y, direction, selectedDraughtTile!.draught);
          if (can || playPositions.contains(pos)) {
            selectDraught(pos);
          } else {
            if (playPositions.isNotEmpty) {
              playPositions.add(pos);
              moveMultipleDraughts();
            } else {
              moveDraught(pos);
            }
          }
        } else {
          moveDraught(pos);
        }
      }
    }
  }

  void moveMultipleDraughts() async {
    awaiting = true;
    for (int i = 0; i < playPositions.length; i++) {
      final index = playPositions[i];
      moveDraught(index);
      if (i != playPositions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    awaiting = false;
    multiSelect = false;
    playPositions.clear();
    hintPositions.clear();
    changePlayer();
    selectedDraughtTile = null;
    showPossiblePlayPositions();
    setState(() {});
  }

  DraughtDirection getDirection(int lastPos, int newPos) {
    final lastCoordinates = convertToGrid(lastPos, gridSize);
    final lastX = lastCoordinates[0];
    final lastY = lastCoordinates[1];
    final newCoordinates = convertToGrid(newPos, gridSize);
    final newX = newCoordinates[0];
    final newY = newCoordinates[1];
    return getDraughtDirection(newX - lastX, newY - lastY);
  }

  void moveDraught(int pos) {
    final draughtTile = draughtTiles[pos];
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    final selX = selectedDraughtTile!.x;
    final selY = selectedDraughtTile!.y;
    final selPos = convertToPosition([selX, selY], gridSize);
    final xDiff = (x - selX).abs();
    final yDiff = (y - selY).abs();
    final selectedDraught = selectedDraughtTile!.draught!;
    if (xDiff != yDiff) return;

    final foundPositions = getPositions(selPos, pos);
    if (foundPositions.isNotEmpty) {
      for (int i = 0; i < foundPositions.length; i++) {
        final foundPos = foundPositions[i];
        final foundDraughtTile = draughtTiles[foundPos];
        final foundDraught = foundDraughtTile.draught!;
        final opponentIndex = foundDraught.player;
        final playerIndex = selectedDraught.player;
        final playerDraughts = playersDraughts[opponentIndex];
        final playerWonDraughts = playersWonDraughts[playerIndex];
        playerWonDraughts.add(foundDraught);
        playerDraughts.removeWhere((element) => element.id == foundDraught.id);
        foundDraughtTile.draught = null;
      }
      drawMoveCount = 0;
      clearPattern();
    } else {
      if (!isValidMovement(selPos, pos)) return;

      if (!selectedDraught.king &&
          ((yDiff > 1 || !(y - selY).isNegative && currentPlayer == 1) ||
              ((y - selY).isNegative && currentPlayer == 0))) {
        return;
      }
      if (mustcapture) {
        showToast(currentPlayer, "You must capture your opponent");
        return;
      }
      savePattern();
      if (selectedDraught.king) {
        drawMoveCount++;
      } else {
        drawMoveCount = 0;
      }
    }
    if ((y == 0 && currentPlayer == 1) ||
        (y == gridSize - 1 && currentPlayer == 0)) {
      selectedDraughtTile!.draught!.king = true;
    }
    selectedDraughtTile!.draught!.x = x;
    selectedDraughtTile!.draught!.y = y;
    draughtTile.draught = selectedDraughtTile!.draught;
    selectedDraughtTile!.draught = null;
    checkWingame();
    if (multiSelect) {
      selectedDraughtTile = draughtTile;
    } else {
      selectedDraughtTile = null;
      changePlayer();
      hintPositions.clear();
      showPossiblePlayPositions();
    }

    setState(() {});
  }

  List<DraughtDirection> getCaptureDirections(
      int x, int y, DraughtDirection capDirection, Draught capdraught) {
    List<DraughtDirection> captureDirections = [];
    List<DraughtDirection> directions = [
      DraughtDirection.topRight,
      DraughtDirection.topLeft,
      DraughtDirection.bottomRight,
      DraughtDirection.bottomLeft,
    ];
    directions.remove(capDirection);
    if (exceedRange(x, y)) return [];
    //final pos = convertToPosition([x, y], gridSize);
    final draught = capdraught;
    int player = draught.player;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      if (direction == getOppositeDirection(capDirection)) continue;
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);
      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) captureDirections.add(direction);
    }
    return captureDirections;
  }

  void getMoveHintPositions(int pos) {
    //final pos = convertToPosition([x, y], gridSize);
    final grids = convertToGrid(pos, gridSize);
    int x = grids[0];
    int y = grids[1];
    final draughtTile = draughtTiles[pos];
    if (draughtTile.draught == null) return;
    int player = draughtTile.draught!.player;
    List<DraughtDirection> directions = [];
    if (player == 0) {
      directions = [DraughtDirection.bottomLeft, DraughtDirection.bottomRight];
    } else {
      directions = [DraughtDirection.topLeft, DraughtDirection.topRight];
    }
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      final newX = getX(direction, x, 1);
      final newY = getY(direction, y, 1);
      if (exceedRange(newX, newY)) continue;
      final pos = convertToPosition([newX, newY], gridSize);
      final draughtTile = draughtTiles[pos];
      if (draughtTile.draught == null) {
        hintPositions.add(pos);
      }
    }

    setState(() {});
  }

  DraughtDirection getEquivalentDirection(DraughtDirection direction) {
    if (direction == DraughtDirection.topLeft) {
      return DraughtDirection.topRight;
    } else if (direction == DraughtDirection.topRight) {
      return DraughtDirection.topLeft;
    } else if (direction == DraughtDirection.bottomLeft) {
      return DraughtDirection.bottomRight;
    } else if (direction == DraughtDirection.bottomRight) {
      return DraughtDirection.bottomLeft;
    }
    return DraughtDirection.bottomLeft;
  }

  DraughtDirection getOppositeDirection(DraughtDirection direction) {
    if (direction == DraughtDirection.topLeft) {
      return DraughtDirection.bottomRight;
    } else if (direction == DraughtDirection.topRight) {
      return DraughtDirection.bottomLeft;
    } else if (direction == DraughtDirection.bottomLeft) {
      return DraughtDirection.topRight;
    } else if (direction == DraughtDirection.bottomRight) {
      return DraughtDirection.topLeft;
    }
    return DraughtDirection.bottomLeft;
  }

  void getHintPositions(int pos,
      [Draught? capdraught, DraughtDirection? capDirection]) {
    if (capdraught == null) {
      hintPositions.clear();
    }
    List<DraughtDirection> directions = capDirection != null
        ? [capDirection]
        : [
            DraughtDirection.topRight,
            DraughtDirection.topLeft,
            DraughtDirection.bottomRight,
            DraughtDirection.bottomLeft,
          ];

    final grids = convertToGrid(pos, gridSize);
    int x = grids[0];
    int y = grids[1];

    //final capture = capdraught == null ? canCapture(x, y) : true;
    final draughtTile = draughtTiles[pos];
    final draught = capdraught ?? draughtTile.draught;
    if (draught == null) return;
    final isKing = draught.king;
    int player = draught.player;

    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      int foundPlayersCount = 0;
      int emptySpacesCount = 0;
      final capture = canCapture(x, y, draught, direction);
      if (mustcapture && !capture) continue;
      bool found = false, hasFoundAPlayer = false;
      for (int j = 1; j < gridSize; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) {
          if (emptySpacesCount > 0 && capture && foundPlayersCount == 0) {
            removeMovePositions(emptySpacesCount);
          }
          break;
        }
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          final foundDraught = draughtTile.draught!;
          if (emptySpacesCount > 0 && foundPlayersCount == 0 && !isKing) {
            if (capture) {
              removeMovePositions(emptySpacesCount);
            }
            break;
          }
          if (foundDraught.player != player) {
            if (!found) {
              found = true;
              hasFoundAPlayer = true;
            } else {
              if (emptySpacesCount > 0 &&
                  foundPlayersCount == 0 &&
                  isKing &&
                  capture) {
                removeMovePositions(emptySpacesCount);
              }
              break;
            }
          } else {
            if (emptySpacesCount > 0 &&
                foundPlayersCount == 0 &&
                isKing &&
                capture) {
              removeMovePositions(emptySpacesCount);
            }
            break;
          }
          //emptySpacesCount = 0;
        } else {
          if (!isKing && !found) {
            if ((player == 0 &&
                    (direction == DraughtDirection.topLeft ||
                        direction == DraughtDirection.topRight)) ||
                (player == 1 &&
                    (direction == DraughtDirection.bottomLeft ||
                        direction == DraughtDirection.bottomRight))) {
              break;
            }
          }
          if (emptySpacesCount > 0 && !found && !isKing) {
            if (capture && foundPlayersCount == 0) {
              removeMovePositions(emptySpacesCount);
            }
            break;
          }
          if (hasFoundAPlayer) {
            final captureDirections =
                direction == DraughtDirection.bottomLeft ||
                        direction == DraughtDirection.topRight
                    ? [DraughtDirection.topLeft, DraughtDirection.bottomRight]
                    : [DraughtDirection.bottomLeft, DraughtDirection.topRight];

            for (int i = 0; i < captureDirections.length; i++) {
              getHintPositions(pos, draught, captureDirections[i]);
            }
          }
          if (found) {
            foundPlayersCount++;
            found = false;
            emptySpacesCount = 0;
          }
          emptySpacesCount++;
          hintPositions.add(pos);
        }
      }
    }
    setState(() {});
  }

  void getHintMessage(bool played, [bool king = false]) {
    if (played) {
      hintMessage =
          "Tap on ${currentPlayer == 0 ? "Brown" : "Yellow"} piece to make your move";
    } else {
      if (king) {
        hintMessage =
            "A King can move 1 or multiple steps diagonally going above opponent to capture and can make multiple captures at different directions";
      } else {
        hintMessage =
            "A normal piece can move 1 step and 2 steps diagonally going above opponent to capture and can make multiple captures at different directions";
      }
    }
    message = hintMessage;
    setState(() {});
  }

  void checkFirstime() async {
    sharedPref = await SharedPreferences.getInstance();
    int playTimes = sharedPref!.getInt(playedDraughtGame) ?? 0;
    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref!.setInt(playedDraughtGame, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void removeMovePositions(int count) {
    if (count > 0) {
      for (int i = 0; i < count; i++) {
        if (hintPositions.isNotEmpty) {
          hintPositions.removeLast();
        }
      }
    }
  }

  bool canMove(int x, int y) {
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    if (draughtTile.draught == null) return false;
    int player = draughtTile.draught!.player;
    List<DraughtDirection> directions = [];
    if (player == 0) {
      directions = [DraughtDirection.bottomLeft, DraughtDirection.bottomRight];
    } else {
      directions = [DraughtDirection.topLeft, DraughtDirection.topRight];
    }
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      final newX = getX(direction, x, 1);
      final newY = getY(direction, y, 1);
      if (exceedRange(newX, newY)) continue;
      final pos = convertToPosition([newX, newY], gridSize);
      final draughtTile = draughtTiles[pos];
      if (draughtTile.draught == null) return true;
    }
    return false;
  }

  bool canCapture(int x, int y,
      [Draught? capdraught,
      DraughtDirection? capDirection,
      DraughtDirection? comingDirection]) {
    List<DraughtDirection> directions = capDirection != null
        ? [capDirection]
        : [
            DraughtDirection.topRight,
            DraughtDirection.topLeft,
            DraughtDirection.bottomRight,
            DraughtDirection.bottomLeft,
          ];
    if (comingDirection != null &&
        directions.contains(getOppositeDirection(comingDirection))) {
      directions.remove(comingDirection);
    }
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    final draught = capdraught ?? draughtTile.draught;
    if (draught == null) return false;
    int player = draught.player;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        } else {
          foundPos = -1;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);
      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) return true;
    }
    return false;
  }

  bool hasMultipleCapture(int x, int y) {
    List<DraughtDirection> directions = [
      DraughtDirection.topRight,
      DraughtDirection.topLeft,
      DraughtDirection.bottomRight,
      DraughtDirection.bottomLeft,
    ];
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final draughtTile = draughtTiles[pos];
    if (draughtTile.draught == null) return false;
    int player = draughtTile.draught!.player;
    final draught = draughtTile.draught!;
    int end = draught.king ? gridSize : 2;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      int foundPos = -1;
      for (int j = 1; j < end; j++) {
        final newX = getX(direction, x, j);
        final newY = getY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        final draughtTile = draughtTiles[pos];
        if (draughtTile.draught != null) {
          if (draughtTile.draught!.player == player) {
            foundPos = -1;
          } else {
            foundPos = j;
          }
          break;
        }
      }
      if (foundPos == -1) continue;
      final lastX = getX(direction, x, foundPos + 1);
      final lastY = getY(direction, y, foundPos + 1);

      if (exceedRange(lastX, lastY)) continue;
      final lastPos = convertToPosition([lastX, lastY], gridSize);
      final lastDraughtTile = draughtTiles[lastPos];
      if (lastDraughtTile.draught == null) {
        int end = draught.king ? gridSize : 2;
        for (int i = 0; i < directions.length; i++) {
          final direction = directions[i];
          int foundPos = -1;
          for (int j = 1; j < end; j++) {
            final newX = getX(direction, lastX, j);
            final newY = getY(direction, lastY, j);
            if (exceedRange(newX, newY)) break;
            final pos = convertToPosition([newX, newY], gridSize);
            final draughtTile = draughtTiles[pos];
            if (draughtTile.draught != null) {
              if (draughtTile.draught!.player == player) {
                foundPos = -1;
              } else {
                foundPos = j;
              }
              break;
            }
          }
          if (foundPos == -1) continue;
          final last2X = getX(direction, lastX, foundPos + 1);
          final last2Y = getY(direction, lastY, foundPos + 1);

          if (exceedRange(last2X, last2Y)) continue;
          final last2Pos = convertToPosition([last2X, last2Y], gridSize);
          final last2DraughtTile = draughtTiles[last2Pos];
          if (last2DraughtTile.draught == null) {
            return true;
          } else {
            continue;
          }
        }
      }
    }
    return false;
  }

  String getPattern(int player, List<Draught> draughts) {
    String pattern = "";
    for (int i = 0; i < draughts.length; i++) {
      final draught = draughts[i];
      final x = draught.x;
      final y = draught.y;
      pattern += "$player$x$y, ";
    }
    return pattern;
  }

  void savePattern() {
    String pattern = "";
    pattern += getPattern(0, playersDraughts[0]);
    pattern += getPattern(1, playersDraughts[1]);
    gamePatterns.add(pattern);
    checkPattern();
  }

  void clearPattern() {
    gamePatterns.clear();
  }

  void checkPattern() {
    if (gamePatterns.isNotEmpty) {
      Map<String, int> patternsMap = {};
      for (int i = 0; i < gamePatterns.length; i++) {
        final pattern = gamePatterns[i];
        if (patternsMap.isNotEmpty && patternsMap[pattern] != null) {
          patternsMap[pattern] = patternsMap[pattern]! + 1;
          if (patternsMap[pattern]! == 3) {
            reason = "3 same game pattern";
            updateDrawgame();
          }
        } else {
          patternsMap[pattern] = 1;
        }
      }
    }
  }

  void checkForDraw() {
    if (drawMoveCount == maxDrawMoveCount) {
      reason = "25 moves without capturing";
      updateDrawgame();
    }
  }

  void checkIfCanMove() {
    mustcapture = false;
    final next = nextIndex(2, currentPlayer);
    final nextPlayerDraughts = playersDraughts[next];
    int captureCount = 0;
    int moveCount = 0;
    if (nextPlayerDraughts.isNotEmpty) {
      for (int i = 0; i < nextPlayerDraughts.length; i++) {
        final draught = nextPlayerDraughts[i];
        final x = draught.x;
        final y = draught.y;
        if (canCapture(x, y)) {
          captureCount++;
        }
        if (canMove(x, y)) {
          moveCount++;
        }
      }
      mustcapture = captureCount > 0;
      if (moveCount == 0 && captureCount == 0) {
        reason = "no possible movement";
        updateDrawgame();
      }
    }
  }

  void updateDrawgame() {
    won = false;
    pauseGame();
    Fluttertoast.showToast(msg: "It's a draw", toastLength: Toast.LENGTH_LONG);
    drawMoveCount = 0;
    roundsCount++;
    completedPlayertime = true;
    finishedRound = true;
    toastDraw();
    setState(() {});
  }

  void updateWingame(bool isTimer) {
    won = true;
    pauseGame();
    drawMoveCount = 0;
    final player = isTimer ? nextIndex(2, currentPlayer) : currentPlayer;

    playersScores[player]++;
    roundsCount++;
    updateMatchRecord();

    completedPlayertime = true;
    finishedRound = true;
    hintPositions.clear();
    toastWinner(player);
    setState(() {});
  }

  void toastDraw() {
    String message = "It's a draw with $reason";
    reasonMessage = message;
    showToast(0, message);
    showToast(1, message);
  }

  void toastWinner(int player) {
    String message =
        "${users != null ? users![player]?.username ?? "" : "Player ${player + 1}"} Won with $reason";
    reasonMessage = message;
    showToast(0, message);
    showToast(1, message);
  }

  void checkWingame() {
    final playerDraughts = playersDraughts[nextIndex(2, currentPlayer)];
    if (playerDraughts.isEmpty) {
      reason = "capturing all pieces";
      updateWingame(false);
    }
  }

  void changePlayer() {
    checkIfCanMove();
    checkForDraw();
    message = "Your Turn";
    getNextPlayer();
  }

  void getNextPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      final nextPlayerIndex = nextIndex(2, currentPlayerIndex);
      final playerId = playerIds[nextPlayerIndex];
      currentPlayerId = playerId;
      currentPlayer = nextPlayerIndex;
    } else {
      currentPlayer = nextIndex(2, currentPlayer);
    }
  }

  void getCurrentPlayer() {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      currentPlayerId = playerIds.last;
      lastPlayerId = currentPlayerId;
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      currentPlayer = currentPlayerIndex;
    } else {
      currentPlayer = 1;
    }
  }

  bool isDown(DraughtDirection direction) {
    return direction == DraughtDirection.bottomLeft ||
        direction == DraughtDirection.bottomRight;
  }

  DraughtDirection getDraughtDirection(int x, int y) {
    DraughtDirection direction = DraughtDirection.bottomLeft;
    if (x < 0 && y < 0) {
      direction = DraughtDirection.topLeft;
    } else if (x > 0 && y > 0) {
      direction = DraughtDirection.bottomRight;
    } else if (x < 0 && y > 0) {
      direction = DraughtDirection.bottomLeft;
    } else if (x > 0 && y < 0) {
      direction = DraughtDirection.topRight;
    }
    return direction;
  }

  int getX(DraughtDirection direction, int x, int step) {
    int newX = 0;
    if (direction == DraughtDirection.topRight ||
        direction == DraughtDirection.bottomRight) {
      newX = x + step;
    } else if (direction == DraughtDirection.topLeft ||
        direction == DraughtDirection.bottomLeft) {
      newX = x - step;
    }
    return newX;
  }

  int getY(DraughtDirection direction, int y, int step) {
    int newY = 0;
    if (direction == DraughtDirection.bottomRight ||
        direction == DraughtDirection.bottomLeft) {
      newY = y + step;
    } else if (direction == DraughtDirection.topRight ||
        direction == DraughtDirection.topLeft) {
      newY = y - step;
    }
    return newY;
  }

  bool exceedRange(int x, int y) =>
      x > gridSize - 1 || x < 0 || y > gridSize - 1 || y < 0;

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
          child: Stack(children: [
            ...List.generate(2, (index) {
              final wonPiecesIndex = landScape
                  ? index == 0
                      ? 1
                      : 0
                  : index;
              return Positioned(
                  top: landScape || index == 0 ? 0 : null,
                  bottom: landScape || index == 1 ? 0 : null,
                  left: !landScape || index == 0 ? 0 : null,
                  right: !landScape || index == 1 ? 0 : null,
                  child: Container(
                      width: landScape ? padding : minSize,
                      height: landScape ? minSize : padding,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RotatedBox(
                        quarterTurns: index == 0 ? 2 : 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (landScape) ...[
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 2,
                                  child: CustomGrid(
                                      height: wonDraughtSize * 2,
                                      width: padding,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      items: playersWonDraughts[wonPiecesIndex],
                                      gridSize: gridSize,
                                      itemBuilder: (pindex) {
                                        final draughts =
                                            playersWonDraughts[wonPiecesIndex];
                                        final draught = draughts[pindex];
                                        return Container(
                                          width: wonDraughtSize,
                                          height: wonDraughtSize,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: darkMode
                                                ? lightestWhite
                                                : lightestBlack,
                                            borderRadius: BorderRadius.only(
                                              topLeft: pindex == 0
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                              bottomLeft: (pindex == 0 &&
                                                          draughts.length <=
                                                              10) ||
                                                      pindex == 10
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                              topRight: pindex == 9 ||
                                                      (pindex ==
                                                              draughts.length -
                                                                  1 &&
                                                          draughts.length <= 10)
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                              bottomRight: pindex ==
                                                          draughts.length - 1 ||
                                                      pindex == 9
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: wonDraughtSize
                                                    .percentValue(75) /
                                                2,
                                            backgroundColor: draught.color == 1
                                                ? const Color(0xffF6BE00)
                                                : const Color(0xff722f37),
                                          ),
                                        );
                                      }),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
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
                                        timerStream: index == 0
                                            ? timerController1.stream
                                            : timerController2.stream,
                                      ),
                                      if (currentPlayer == index) ...[
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          message,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: darkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!landScape) ...[
                                        CustomGrid(
                                            height: wonDraughtSize * 2,
                                            width: padding,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            items: playersWonDraughts[index],
                                            gridSize: gridSize,
                                            itemBuilder: (pindex) {
                                              final draughts =
                                                  playersWonDraughts[index];
                                              final draught = draughts[pindex];
                                              return Container(
                                                width: wonDraughtSize,
                                                height: wonDraughtSize,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: darkMode
                                                      ? lightestWhite
                                                      : lightestBlack,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: pindex == 0
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                    bottomLeft: (pindex == 0 &&
                                                                draughts.length <=
                                                                    10) ||
                                                            pindex == 10
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                    topRight: pindex == 9 ||
                                                            (pindex ==
                                                                    draughts.length -
                                                                        1 &&
                                                                draughts.length <=
                                                                    10)
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                    bottomRight: pindex ==
                                                                draughts.length -
                                                                    1 ||
                                                            pindex == 9
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                  ),
                                                ),
                                                child: CircleAvatar(
                                                  radius: wonDraughtSize
                                                          .percentValue(75) /
                                                      2,
                                                  backgroundColor: draught
                                                              .color ==
                                                          1
                                                      ? const Color(0xffF6BE00)
                                                      : const Color(0xff722f37),
                                                ),
                                              );
                                            }),
                                      ],
                                      Text(
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
                child: Container(
                  color: Colors.white,
                  child: GridView(
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize),
                    children: List.generate(gridSize * gridSize, (index) {
                      final coordinates = convertToGrid(index, gridSize);
                      final x = coordinates[0];
                      final y = coordinates[1];
                      final draughtTile = draughtTiles[index];
                      return DraughtTileWidget(
                          blink: hintPositions.contains(index),
                          gameId: gameId,
                          key: Key(draughtTile.id),
                          x: x,
                          y: y,
                          highLight: selectedDraughtTile == draughtTile ||
                              (playPositions.isNotEmpty &&
                                  playPositions.contains(index)),
                          draughtTile: draughtTile,
                          onPressed: () {
                            if (awaiting) return;
                            if (gameId != "" && currentPlayerId != myId) {
                              showToast(1,
                                  "Its ${getUsername(currentPlayerId)}'s turn");
                              return;
                            }
                            if (gameId != "") {
                              updateDetails(index);
                            } else {
                              playDraught(index);
                            }
                          },
                          onLongPressed: () {},
                          size: size);
                    }),
                  ),
                ),
              ),
            ),
            Positioned(
              top: currentPlayer == 0 ? 40 : null,
              bottom: currentPlayer == 1 ? 40 : null,
              left: currentPlayer == 0 ? 20 : null,
              right: currentPlayer == 1 ? 20 : null,
              child: !multiSelect
                  ? Container()
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (multiSelect) {
                          if (gameId != "") {
                            updateDetails(-1);
                          } else {
                            if (playPositions.isNotEmpty) {
                              moveMultipleDraughts();
                            }
                            showPossiblePlayPositions();
                          }
                          multiSelect = false;
                        }
                        setState(() {});
                      },
                      child: RotatedBox(
                        quarterTurns:
                            gameId != "" && currentPlayer == 0 ? 2 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: RotatedBox(
                            quarterTurns:
                                gameId == "" && currentPlayer == 0 ? 2 : 0,
                            child: Text(
                              playPositions.isNotEmpty
                                  ? "Done Selecting"
                                  : "Unselect",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                        "Tap on any draught piece\nMake your move",
                        style: TextStyle(color: Colors.white, fontSize: 18),
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
            if (paused) ...[
              RotatedBox(
                quarterTurns: gameId != "" && myPlayer == 0 ? 2 : 0,
                child: PausedGamePage(
                  context: context,
                  reasonMessage: reasonMessage,
                  readAboutGame: readAboutGame,
                  game: "Draught",
                  playersScores: playersScores,
                  users: users,
                  playersSize: playersSize,
                  finishedRound: finishedRound,
                  startingRound: player1Time == maxChessDraughtTime &&
                      player2Time == maxChessDraughtTime,
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
          ]),
        ),
      ),
    );
  }
}
