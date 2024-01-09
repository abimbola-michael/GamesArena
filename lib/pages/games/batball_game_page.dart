import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:gamesarena/blocs/firebase_methods.dart';
import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/models/games/batball.dart';
import 'package:gamesarena/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../../components/game_timer.dart';
import '../../components/components.dart';
import '../../enums/emums.dart';
import '../../models/models.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../paused_game_page.dart';
import '../tabs/games_page.dart';

class BatballGamePage extends StatefulWidget {
  final String? matchId;
  final String? gameId;
  final List<User?>? users;
  final int? id;
  const BatballGamePage(
      {super.key, this.id, this.matchId, this.gameId, this.users});

  @override
  State<BatballGamePage> createState() => _BatballGamePageState();
}

class _BatballGamePageState extends State<BatballGamePage>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  bool played = false;
  BatBallDetails? prevDetails;
  double width = 0;
  double height = 0;
  double ballPosX = 0;
  double ballPosY = 0;
  double batWidth = 0;
  double batHeight = 0;
  double postHeight = 0;
  double postWidth = 0;
  int postThickness = 5;
  double player1dX = 0, player2dX = 0;
  double player1dY = 0, player2dY = 0;
  double player1BatX = 0, player2BatX = 0;
  double player1BatY = 0, player2BatY = 0;
  double playerDistanceFromPost = 50;
  double postX = 0;
  double player1PostY = 0, player2PostY = 0;
  double maxplayer1BatY = 0, maxplayer2BatY = 0;
  int speed = 10;
  int angle = 45;
  double incrementX = 1;
  double incrementY = 1;
  int minSpeed = 10;
  int maxSpeed = 25;
  int ballDiameter = 30, boardCenterDiammeter = 0;
  int currentTime = 0;
  int pauseTime = 0;
  List<int> playersScores = [];

  Direction vDir = Direction.down;
  Direction hDir = Direction.right;
  bool? ballHitX;
  bool hasHitBall = false;
  bool player1Hit = false;
  bool player2Hit = false;
  int timerCount = 3;
  int timeNow = DateTime.now().millisecondsSinceEpoch;
  GameMode gameMode = GameMode.idle;

  String myId = "";
  AnimationController? controller;
  FirebaseMethods fm = FirebaseMethods();
  FirebaseService fs = FirebaseService();
  String player1Action = "";
  String player2Action = "";

  List<User> selectedPlayers = [];
  // AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  String matchId = "";
  String gameId = "";
  int id = 0;
  String opponent_id = "";
  List<User?>? users = [];
  List<User?> notReadyUsers = [];
  List<Playing> playing = [];

  Timer? timer, perTimer;
  int playerTime = 20, gameTime = 0, adsTime = 0, roundsCount = 0;
  bool adLoaded = false, loadedInitial = false;
  bool paused = true,
      finishedRound = false,
      checkout = false,
      pausePlayerTime = false;
  int myPlayer = 0;
  String currentPlayerId = "";
  int currentPlayerIndex = 0;
  int currentPlayer = 0;
  double myX = 0, myY = 0, oppX = 0, oppY = 0;
  StreamSubscription? detailsSub;
  StreamSubscription<List<Playing>>? playingSub;
  double padding = 0;
  InterstitialAd? _interstitialAd;
  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool changingGame = false;
  String hintMessage = "";
  SharedPreferences? sharedPref;
  String reason = "";
  late StreamController<int> timerController;
  @override
  void initState() {
    super.initState();
    timerController = StreamController.broadcast();
    gameTime = maxGameTime;
    timerController.sink.add(gameTime);
    if (kIsWeb) ServicesBinding.instance.keyboard.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    id = widget.id ?? 0;
    myId = fs.myId;
    matchId = widget.matchId ?? "";
    gameId = widget.gameId ?? "";
    users = widget.users;
    gameTime = maxGameTime;
    checkFirstime();
    resetScores();
    readDetails();
  }

  void initDetails() {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeVariables();
    padding = (context.screenHeight - context.screenWidth) / 2;
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
    controller?.dispose();
    detailsSub?.cancel();
    playingSub?.cancel();
    super.dispose();
  }

  @override
  void deactivate() {
    stopTimer();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    super.deactivate();
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
          if (value.game != batballGame) {
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
      if (newgame != "" && newgame != batballGame) {
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

      currentPlayerId = users!.first!.user_id;
      currentPlayerIndex = users!.indexWhere(
          (element) => element != null && element.user_id == currentPlayerId);

      vDir = currentPlayerId == myId ? Direction.up : Direction.down;
      hDir = currentPlayerId == myId ? Direction.left : Direction.right;
      readPlaying();

      detailsSub = fs.getBatBallDetails(gameId).listen((details) async {
        if (details != null) {
          played = false;
          final angle = details.angle;
          final speed = details.speed;
          // final vDir = details.vDir;
          // final hDir = details.hDir;
          final player1X = details.player1X;
          final player1Y = details.player1Y;
          final player2X = details.player2X;
          final player2Y = details.player2Y;
          if (angle != null && this.angle != angle) {
            this.angle = angle;
          }
          if (speed != null && this.speed != speed) {
            this.speed = speed;
          }
          if (myPlayer == 0) {
            if (player1X != null && player1Y != null) {
              player2BatX = player1X;
              player2BatY = player1Y;
            }
            if (player2X != null && player2Y != null) {
              player1BatX = width - player2X;
              player1BatY = height - player2Y;
            }
          } else {
            if (player2X != null && player2Y != null) {
              player2BatX = player2X;
              player2BatY = player2Y;
            }
            if (player1X != null && player1Y != null) {
              player1BatX = width - player1X;
              player1BatY = height - player1Y;
            }
          }
          move(true, player1BatX, player1BatY);
          move(false, player2BatX, player2BatY);
          pausePlayerTime = false;
        }
      });
    }
  }

  void checkFirstime() async {
    sharedPref = await SharedPreferences.getInstance();
    int playTimes = sharedPref!.getInt(playedBatballGame) ?? 0;
    readAboutGame = playTimes == 0;
    if (playTimes < maxHintTime) {
      playTimes++;
      sharedPref!.setInt(playedBatballGame, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void flipHorizontalDirection() {
    hDir = hDir == Direction.left ? Direction.right : Direction.left;
  }

  void flipVerticalDirection() {
    vDir = vDir == Direction.down ? Direction.up : Direction.down;
  }

  void flipX() {
    player1BatX = width - player1BatX;
  }

  void flipY() {
    player1BatY = height - player1BatY;
  }

  void updateDetails(double batX, double batY) {
    if (matchId != "" && gameId != "" && users != null) {
      final details = myPlayer == 0
          ? BatBallDetails(player1X: batX, player1Y: batY)
          : BatBallDetails(player2X: batX, player2Y: batY);
      fs.setBatBallDetails(
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
          batballGame,
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
        resetPositions();
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
      resetPositions();
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
      if (newgame == batballGame) {
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

  int nextIndex(int index) {
    return index == 0 ? 1 : 0;
  }

  String getActionButton() {
    if (gameMode == GameMode.idle) {
      return "Play Game";
    } else if (gameMode == GameMode.paused) {
      return "Resume Game";
    } else if (gameMode == GameMode.idle) {
      return "Play Next Game";
    } else {
      return "";
    }
  }

  void moveBall() {
    //if (gameMode != GameMode.playing) return;
    Direction hDir =
        this.hDir.name == "left" ? Direction.left : Direction.right;
    Direction vDir = this.vDir.name == "up" ? Direction.up : Direction.down;

    if (ballPosX <= 0) {
      hDir = Direction.right;
    }
    if (ballPosX >= width - ballDiameter) {
      hDir = Direction.left;
    }
    if (ballPosY <= -ballDiameter) {
      winGame(true);
    }
    if (ballPosY >= height) {
      winGame(false);
    }
    if (ballPosY >= player1BatY - ballDiameter &&
        ballPosY <= player1BatY + batHeight &&
        ballPosX >= player1BatX - ballDiameter &&
        ballPosX <= player1BatX + batWidth) {
      if (ballPosY >= player1BatY - ballDiameter && !player1Hit) {
        vDir = Direction.up;
        player1Hit = true;
      } else if (ballPosY <= player1BatY + batHeight && !player1Hit) {
        vDir = Direction.down;
        player1Hit = true;
      }
    } else {
      player1Hit = false;
    }

    if (ballPosY <= player2BatY + batHeight &&
        ballPosY >= player2BatY - ballDiameter &&
        ballPosX >= player2BatX - ballDiameter &&
        ballPosX <= player2BatX + batWidth) {
      if (ballPosY >= player2BatY - ballDiameter && !player2Hit) {
        vDir = Direction.down;
        player2Hit = true;
      } else if (ballPosY <= player2BatY + batHeight && !player2Hit) {
        vDir = Direction.up;
        player2Hit = true;
      }
    } else {
      player2Hit = false;
    }

    // if (ballPosY <= postHeight && ballPosY >= -1) {
    //   if (ballPosX >= postX && ballPosX <= postX + postWidth - ballDiameter) {
    //     if (ballPosY <= 0) {
    //       winGame(true);
    //     } else {
    //       if (ballPosX >= postX + postWidth - ballDiameter) {
    //         hDir = Direction.left;
    //       } else if (ballPosX <= postX) {
    //         hDir = Direction.right;
    //       }
    //     }
    //   } else if (ballPosX >= postX - ballDiameter ||
    //       ballPosX <= postX + postWidth) {
    //     if (ballPosY >= (postHeight / 2) && ballPosY <= postHeight) {
    //       vDir = Direction.down;
    //     } else {
    //       if (ballPosX >= postX - ballDiameter) {
    //         hDir = Direction.left;
    //       } else if (ballPosX <= postX + postWidth) {
    //         hDir = Direction.right;
    //       }
    //     }
    //   } else {
    //     vDir = Direction.down;
    //   }
    // }

    // if (ballPosY >= height - postHeight - ballDiameter && ballPosY <= height) {
    //   if (ballPosX >= postX && ballPosX <= postX + postWidth - ballDiameter) {
    //     if (ballPosY >= height - ballDiameter) {
    //       winGame(false);
    //     } else {
    //       if (ballPosX >= postX + postWidth - ballDiameter) {
    //         hDir = Direction.left;
    //       } else if (ballPosX <= postX) {
    //         hDir = Direction.right;
    //       }
    //     }
    //   } else if (ballPosX >= postX - ballDiameter ||
    //       ballPosX <= postX + postWidth) {
    //     if (ballPosY >= height - postHeight - ballDiameter &&
    //         ballPosY <= height - ballDiameter - (postHeight / 2)) {
    //       vDir = Direction.up;
    //     } else {
    //       if (ballPosX >= postX - ballDiameter) {
    //         hDir = Direction.left;
    //       } else if (ballPosX <= postX + postWidth) {
    //         hDir = Direction.right;
    //       }
    //     }
    //   } else {
    //     vDir = Direction.up;
    //   }
    // }

    // setState(() {
    // if (ballPosX >= double.infinity) {
    //   ballPosX = width;
    // } else if (ballPosX <= double.negativeInfinity) {
    //   ballPosX = 0;
    // } else if (ballPosX.isNaN) {
    //   ballPosX = 0;
    // }

    // if (ballPosY >= double.infinity) {
    //   ballPosY = height;
    // } else if (ballPosY <= double.negativeInfinity) {
    //   ballPosY = 0;
    // } else if (ballPosY.isNaN) {
    //   ballPosY = 0;
    // }

    if (this.hDir != hDir || this.vDir != vDir || player1Hit || player2Hit) {
      if (this.hDir != hDir) this.hDir = hDir;
      if (this.vDir != vDir) this.vDir = vDir;
      //if (gameStarted) gameStarted = false;
      final hitX = this.hDir != hDir;
      bool hasHit = false;
      if (player1Hit) {
        changeHitDetails(true, player1dX.toInt(), player1dY.toInt());
        hasHit = true;
      }
      if (player2Hit) {
        changeHitDetails(false, player2dX.toInt(), player2dY.toInt());
        hasHit = true;
      }
      if (hasHit) {
        playHitBallSound();
      } else {
        playHitEdgeSound();
      }
      changeBallDirection(hitX, hasHit);
    }

    final additionX = incrementX * speed;
    final additionY = incrementY * speed;

    // this.hDir == Direction.right
    //     ? ballPosX + additionX >= width
    //         ? width
    //         : ballPosX += additionX
    //     : ballPosX - additionX <= 0
    //         ? 0
    //         : ballPosX -= additionX;
    // this.vDir == Direction.down
    //     ? ballPosY + additionY >= height
    //         ? height
    //         : ballPosY += additionY
    //     : ballPosY - additionY <= 0
    //         ? 0
    //         : ballPosY -= additionY;

    this.hDir == Direction.right
        ? ballPosX += additionX
        : ballPosX -= additionX;
    this.vDir == Direction.down ? ballPosY += additionY : ballPosY -= additionY;

    // if (opponent == null) {
    //   player2BatX = ballPosX.toDouble() >= width - ballDiameter
    //       ? width.toDouble() - ballDiameter
    //       : ballPosX <= 0
    //           ? 0
    //           : ballPosX - (batWidth ~/ 2);
    // }
    setState(() {});
  }

  void changeBallDirection(bool hitX, bool hasHit) {
    if (!hasHit) {
      if (speed < minSpeed) {
        speed = minSpeed;
      } else {
        speed--;
      }
    }
    final hitPointX = ballPosX;
    final hitPointY = ballPosY;
    if (ballHitX != null) {
      if (ballHitX != hitX) {
        if (!hasHit) {
          angle = 90 - angle;
        }
        ballHitX = hitX;
      }
    } else {
      ballHitX = hitX;
    }
    if (hitX) {
      final remainingY = vDir == Direction.up ? ballPosY : height - hitPointY;
      final expectedX = (angle / 45) * remainingY;
      if (expectedX > remainingY) {
        incrementX = remainingY / expectedX;
        incrementY = 1;
      } else {
        incrementX = 1;
        incrementY = expectedX / remainingY;
      }
    } else {
      final remainingX = hDir == Direction.left ? ballPosX : width - hitPointX;
      final expectedY = (angle / 45) * remainingX;
      if (expectedY > remainingX) {
        incrementX = remainingX / expectedY;
        incrementY = 1;
      } else {
        incrementX = 1;
        incrementY = expectedY / remainingX;
      }
    }
  }

  void setHitBall(int speed, int angle, String vDir, String hDir) {
    this.speed = speed;
    this.angle = angle;
    this.vDir = vDir == "up" ? Direction.up : Direction.down;
    this.hDir = vDir == "left" ? Direction.left : Direction.right;
  }

  void changeHitDetails(bool playerOne, int dx, int dy) {
    if (!hasHitBall) hasHitBall = true;
    // if (dx >= double.infinity) {
    //   dx = width;
    // } else if (dx <= double.negativeInfinity) {
    //   dx = 0;
    // }
    // if (dy >= double.infinity) {
    //   dy = height;
    // } else if (dy <= double.negativeInfinity) {
    //   dy = 0;
    // }
    final distance = getDistance(dx.toDouble(), dy.toDouble());
    Fluttertoast.showToast(msg: "dx = $dx, dy = $dy, distance = $distance");

    int derivedSpeed = 0;
    if (dx != 0) {
      hDir = dy > 0
          ? dx > 0
              ? Direction.left
              : Direction.right
          : dx > 0
              ? Direction.right
              : Direction.left;

      //hDir = hDir == Direction.left ? Direction.right : Direction.left;

      if (dy == 0) {
        angle = 90 - angle;
        derivedSpeed = (dx * 2).toInt();
      } else {
        angle = atan2(dy.abs(), dx.abs()).toDegrees;
        derivedSpeed = (distance * 2).toInt();
      }
    } else {
      if (dy == 0) {
        angle = 90 - angle;
        derivedSpeed--;
      } else {
        angle = 90;
        derivedSpeed = (dy * 2).toInt();
      }
    }
    derivedSpeed = derivedSpeed < minSpeed
        ? minSpeed
        : derivedSpeed > maxSpeed
            ? maxSpeed
            : derivedSpeed;
    if (derivedSpeed > speed) {
      speed = derivedSpeed;
    }
  }

  void setBatMovement(double batX, double batY, bool playerOne) {
    if (playerOne) {
      player1BatX = batX;
      player1BatY = batY;
    } else {
      player2BatX = batX;
      player2BatY = batY;
    }
  }

  double getDistance(double dx, double dy) {
    return sqrt((dx * dx) + (dy * dy));
  }

  void move(bool playerOne, double batX, double batY) {
    if (playerOne) {
      player1BatX = batX;
      player1BatY = batY;
    } else {
      player2BatX = batX;
      player2BatY = batY;
    }
  }

  void moveBat(bool playerOne, double dx, double dy) {
    // if (gameMode != GameMode.playing) return;

    if (playerOne) {
      final player1xResult = this.player1BatX + dx;
      final player1yResult = this.player1BatY + dy;

      double player1BatX = player1xResult <= 0
          ? 1
          : player1xResult >= width - batWidth
              ? width - batWidth + 1
              : player1xResult;

      double player1BatY = player1yResult <= 0
          ? 1
          : player1yResult >= height - batHeight
              ? height - batHeight + 1
              : player1yResult;
      move(playerOne, player1BatX, player1BatY);
    } else {
      final player2xResult = this.player2BatX + dx;
      final player2yResult = this.player2BatY + dy;

      double player2BatX = player2xResult <= 0
          ? 1
          : player2xResult >= width - batWidth
              ? width - batWidth + 1
              : player2xResult;

      double player2BatY = player2yResult <= 0
          ? 1
          : player2yResult >= height - batHeight
              ? height - batHeight + 1
              : player2yResult;
      if (gameId != "") {
        updateDetails(player2BatX, player2BatY);
      } else {
        move(playerOne, player2BatX, player2BatY);
      }
    }
    setState(() {});
  }

  void resetPositions() {
    finishedRound = false;
    setState(() {
      ballPosX = (width / 2) - (ballDiameter / 2);
      ballPosY = (height / 2) - (ballDiameter / 2);
      player1BatX = (width / 2) - (batWidth / 2);
      player2BatX = (width / 2) - (batWidth / 2);
      player1BatY = 50;
      player2BatY = height - 50 - batHeight;
      // angle = Random().nextInt(90);
      // vDir = Random().nextInt(2) == 0 ? Direction.up : Direction.down;
      // hDir = Random().nextInt(2) == 0 ? Direction.left : Direction.right;
      speed = minSpeed;
      incrementX = 1;
      incrementY = 1;
      hasHitBall = false;
    });
  }

  void initializeVariables() {
    height = context.screenHeight;
    width = context.screenWidth;
    batWidth = context.screenWidthPercentage(20);
    batHeight = context.screenHeightPercentage(4);
    postWidth = context.screenWidthPercentage(70);
    postHeight = context.screenHeightPercentage(5);
    boardCenterDiammeter = context.screenWidthPercentage(50).toInt();
    ballPosX = width / 2 - ballDiameter / 2;
    ballPosY = (height / 2) - (ballDiameter / 2);
    player1BatX = (width / 2) - (batWidth / 2);
    player2BatX = (width / 2) - (batWidth / 2);
    player1BatY = 50;
    player2BatY = height - 50 - batHeight;
    // player1BatY =
    //     height - postHeight.toDouble() - playerDistanceFromPost - batHeight;
    // player2BatY = postHeight.toDouble() + playerDistanceFromPost;
    // angle = Random().nextInt(90);
    // vDir = Random().nextInt(2) == 0 ? Direction.up : Direction.down;
    // hDir = Random().nextInt(2) == 0 ? Direction.left : Direction.right;
    postX = context.screenWidthPercentage(15);
    postX = context.screenWidthPercentage(15);
    player1PostY = height - postHeight;
    player2PostY = postHeight;
    maxplayer1BatY = (height ~/ 2) + batHeight;
    maxplayer2BatY = (height ~/ 2) - batHeight;
    speed = minSpeed;
  }

  void initializeController() {
    controller =
        AnimationController(duration: const Duration(minutes: 20), vsync: this);
    controller!.addListener(() {
      if (gameMode == GameMode.playing) moveBall();
    });
    controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (gameMode == GameMode.playing) {
          setState(() {
            gameMode = GameMode.idle;
          });
        }
      }
    });
    controller!.forward(from: pauseTime.toDouble());
    setState(() {
      gameMode = GameMode.playing;
    });
  }

  void winGame(bool playerOne) async {
    if (!playerOne) {
      playersScores[0]++;
    } else {
      playersScores[1]++;
    }
    updateMatchRecord();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate();
    }
    stopTimer();
    resetPositions();
  }

  void gotoMainMenu() {
    pauseTime = 0;
    stopTimer();
    resetPositions();
    setState(() {
      gameMode == GameMode.idle;
    });
  }

  void resetScores() {
    playersScores = List.generate(2, (index) => 0);
  }

  void startTimer() async {
    pausePlayerTime = false;
    setState(() {
      gameMode = GameMode.loading;
    });
    paused = false;
    timer?.cancel();
    perTimer?.cancel();
    timer = null;
    perTimer = null;
    perTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      this.timer = timer;
      if (!mounted) return;
      if (gameMode == GameMode.loading) {
        if (timerCount <= 0) {
          timerCount = 3;
          initializeController();
        } else {
          setState(() {
            timerCount--;
          });
        }
      } else {
        if (gameTime <= 0) {
          roundsCount++;
          finishedRound = true;
          stopTimer();
        } else {
          if (adsTime >= maxAdsTime) {
            loadAd();
            adsTime = 0;
          } else {
            adsTime++;
          }
          gameTime--;
        }
      }
      timerController.sink.add(gameTime);
      //setState(() {});
    });
  }

  void stopTimer() {
    gameMode = GameMode.paused;
    paused = true;
    perTimer?.cancel();
    timer?.cancel();
    perTimer = null;
    timer = null;
    pauseTime = controller?.value.toInt() ?? 0;
    controller?.dispose();
    controller = null;
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

  void playHitBallSound() {
    // assetsAudioPlayer.stop();
    // assetsAudioPlayer.open(
    //   Audio("assets/audios/hit-ball-60701.mp3"),
    // );
  }

  void playHitEdgeSound() {
    // assetsAudioPlayer.stop();
    // assetsAudioPlayer.open(
    //   Audio("assets/audios/mixkit-ball-bouncing-in-the-ground-2077.wav"),
    // );
  }
  void gotoLoginOrSignUp(bool login) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LoginPage(
              login: login,
            )));
  }

  @override
  bool get wantKeepAlive => true;

  void getMatchRecords() async {
    // if (playersFormation.isNotEmpty) {
    //   for (int i = 0; i < playersFormation.length; i++) {
    //     final formation = playersFormation[i];
    //     // final record = await fs.getMatchRecord(
    //     //     gameId, matchId, formation.player1??"", formation.player2??"");
    //     // if (record != null) {
    //     //   formation.player1Score = record.score1;
    //     //   formation.player2Score = record.score2;
    //     // }
    //   }
    // }
    // setState(() {});
  }

  void getGame() {
    if (matchId != "" && gameId != "" && opponent_id != "") {
      // detailsSub = fs
      //     .getGameDetails(gameId, matchId, opponent_id)
      //     .listen((details) async {
      //   if (details != null) {
      played = false;
      //     player2BatX = width - details.dx;
      //     player2BatY = details.dy;
      //     speed = details.speed;
      //     angle = details.angle;
      //     vDir = details.vDir == Direction.down ? Direction.up : Direction.down;
      //     hDir =
      //         details.hDir == Direction.left ? Direction.right : Direction.left;
      //     player2Action = details.action;
      //     setState(() {});
      //   }
      // });
    }
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
            alignment: Alignment.center,
            children: [
              BoardCenter(
                diameter: boardCenterDiammeter,
              ),
              Container(
                height: 5,
                width: width,
                color: darkMode ? Colors.white : Colors.black,
              ),

              // Container(
              //   decoration: BoxDecoration(
              //     border: Border.all(
              //         width: 5,
              //         color: darkMode ? Colors.white : Colors.black),
              //   ),
              // ),

              // Padding(
              //   padding: const EdgeInsets.all(30.0),
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     crossAxisAlignment: CrossAxisAlignment.stretch,
              //     children: [
              //       Padding(
              //         padding: const EdgeInsets.all(8.0),
              //         child: gameMode == GameMode.idle
              //             ? Container()
              //             : Text(
              //                 player2Name,
              //                 textAlign: TextAlign.center,
              //                 style: const TextStyle(fontSize: 18),
              //               ),
              //       ),
              //       Text(
              //         '$player2Score',
              //         style: TextStyle(
              //             fontWeight: FontWeight.bold,
              //             fontSize: 60,
              //             color: darkMode
              //                 ? Colors.white.withOpacity(0.5)
              //                 : Colors.black.withOpacity(0.5)),
              //         textAlign: TextAlign.center,
              //       ),
              //       gameMode == GameMode.playing
              //           ? GameTimer(
              //               time: controller == null
              //                   ? pauseTime.toInt()
              //                   : controller?.value.toInt() ?? 0)
              //           : Container(),
              //       Text(
              //         '$player1Score',
              //         style: TextStyle(
              //             fontWeight: FontWeight.bold,
              //             fontSize: 60,
              //             color: darkMode
              //                 ? Colors.white.withOpacity(0.5)
              //                 : Colors.black.withOpacity(0.5)),
              //         textAlign: TextAlign.center,
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(8.0),
              //         child: gameMode == GameMode.idle
              //             ? Container()
              //             : Text(
              //                 player1Name,
              //                 textAlign: TextAlign.center,
              //                 style: const TextStyle(fontSize: 18),
              //               ),
              //       ),
              //     ],
              //   ),
              // ),
              Positioned(
                left: 0,
                right: 0,
                bottom: padding - 95,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${playersScores.second}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 60,
                          color: darkMode
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5)),
                      textAlign: TextAlign.center,
                    ),
                    GameTimer(
                      timerStream: timerController.stream,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: padding - 95,
                child: RotatedBox(
                  quarterTurns: gameId == "" ? 2 : 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${playersScores.first}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 60,
                            color: darkMode
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.5)),
                        textAlign: TextAlign.center,
                      ),
                      GameTimer(
                        timerStream: timerController.stream,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: RotatedBox(
                  quarterTurns: gameId == "" ? 2 : 0,
                  child: Text(
                    users != null ? users![0]?.username ?? "" : "Player 1",
                    style: TextStyle(
                        fontSize: 20,
                        color: darkMode ? Colors.white : Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Text(
                  "${users != null ? users![1]?.username ?? "" : "Player 2"} ",
                  style: TextStyle(
                      fontSize: 20,
                      color: darkMode ? Colors.white : Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                top: ballPosY,
                left: ballPosX,
                child: Ball(
                  diameter: ballDiameter.toDouble(),
                ),
              ),
              Positioned(
                top: player2BatY,
                left: player2BatX,
                child: Bat(
                  width: batWidth,
                  height: batHeight,
                  color: Colors.blue,
                ),
              ),
              Positioned(
                top: player1BatY,
                left: player1BatX,
                child: Bat(
                  width: batWidth,
                  height: batHeight,
                  color: Colors.red,
                ),
              ),

              // Positioned(
              //   top: 0,
              //   left: 0,
              //   right: 0,
              //   child: Container(
              //     alignment: Alignment.center,
              //     child: Post(
              //       height: postHeight,
              //       width: postWidth,
              //       down: true,
              //     ),
              //   ),
              // ),
              // Positioned(
              //   bottom: 0,
              //   left: 0,
              //   right: 0,
              //   child: Container(
              //     alignment: Alignment.center,
              //     child: Post(
              //       height: postHeight,
              //       width: postWidth,
              //       down: false,
              //     ),
              //   ),
              // ),
              Positioned.fill(
                  child: Column(
                children: [
                  if (gameId == "") ...[
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (details) {
                          player1dX = details.delta.dx;
                          player1dY = details.delta.dy;
                          moveBat(true, player1dX, player1dY);
                        },
                        onPanEnd: (details) {
                          player1dX = 0;
                          player1dY = 0;
                        },
                        child: SizedBox(
                          height: height / 2,
                          width: width,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (details) {
                        player2dX = details.delta.dx;
                        player2dY = details.delta.dy;
                        moveBat(false, player2dX, player2dY);
                      },
                      onPanEnd: (details) {
                        player2dX = 0;
                        player2dY = 0;
                      },
                      child: SizedBox(
                        height: height / 2,
                        width: width,
                      ),
                    ),
                  ),
                ],
              )),
              Center(
                child: gameMode == GameMode.loading
                    ? Text(
                        timerCount == 0 ? "Go" : "$timerCount",
                        style: TextStyle(
                            fontSize: 80,
                            color: darkMode ? Colors.white : Colors.black),
                      )
                    : Container(),
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
                          "Hold down and move around half of the screen\nHit the ball\nDefend your post",
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
                    readAboutGame: readAboutGame,
                    game: "Bat Ball",
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

              // Positioned.fill(
              //   child: Column(
              //     children: [
              //       // Text(
              //       //   "Bat Ball",
              //       //   style: GoogleFonts.orbitron(fontSize: 30),
              //       // ),
              //       if (gameMode == GameMode.idle) ...[
              //         Text(
              //           player1Score > player2Score ? "You Won" : "You Lost",
              //           style: const TextStyle(fontSize: 24),
              //           textAlign: TextAlign.center,
              //         ),
              //         const SizedBox(
              //           height: 16,
              //         ),
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Column(
              //               mainAxisSize: MainAxisSize.min,
              //               children: [
              //                 Text(
              //                   "$player1Score",
              //                   style: const TextStyle(fontSize: 50),
              //                   textAlign: TextAlign.center,
              //                 ),
              //                 const SizedBox(
              //                   height: 16,
              //                 ),
              //                 Text(
              //                   player1Name,
              //                   style: const TextStyle(fontSize: 25),
              //                   textAlign: TextAlign.center,
              //                 ),
              //               ],
              //             ),
              //             Container(
              //               width: 50,
              //               height: 10,
              //               color: tintColor,
              //               padding: const EdgeInsets.symmetric(horizontal: 20),
              //             ),
              //             Column(
              //               mainAxisSize: MainAxisSize.min,
              //               children: [
              //                 Text(
              //                   "$player2Score",
              //                   style: const TextStyle(fontSize: 50),
              //                   textAlign: TextAlign.center,
              //                 ),
              //                 const SizedBox(
              //                   height: 16,
              //                 ),
              //                 Text(
              //                   player2Name,
              //                   style: const TextStyle(fontSize: 25),
              //                   textAlign: TextAlign.center,
              //                 ),
              //               ],
              //             ),
              //           ],
              //         ),

              //       ],
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
