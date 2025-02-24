import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/firebase_service.dart';
import '../../components/game_timer.dart';
import '../../components/custom_grid.dart';
import '../../components/custom_toast.dart';
import '../../components/games/chess_tile.dart';
import '../../enums/emums.dart';
import '../../models/games/chess.dart';
import '../../models/models.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../paused_game_page.dart';
import '../tabs/games_page.dart';

class ChessGamePage extends StatefulWidget {
  final String? matchId;
  final String? gameId;
  final List<User?>? users;
  final int? id;

  const ChessGamePage({
    super.key,
    this.matchId,
    this.gameId,
    this.users,
    this.id,
  });

  @override
  State<ChessGamePage> createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool played = false;
  ChessDetails? prevDetails;
  int gridSize = 8;
  double size = 0, wonChessSize = 0;
  ChessTile? selectedChessTile, pawnPositionChessTile;
  List<ChessTile> chessTiles = [];
  List<List<Chess>> playersChesses = [];
  List<List<Chess>> playersWonChesses = [];
  List<int> playersScores = [];
  List<String> playersToasts = [];
  List<String> gamePatterns = [];

  int drawMoveCount = 0;
  int maxDrawMoveCount = 50;

  int currentPlayer = -1;
  double messagePadding = 0, wonChessesPadding = 60, pawnPromotionPadding = 60;
  bool choosePawnPromotion = false;
  String message = "Your Turn";
  double padding = 0;
  int player1KingPos = 4;
  int player2KingPos = 60;
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
      pausePlayerTime = false;
  InterstitialAd? _interstitialAd;
  String matchId = "";
  String gameId = "";
  int id = 0;
  String myId = "";
  String opponentId = "";
  List<User?>? users;
  List<User?> notReadyUsers = [];
  List<Playing> playing = [];
  List<int> hintPositions = [];

  int myPlayer = 0;
  String currentPlayerId = "";
  String updatePlayerId = "";

  int currentPlayerIndex = 0;
  StreamSubscription? detailsSub;
  StreamSubscription<List<Playing>>? playingSub;
  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool changingGame = false;
  bool won = false;
  int checkingPos = -1;
  String drawReason = "";
  String hintMessage = "";
  int enpassantPos = -1;
  SharedPreferences? sharedPref;
  bool landScape = false;
  double minSize = 0, maxSize = 0;
  String reason = "", reasonMessage = "";
  FirebaseService fs = FirebaseService();

  List<ChessShape> chessShapes = [
    ChessShape.queen,
    ChessShape.bishop,
    ChessShape.rook,
    ChessShape.knight,
  ];
  List<ChessShape> shapes = [
    ChessShape.king,
    ChessShape.queen,
    ChessShape.bishop,
    ChessShape.rook,
    ChessShape.knight,
    ChessShape.pawn,
  ];

  List<ChessDirection> diagonalDirections = [
    ChessDirection.topLeft,
    ChessDirection.topRight,
    ChessDirection.bottomLeft,
    ChessDirection.bottomRight
  ];
  List<ChessDirection> edgeDirections = [
    ChessDirection.top,
    ChessDirection.right,
    ChessDirection.left,
    ChessDirection.bottom
  ];
  List<ChessDirection> knightDirections = [
    ChessDirection.topLeftLeft,
    ChessDirection.topRightRight,
    ChessDirection.bottomLeftLeft,
    ChessDirection.bottomRightRight,
    ChessDirection.bottomBottomLeft,
    ChessDirection.bottomBottomRight,
    ChessDirection.topTopLeft,
    ChessDirection.topTopRight,
  ];
  List<ChessDirection> allDirections = [
    ChessDirection.topRight,
    ChessDirection.topLeft,
    ChessDirection.bottomRight,
    ChessDirection.bottomLeft,
    ChessDirection.top,
    ChessDirection.bottom,
    ChessDirection.left,
    ChessDirection.right,
    ChessDirection.topTopRight,
    ChessDirection.topTopLeft,
    ChessDirection.topLeftLeft,
    ChessDirection.topRightRight,
    ChessDirection.bottomRightRight,
    ChessDirection.bottomLeftLeft,
    ChessDirection.bottomBottomRight,
    ChessDirection.bottomBottomLeft,
  ];
  late StreamController<int> timerController1, timerController2;
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
    wonChessSize = padding / 10;
    wonChessesPadding = padding - size - 20;
    messagePadding = wonChessesPadding - 30;
  }

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
    id = widget.id ?? 0;
    myId = fs.myId;
    users = widget.users;
    matchId = widget.matchId ?? "";
    gameId = widget.gameId ?? "";
    initDetails();
    checkFirstime();
    resetScores();
    readDetails();
    addInitialChesses();
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
    pausePlayerTime = false;
    paused = false;
    timer?.cancel();
    perTimer?.cancel();
    timer = null;
    perTimer = null;
    perTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      this.timer = timer;
      if (!mounted) return;
      //if (!pausePlayerTime) {
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
      //}
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

  void addInitialChesses() {
    won = false;
    reason = "";
    reasonMessage = "";
    player1KingPos = 4;
    player2KingPos = 60;
    getCurrentPlayer();
    finishedRound = false;
    message = "Your Turn";
    hintPositions.clear();
    playersChesses.clear();
    playersWonChesses.clear();
    chessTiles.clear();
    checkingPos = -1;

    for (int i = 0; i < 2; i++) {
      playersChesses.add([]);
      playersWonChesses.add([]);
    }
    chessTiles = List.generate(gridSize * gridSize, (index) {
      Chess? chess;
      final coordinates = convertToGrid(index, gridSize);
      final x = coordinates[0];
      final y = coordinates[1];
      ChessShape shape = ChessShape.pawn;
      if (y == 1 || y == 6) {
        shape = ChessShape.pawn;
      } else if (y == 0 || y == 7) {
        if (x == 0 || x == 7) {
          shape = ChessShape.rook;
        } else if (x == 1 || x == 6) {
          shape = ChessShape.knight;
        } else if (x == 2 || x == 5) {
          shape = ChessShape.bishop;
        } else if (x == 3) {
          shape = ChessShape.queen;
        } else if (x == 4) {
          shape = ChessShape.king;
        }
      }
      if (y < 2) {
        chess = Chess(x, y, "$index", 0, 0, shape, false);
        playersChesses[0].add(chess);
      } else if (y > 5) {
        chess = Chess(x, y, "$index", 1, 1, shape, false);
        playersChesses[1].add(chess);
      }
      return ChessTile(x, y, "$index", chess);
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
          if (value.game != chessGame) {
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
      if (newgame != "" && newgame != chessGame) {
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
      detailsSub = fs.getChessDetails(gameId).listen((details) async {
        if (details != null) {
          played = false;
          pausePlayerTime = false;
          final playPos = details.playPos;
          // final pawnPromotionIndex = details.pawnPromotionIndex;
          // if (pawnPromotionIndex != null && pawnPromotionIndex != -1) {
          //   updateChessPromotion(index);
          //   return;
          // }
          if (playPos != -1) {
            if (choosePawnPromotion) {
              updateChessPromotion(playPos);
            } else {
              //int actualPos = convertPos(playPos, currentPlayerId);
              playChess(playPos);
            }
          } else {
            selectedChessTile = null;
            changePlayer();
          }
          pausePlayerTime = false;

          setState(() {});
        }
      });
    }
  }

  void updateDetails(int playPos) {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = ChessDetails(
        currentPlayerId: myId,
        playPos: playPos,
      );
      fs.setChessDetails(
        gameId,
        details,
        prevDetails,
      );
      prevDetails = details;
    }
  }

  void updatePawnPromotionDetails(int pawnPromotionIndex) {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = ChessDetails(
        currentPlayerId: myId,
        playPos: pawnPromotionIndex,
      );
      fs.setChessDetails(
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
    return convertToPosition([7 - x, 7 - y], gridSize);
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
          chessGame,
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
        addInitialChesses();
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
      addInitialChesses();
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
      if (newgame == chessGame) {
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

  String getAsset(ChessShape shape) {
    String asset = "";
    if (shape == ChessShape.bishop) {
      asset = "assets/svgs/chess_bishop_icon.svg";
    } else if (shape == ChessShape.knight) {
      asset = "assets/svgs/chess_horse_knight_icon.svg";
    } else if (shape == ChessShape.king) {
      asset = "assets/svgs/chess_king_icon.svg";
    } else if (shape == ChessShape.pawn) {
      asset = "assets/svgs/chess_pawn_icon.svg";
    } else if (shape == ChessShape.queen) {
      asset = "assets/svgs/chess_queen_icon.svg";
    } else if (shape == ChessShape.rook) {
      asset = "assets/svgs/chess_rook_icon.svg";
    }
    return asset;
  }

  void updateChessPromotion(int index) {
    final selectedChessShape = chessShapes[index];
    choosePawnPromotion = false;
    selectedChessTile!.chess!.shape = selectedChessShape;
    pawnPositionChessTile!.chess = selectedChessTile!.chess;
    selectedChessTile!.chess = null;
    selectedChessTile = null;
    pawnPositionChessTile = null;

    final check = checkForCheck();
    if (check) {
      final checkMate = checkForCheckmate();
      if (checkMate) {
        message = "CheckMate";
        reason = "Checkmate";
        setState(() {});
        updateWingame(false);
      } else {
        message = "Check";
      }
    } else {
      message = "Your Turn";
    }
    hintPositions.clear();
    changePlayer();
    setState(() {});
  }

  void showToastMessage(int player, String message) {
    Fluttertoast.showToast(
        msg: message,
        gravity: player == 1 ? ToastGravity.BOTTOM : ToastGravity.TOP);
  }

  void showPossiblePlayPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    final playerChesses = playersChesses[currentPlayer];
    for (int i = 0; i < playerChesses.length; i++) {
      final chess = playerChesses[i];
      int pos = convertToPosition([chess.x, chess.y], gridSize);
      hintPositions.add(pos);
    }
    //getHintMessage(true);
    setState(() {});
  }

  void playChess(int pos) {
    //hintPositions.clear();
    final chessTile = chessTiles[pos];

    if (chessTile.chess != null) {
      if (chessTile.chess!.player != currentPlayer &&
          selectedChessTile == null) {
        final color = currentPlayer == 0 ? "black" : "white";
        showToast(currentPlayer,
            "This is not your chess piece. Your chess piece color is $color");

        return;
      }

      if (selectedChessTile != null) {
        if (selectedChessTile == chessTile) {
          selectedChessTile = null;
          hintPositions.clear();
          showPossiblePlayPositions();
        } else if (selectedChessTile!.chess!.player == currentPlayer &&
            chessTile.chess!.player != currentPlayer) {
          moveChess(pos);
        } else {
          selectedChessTile = chessTile;
          getHintPositions(pos);
          //selectChessIfNotPinned(pos);
        }
      } else {
        selectedChessTile = chessTile;
        getHintPositions(pos);
        //selectChessIfNotPinned(pos);
      }
      setState(() {});
    } else {
      if (selectedChessTile != null) {
        moveChess(pos);
      }
    }
  }

  bool canCastle(ChessDirection direction) {
    if (direction != ChessDirection.right && direction != ChessDirection.left) {
      return false;
    }
    if (selectedChessTile == null) return false;

    final x = selectedChessTile!.x;
    final y = selectedChessTile!.y;
    final kingChess = selectedChessTile!.chess!;
    final kingPos = convertToPosition([x, y], gridSize);

    if ((currentPlayer == 0 && y != 0) || (currentPlayer == 1 && y != 7)) {
      return false;
    }
    if (x != 4 || kingChess.moved || checkingPos != -1) {
      return false;
    }
    final checkX = direction == ChessDirection.right ? 5 : 3;
    final possibleCheckPos = convertToPosition([checkX, y], gridSize);
    final check = checkForPossibleCheckForKing(possibleCheckPos);
    if (check) return false;

    for (int i = 1; i < 5; i++) {
      int pointX = getX(direction, x, i);
      int pointY = getY(direction, y, i);
      if (exceedRange(pointX, pointY)) return false;
      final pointChessPos = convertToPosition([pointX, pointY], gridSize);
      final pointChessTile = chessTiles[pointChessPos];
      if (pointChessTile.chess != null &&
          pointChessTile.chess!.shape == ChessShape.rook &&
          !pointChessTile.chess!.moved) {
        return true;
      }
    }
    return false;
  }

  void moveChess(int pos) {
    final chessTile = chessTiles[pos];
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    final prevCoordinates =
        convertToGrid(int.parse(selectedChessTile!.id), gridSize);
    final selX = prevCoordinates[0];
    final selY = prevCoordinates[1];
    final xDiff = (x - selX).abs();
    final yDiff = (y - selY).abs();
    final selectedChess = selectedChessTile!.chess!;
    final direction =
        getChessDirection(x - selX, y - selY, selectedChess.shape);
    bool canCas = false;
    if (selectedChess.shape == ChessShape.king) {
      canCas = canCastle(direction);
    }
    final pawnCond = ((yDiff <= 2 && xDiff == 0) ||
        (xDiff == yDiff && xDiff == 1 && yDiff == 1));
    final rookCond = ((xDiff > 0 && yDiff == 0) || (yDiff > 0 && xDiff == 0));
    final knightCond =
        ((xDiff == 2 && yDiff == 1) || (yDiff == 2 && xDiff == 1));

    final bishopCond = ((xDiff == yDiff) && (xDiff > 0 && yDiff > 0));
    final queenCond = (rookCond || bishopCond);
    final kingCond =
        (((xDiff == 1 && yDiff == 0) || (yDiff == 1 && xDiff == 0)) ||
                ((xDiff == yDiff) && (xDiff == 1 && yDiff == 1))) ||
            (canCas && xDiff == 2 && yDiff == 0);
    List<int> foundChessPositions = [];
    if ((selectedChess.shape == ChessShape.pawn && pawnCond) ||
        (selectedChess.shape == ChessShape.rook && rookCond) ||
        (selectedChess.shape == ChessShape.knight && knightCond) ||
        (selectedChess.shape == ChessShape.bishop && bishopCond) ||
        (selectedChess.shape == ChessShape.queen && queenCond) ||
        (selectedChess.shape == ChessShape.king && kingCond)) {
      final count = (selectedChess.shape == ChessShape.pawn ||
              selectedChess.shape == ChessShape.knight ||
              selectedChess.shape == ChessShape.king)
          ? 1
          : xDiff > yDiff
              ? xDiff
              : yDiff;

      if (selectedChess.shape == ChessShape.pawn &&
          ((!(y - selY).isNegative && currentPlayer == 1) ||
              ((y - selY).isNegative && currentPlayer == 0))) {
        showToast(currentPlayer, "A pawn can't move backward only forward");
        return;
      }
      if (selectedChess.shape == ChessShape.pawn &&
          yDiff == 2 &&
          xDiff == 0 &&
          selectedChess.moved) {
        showToast(currentPlayer,
            "A pawn can no longer take 2 steps after first movement");
        return;
      }
      // if (selectedChess.shape == ChessShape.pawn &&
      //     ((!(y - selY).isNegative && currentPlayer == 1) ||
      //         ((y - selY).isNegative && currentPlayer == 0) ||
      //         (yDiff == 2 &&
      //             xDiff == 0 &&
      //             ((selectedChess.y < 6 && currentPlayer == 1) ||
      //                 (selectedChess.y > 1 && currentPlayer == 0))) ||
      //         (xDiff == yDiff))) {
      //   return;
      // }
      bool hasEnpassant = false;

      for (int i = 1; i < count + 1; i++) {
        int pointX = 0;
        int pointY = 0;
        if (selectedChess.shape == ChessShape.pawn ||
            selectedChess.shape == ChessShape.knight ||
            selectedChess.shape == ChessShape.king) {
          pointX = x;
          pointY = y;
        } else {
          pointX = getX(direction, selX, i);
          pointY = getY(direction, selY, i);
        }

        final pointChessPos = convertToPosition([pointX, pointY], gridSize);
        final pointChessTile = chessTiles[pointChessPos];

        if (pointChessTile.chess != null) {
          if (selectedChess.shape == ChessShape.pawn &&
              ((yDiff <= 2 && xDiff == 0) ||
                  (xDiff == 1 &&
                      yDiff == 1 &&
                      ((!(y - selY).isNegative && currentPlayer == 1) ||
                          ((y - selY).isNegative && currentPlayer == 0))))) {
            return;
          }

          if (pointChessTile.chess!.player != currentPlayer) {
            foundChessPositions.add(pointChessPos);
          } else {
            return;
          }
        } else {
          if (selectedChess.shape == ChessShape.pawn &&
              xDiff == 1 &&
              yDiff == 1) {
            final pawnY = selectedChess.player == 1 ? pointY + 1 : pointY - 1;
            if (!exceedRange(pointX, pawnY)) {
              final pawnPos = convertToPosition([pointX, pawnY], gridSize);
              if (chessTiles[pawnPos].chess != null) {
                final pawnChess = chessTiles[pawnPos].chess!;
                if (pawnChess.shape == ChessShape.pawn &&
                    pawnChess.player != currentPlayer &&
                    pawnChess.moved &&
                    pawnPos == enpassantPos &&
                    (pawnChess.player == 0 && pawnChess.y == 3 ||
                        pawnChess.player == 1 && pawnChess.y == 4)) {
                  foundChessPositions.add(pawnPos);
                  hasEnpassant = true;
                  enpassantPos = -1;
                }
              }
            }
            if (xDiff == yDiff && foundChessPositions.isEmpty) {
              return;
            }
          }
        }
      }
      if (foundChessPositions.length > 1 ||
          (foundChessPositions.length == 1 &&
              chessTile.chess == null &&
              !hasEnpassant)) {
        return;
      }
      if (selectedChess.shape == ChessShape.king) {
        final check = checkForPossibleCheckForKing(pos);
        if (check) {
          showToast(
              currentPlayer, "You are going to be on check. Make another move");
          return;
        }
      } else {
        final pinned = checkForPinning(pos);
        if (pinned) {
          Fluttertoast.showToast(
              msg:
                  "This ${selectedChess.shape.name} is pinned due to king check, Make another move");
          return;
        }
      }

      if (checkingPos != -1) {
        final uncheck = checkForUncheck(pos);
        if (!uncheck) {
          if (foundChessPositions.isEmpty ||
              foundChessPositions.length != 1 ||
              foundChessPositions.first != checkingPos) {
            showToast(
                currentPlayer, "You are on check. Protect your king or block");
            return;
          } else {
            checkingPos = -1;
          }
        } else {
          checkingPos = -1;
        }
      }
      if (foundChessPositions.length == 1) {
        final foundPos = foundChessPositions.first;
        final chessTile = chessTiles[foundPos];
        final currentPlayerIndex = currentPlayer;
        final playerIndex = currentPlayerIndex == 1 ? 0 : 1;
        final playerChesses = playersChesses[playerIndex];
        final playerWonChesses = playersWonChesses[currentPlayerIndex];
        playerWonChesses.add(chessTile.chess!);
        playerChesses
            .removeWhere((element) => element.id == chessTile.chess!.id);

        chessTile.chess = null;
        drawMoveCount = 0;
        clearPattern();
      }
      if (selectedChessTile!.chess!.shape == ChessShape.pawn &&
          ((y == 0 && selectedChessTile!.chess!.player == 1) ||
              (y == gridSize - 1 && currentPlayer == 0))) {
        setState(() {
          pawnPositionChessTile = chessTile;
          choosePawnPromotion = true;
        });
        return;
      }

      selectedChessTile!.chess!.x = x;
      selectedChessTile!.chess!.y = y;
      if (!selectedChessTile!.chess!.moved) {
        selectedChessTile!.chess!.moved = true;
        if (selectedChessTile!.chess!.shape == ChessShape.pawn &&
            (selectedChessTile!.chess!.player == 0 &&
                    selectedChessTile!.chess!.y == 3 ||
                selectedChessTile!.chess!.player == 1 &&
                    selectedChessTile!.chess!.y == 4)) {
          enpassantPos = pos;
        } else {
          enpassantPos = -1;
        }
      }

      chessTile.chess = selectedChessTile!.chess;
      if (selectedChess.shape == ChessShape.king) {
        if (currentPlayer == 0) {
          player1KingPos = pos;
        } else if (currentPlayer == 1) {
          player2KingPos = pos;
        }
      }
      selectedChessTile!.chess = null;
      selectedChessTile = null;

      if (canCas && xDiff == 2 && yDiff == 0) {
        final rookX = direction == ChessDirection.right ? 7 : 0;
        final rookPos = convertToPosition([rookX, y], gridSize);
        final rookChess = chessTiles[rookPos].chess;
        if (rookChess != null) {
          final newRookX = direction == ChessDirection.right ? x - 1 : x + 1;
          final newRookPos = convertToPosition([newRookX, y], gridSize);
          rookChess.moved = true;
          chessTiles[newRookPos].chess = rookChess;
          chessTiles[rookPos].chess = null;
        }
      }
      final check = checkForCheck();
      if (check) {
        final checkMate = checkForCheckmate();
        if (checkMate) {
          message = "Checkmate";
          reason = "Checkmate";
          setState(() {});
          updateWingame(false);
        } else {
          message = "Check";
        }
      } else {
        message = "Your Turn";
      }
      if (foundChessPositions.isEmpty) {
        drawMoveCount++;
      }
      savePattern();
      checkWingame();
      changePlayer();
      hintPositions.clear();
      showPossiblePlayPositions();
      setState(() {});
    } else {
      String toastMessage = "";
      if (selectedChess.shape == ChessShape.pawn) {
        toastMessage =
            "Pawn: A Pawn moves 1 or 2 steps forward with 2 for first move and 1 for subsequent move and 1 step diagonal when about to capture";
      } else if (selectedChess.shape == ChessShape.rook) {
        toastMessage =
            "Rook: A Rook moves 1 or multiple steps edge to edge in top, bottom, left and right direction";
      } else if (selectedChess.shape == ChessShape.bishop) {
        toastMessage =
            "Bishop: A Bishop moves 1 or multiple steps diagonally in top left, top right, bottom left, bottom right direction";
      } else if (selectedChess.shape == ChessShape.knight) {
        toastMessage =
            "Knight: A Knight moves 1 step in one edge and 2 steps in the other edge in all directions";
      } else if (selectedChess.shape == ChessShape.king) {
        toastMessage = "King: A King moves 1 step in all directions";
      } else if (selectedChess.shape == ChessShape.queen) {
        toastMessage =
            "Queen: A Queen moves 1 or multiple steps in all directions";
      }
      showToast(currentPlayer, toastMessage);
    }
  }

  bool checkForCheckmate() {
    List<ChessDirection> directions = [
      ChessDirection.top,
      ChessDirection.right,
      ChessDirection.left,
      ChessDirection.bottom,
      ChessDirection.topLeft,
      ChessDirection.topRight,
      ChessDirection.bottomLeft,
      ChessDirection.bottomRight
    ];
    bool canMove = false;
    int nextPlayer = nextIndex(2, currentPlayer);
    int kingPos = nextPlayer == 0 ? player1KingPos : player2KingPos;
    final kingCoordinates = convertToGrid(kingPos, gridSize);
    final kingX = kingCoordinates[0];
    final kingY = kingCoordinates[1];
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      final x = getX(direction, kingX, 1);
      final y = getY(direction, kingY, 1);
      if (exceedRange(x, y)) continue;
      final chessPos = convertToPosition([x, y], gridSize);
      if ((chessTiles[chessPos].chess == null ||
          (chessTiles[chessPos].chess != null &&
              chessTiles[chessPos].chess!.player == currentPlayer))) {
        final checkPos = getCheckPosition(x, y, nextPlayer);
        if (!canMove) canMove = true;
        if (checkPos == -1) {
          return false;
        }
      }
    }
    return canMove;
  }

  bool checkForCheck() {
    int nextPlayer = nextIndex(2, currentPlayer);
    int kingPos = nextPlayer == 0 ? player1KingPos : player2KingPos;
    final kingCoordinates = convertToGrid(kingPos, gridSize);
    final kingX = kingCoordinates[0];
    final kingY = kingCoordinates[1];
    final checkPos = getCheckPosition(kingX, kingY, nextPlayer);
    if (checkPos != -1) {
      checkingPos = checkPos;
    }
    return checkPos != -1;
  }

  bool checkForUncheck(int pos) {
    if (checkingPos == -1 || selectedChessTile == null) return false;
    final checkingChess = chessTiles[checkingPos].chess!;
    int player = checkingChess.player;
    int kingPos = currentPlayer == 0 ? player1KingPos : player2KingPos;

    final kingCoordinates = convertToGrid(kingPos, gridSize);
    final kingX = kingCoordinates[0];
    final kingY = kingCoordinates[1];

    final coordinates = convertToGrid(checkingPos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];

    final xDiff = (x - kingX).abs();
    final yDiff = (y - kingY).abs();

    List<ChessDirection> directions = [];
    ChessDirection direction = ChessDirection.noDirection;
    if (checkingChess.shape == ChessShape.pawn ||
        checkingChess.shape == ChessShape.bishop) {
      directions = diagonalDirections;
      direction = getDiagonalDirection(kingX - x, kingY - y);
    } else if (checkingChess.shape == ChessShape.knight) {
      directions = knightDirections;
      direction = getKnightDirection(kingX - x, kingY - y);
    } else if (checkingChess.shape == ChessShape.rook) {
      directions = edgeDirections;
      direction = getEdgeDirection(kingX - x, kingY - y);
    } else if (checkingChess.shape == ChessShape.king ||
        checkingChess.shape == ChessShape.queen) {
      directions.addAll(edgeDirections);
      directions.addAll(diagonalDirections);
      direction = getDiagonalAndEdgeDirection(kingX - x, kingY - y);
    }
    if (direction == ChessDirection.noDirection) return false;

    // final count = (checkingChess.shape == ChessShape.pawn ||
    //         checkingChess.shape == ChessShape.knight ||
    //         checkingChess.shape == ChessShape.king)
    //     ? 1
    //     : xDiff > yDiff
    //         ? xDiff
    //         : yDiff;

    List<int> kingPositions = [];
    List<int> otherPiecesPositions = [];
    bool found = false;
    for (int i = 0; i < 8; i++) {
      if (exceedRange(getChessX(direction, x, i), getChessY(direction, y, i))) {
        break;
      }
      int pointX = getChessX(direction, x, i);
      int pointY = getChessY(direction, y, i);
      final pointChessPos = convertToPosition([pointX, pointY], gridSize);
      kingPositions.add(pointChessPos);
      final chess = chessTiles[pointChessPos].chess;
      if (found && chess != null) {
        break;
      }
      if (!found && pointX == kingX && pointY == kingY) {
        found = true;
      }
      if (!found) {
        otherPiecesPositions.add(pointChessPos);
      }
    }
    final selectedChess = selectedChessTile!.chess!;
    if ((selectedChess.shape == ChessShape.king &&
            (!kingPositions.contains(pos))) ||
        selectedChess.shape != ChessShape.king &&
            (otherPiecesPositions.contains(pos))) {
      return true;
    }
    return false;
  }

  int getCheckPosition(int x, int y, int checkingPlayer) {
    for (int i = 0; i < allDirections.length; i++) {
      final direction = allDirections[i];
      //final count = isKnightDirection(direction) ? 2 : 8;
      int searchCount = 0;
      for (int j = 1; j < 8; j++) {
        if (exceedRange(
            getChessX(direction, x, j), getChessY(direction, y, j))) {
          break;
        }
        int pointX = getChessX(direction, x, j);
        int pointY = getChessY(direction, y, j);
        final pointChessPos = convertToPosition([pointX, pointY], gridSize);
        final pointChessTile = chessTiles[pointChessPos];
        if (pointChessTile.chess != null) {
          final pointChess = pointChessTile.chess!;
          final player = pointChess.player;
          final shape = pointChess.shape;
          if (player == checkingPlayer) break;
          if ((edgeDirections.contains(direction) &&
                  ((shape == ChessShape.king && searchCount == 0) ||
                      shape == ChessShape.queen ||
                      shape == ChessShape.rook)) ||
              (diagonalDirections.contains(direction) &&
                  (((shape == ChessShape.king ||
                              (shape == ChessShape.pawn &&
                                  ((player == 1 &&
                                          (direction ==
                                                  ChessDirection.bottomRight ||
                                              direction ==
                                                  ChessDirection.bottomLeft) ||
                                      (player == 0 &&
                                          (direction ==
                                                  ChessDirection.topRight ||
                                              direction ==
                                                  ChessDirection
                                                      .topLeft)))))) &&
                          searchCount == 0) ||
                      shape == ChessShape.queen ||
                      shape == ChessShape.bishop)) ||
              (knightDirections.contains(direction) &&
                  shape == ChessShape.knight &&
                  searchCount == 0)) {
            return pointChessPos;
          } else {
            break;
          }
        } else {
          searchCount++;
        }
      }
    }
    return -1;
  }

  // bool canEscapeCapturing(int x, int y) {
  //   int captureCount = 0;
  //   final nextPlayer = nextIndex(2, currentPlayer);
  //   for (int i = 0; i < allDirections.length; i++) {
  //     final direction = allDirections[i];
  //     final count = isKnightDirection(direction) ? 2 : 8;
  //     int searchCount = 0;
  //     for (int j = 1; j < count; j++) {
  //       if (exceedRange(
  //           getChessX(direction, x, j), getChessY(direction, y, j))) {
  //         break;
  //       }
  //       int pointX = getChessX(direction, x, j);
  //       int pointY = getChessY(direction, y, j);
  //       final pointChessPos = convertToPosition([pointX, pointY], gridSize);
  //       final pointChessTile = chessTiles[pointChessPos];
  //       if (pointChessTile.chess != null) {
  //         final pointChess = pointChessTile.chess!;
  //         final player = pointChess.player;
  //         final shape = pointChess.shape;
  //         if (player == nextPlayer) {
  //           break;
  //         }
  //         if ((edgeDirections.contains(direction) &&
  //                 ((shape == ChessShape.king && searchCount == 0) ||
  //                     shape == ChessShape.queen ||
  //                     shape == ChessShape.rook)) ||
  //             (diagonalDirections.contains(direction) &&
  //                 (((shape == ChessShape.king ||
  //                             (shape == ChessShape.pawn &&
  //                                 ((player == 1 &&
  //                                         (direction ==
  //                                                 ChessDirection.bottomRight ||
  //                                             direction ==
  //                                                 ChessDirection.bottomLeft) ||
  //                                     (player == 0 &&
  //                                         (direction ==
  //                                                 ChessDirection.topRight ||
  //                                             direction ==
  //                                                 ChessDirection
  //                                                     .topLeft)))))) &&
  //                         searchCount == 0) ||
  //                     shape == ChessShape.queen ||
  //                     shape == ChessShape.bishop)) ||
  //             (knightDirections.contains(direction) &&
  //                 shape == ChessShape.knight)) {
  //           captureCount++;
  //         }
  //         break;
  //       } else {
  //         searchCount++;
  //       }
  //     }
  //   }
  //   return captureCount == 0;
  // }

  bool checkForPossibleCheckForKing(int pos) {
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    if (chessTiles[pos].chess == null ||
        (chessTiles[pos].chess != null &&
            chessTiles[pos].chess!.player != currentPlayer)) {
      final checkPos = getCheckPosition(x, y, currentPlayer);
      return checkPos != -1;
    }

    return false;
  }

  bool checkForPinning(int pos) {
    if (selectedChessTile == null) return false;
    final chessTile = chessTiles[pos];
    final newX = chessTile.x;
    final newY = chessTile.y;

    final selectedChess = selectedChessTile!.chess!;
    final x = selectedChess.x;
    final y = selectedChess.y;
    bool foundPlayer = false;

    int kingPos = currentPlayer == 0 ? player1KingPos : player2KingPos;
    final kingCoordinates = convertToGrid(kingPos, gridSize);
    final kingX = kingCoordinates[0];
    final kingY = kingCoordinates[1];
    ChessDirection direction =
        getChessDirection(x - kingX, y - kingY, selectedChess.shape);
    if (direction == ChessDirection.noDirection) return false;
    ChessDirection otherDirection =
        getChessDirection(kingX - x, kingY - y, selectedChess.shape);
    ChessDirection playerDirection =
        getChessDirection(newX - x, newY - y, selectedChess.shape);

    if (direction == ChessDirection.noDirection) return false;
    int searchCount = 0;
    for (int j = 1; j < 8; j++) {
      if (exceedRange(
          getChessX(direction, kingX, j), getChessY(direction, kingY, j))) {
        break;
      }
      int pointX = getChessX(direction, kingX, j);
      int pointY = getChessY(direction, kingY, j);
      final pointChessPos = convertToPosition([pointX, pointY], gridSize);
      final pointChessTile = chessTiles[pointChessPos];
      if (pointChessTile.chess != null) {
        final pointChess = pointChessTile.chess!;
        final player = pointChess.player;
        final shape = pointChess.shape;
        if (foundPlayer) {
          if (player == currentPlayer) return false;
          if ((edgeDirections.contains(direction) &&
                  ((shape == ChessShape.king && searchCount == 0) ||
                      shape == ChessShape.queen ||
                      shape == ChessShape.rook)) ||
              (diagonalDirections.contains(direction) &&
                  (((shape == ChessShape.king ||
                              (shape == ChessShape.pawn &&
                                  ((player == 1 &&
                                          (direction ==
                                                  ChessDirection.bottomRight ||
                                              direction ==
                                                  ChessDirection.bottomLeft) ||
                                      (player == 0 &&
                                          (direction ==
                                                  ChessDirection.topRight ||
                                              direction ==
                                                  ChessDirection
                                                      .topLeft)))))) &&
                          searchCount == 0) ||
                      shape == ChessShape.queen ||
                      shape == ChessShape.bishop)) ||
              (knightDirections.contains(direction) &&
                  shape == ChessShape.knight &&
                  searchCount == 0)) {
            return playerDirection != direction &&
                playerDirection != otherDirection;
          } else {
            return false;
          }
        } else {
          if (player == currentPlayer && pointChess == selectedChess) {
            foundPlayer = true;
          } else {
            return false;
          }
        }
      } else {
        searchCount++;
        // if (foundPlayer) {

        // }
      }
    }
    return false;
  }

  void getHintPositions(int pos) {
    //if (!firstTime) return;
    hintPositions.clear();
    final chess = chessTiles[pos].chess!;
    final coordinates = convertToGrid(pos, gridSize);
    final x = coordinates[0];
    final y = coordinates[1];
    List<ChessDirection> directions = [];

    if (chess.shape == ChessShape.pawn) {
      if (currentPlayer == 0) {
        directions = [
          ChessDirection.bottomLeft,
          ChessDirection.bottomRight,
          ChessDirection.bottom
        ];
      } else {
        directions = [
          ChessDirection.topLeft,
          ChessDirection.topRight,
          ChessDirection.top
        ];
      }
    } else if (chess.shape == ChessShape.bishop) {
      directions = diagonalDirections;
    } else if (chess.shape == ChessShape.knight) {
      directions = knightDirections;
    } else if (chess.shape == ChessShape.rook) {
      directions = edgeDirections;
    } else if (chess.shape == ChessShape.king ||
        chess.shape == ChessShape.queen) {
      directions.addAll(edgeDirections);
      directions.addAll(diagonalDirections);
    }
    final end =
        (chess.shape == ChessShape.knight || chess.shape == ChessShape.king)
            ? 2
            : chess.shape == ChessShape.pawn
                ? 3
                : 8;
    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      bool canCas = false;
      if (chess.shape == ChessShape.king) {
        canCas = canCastle(direction);
      }
      int count = canCas ? end + 1 : end;
      int emptySpacesCount = 0;
      bool hasEnpassantPos = false;
      for (int j = 1; j < count; j++) {
        final newX = getChessX(direction, x, j);
        final newY = getChessY(direction, y, j);
        if (exceedRange(newX, newY)) break;
        final pos = convertToPosition([newX, newY], gridSize);
        if (chess.shape == ChessShape.king) {
          final check = checkForPossibleCheckForKing(pos);
          if (check) {
            break;
          }
        } else {
          final pinned = checkForPinning(pos);
          if (pinned) {
            break;
          }
        }
        if (checkingPos != -1) {
          final uncheck = checkForUncheck(pos);
          if (!uncheck) {
            break;
          }
        }
        final chessTile = chessTiles[pos];
        if (chessTile.chess != null) {
          emptySpacesCount = 0;
          if (chessTile.chess!.player != currentPlayer) {
            if (chess.shape != ChessShape.pawn ||
                (direction == ChessDirection.bottomLeft ||
                    direction == ChessDirection.bottomRight ||
                    direction == ChessDirection.topLeft ||
                    direction == ChessDirection.topRight)) {
              hintPositions.add(pos);
            }
          }
          break;
        } else {
          emptySpacesCount++;
          if (chess.shape == ChessShape.pawn) {
            final pawnY = chess.player == 1 ? newY + 1 : newY - 1;
            if (!exceedRange(newX, pawnY)) {
              final pawnPos = convertToPosition([newX, pawnY], gridSize);
              if (chessTiles[pawnPos].chess != null) {
                final pawnChess = chessTiles[pawnPos].chess!;
                if (pawnChess.shape == ChessShape.pawn &&
                    pawnChess.player != currentPlayer &&
                    pawnChess.moved &&
                    enpassantPos == pawnPos &&
                    (pawnChess.player == 0 && pawnChess.y == 3 ||
                        pawnChess.player == 1 && pawnChess.y == 4)) {
                  // hintPositions.add(pawnPos);
                  hasEnpassantPos = true;
                }
              }
            }
          }
          if (chess.shape == ChessShape.pawn) {
            if (direction != ChessDirection.bottom &&
                direction != ChessDirection.top &&
                !hasEnpassantPos) {
              break;
            }
            int limit = ((chess.y < 6 && currentPlayer == 1) ||
                    (chess.y > 1 && currentPlayer == 0))
                ? 1
                : 2;
            if (emptySpacesCount > limit) {
              break;
            }
          }
          hintPositions.add(pos);
          if (hasEnpassantPos) break;
        }
      }
    }
    // getHintMessage(false, chess.shape);
    setState(() {});
  }

  void getHintMessage(bool played, [ChessShape chessShape = ChessShape.pawn]) {
    if (!firstTime) return;

    if (played) {
      hintMessage =
          "Tap on ${currentPlayer == 0 ? "Black" : "White"} piece to make your move";
    } else {
      if (chessShape == ChessShape.pawn) {
        hintMessage =
            "Pawn: A Pawn moves 1 or 2 steps forward with 2 for first move and 1 for subsequent move and 1 step diagonal when about to capture";
      } else if (chessShape == ChessShape.rook) {
        hintMessage =
            "Rook: A Rook moves 1 or multiple steps edge to edge in top, bottom, left and right direction";
      } else if (chessShape == ChessShape.bishop) {
        hintMessage =
            "Bishop: A Bishop moves 1 or multiple steps diagonally in top left, top right, bottom left, bottom right direction";
      } else if (chessShape == ChessShape.knight) {
        hintMessage =
            "Knight: A Knight moves 1 step in one edge and 2 steps in the other edge in all directions";
      } else if (chessShape == ChessShape.king) {
        hintMessage = "King: A King moves 1 step in all directions";
      } else if (chessShape == ChessShape.queen) {
        hintMessage =
            "Queen: A Queen moves 1 or multiple steps in all directions";
      }
    }
    message = hintMessage;
    setState(() {});
  }

  void checkFirstime() async {
    sharedPref = await SharedPreferences.getInstance();
    int playTimes = sharedPref!.getInt(playedChessGame) ?? 0;
    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref!.setInt(playedChessGame, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  bool canMove(int x, int y) {
    if (exceedRange(x, y)) return false;
    final pos = convertToPosition([x, y], gridSize);
    final chessTile = chessTiles[pos];
    if (chessTile.chess == null) return false;
    final chess = chessTile.chess!;
    int player = chessTile.chess!.player;
    List<ChessDirection> directions = [];
    if (chess.shape == ChessShape.pawn) {
      if (player == 0) {
        directions = [
          ChessDirection.bottomLeft,
          ChessDirection.bottomRight,
          ChessDirection.bottom
        ];
      } else {
        directions = [
          ChessDirection.topLeft,
          ChessDirection.topRight,
          ChessDirection.top
        ];
      }
    } else if (chess.shape == ChessShape.bishop) {
      directions = diagonalDirections;
    } else if (chess.shape == ChessShape.knight) {
      directions = knightDirections;
    } else if (chess.shape == ChessShape.rook) {
      directions = edgeDirections;
    } else if (chess.shape == ChessShape.king ||
        chess.shape == ChessShape.queen) {
      directions.addAll(edgeDirections);
      directions.addAll(diagonalDirections);
    }

    for (int i = 0; i < directions.length; i++) {
      final direction = directions[i];
      final newX = getX(direction, x, 1);
      final newY = getY(direction, y, 1);
      if (exceedRange(newX, newY)) continue;
      final pos = convertToPosition([newX, newY], gridSize);
      final chessTile = chessTiles[pos];
      if (chessTile.chess == null) return true;
      if (chessTile.chess!.player != player) {
        if (chessTile.chess!.shape == ChessShape.pawn &&
            (direction == ChessDirection.bottom ||
                direction == ChessDirection.top)) {
          continue;
        } else {
          return true;
        }
      }
    }
    return false;
  }

  String getPattern(int player, List<Chess> chesses) {
    String pattern = "";
    for (int i = 0; i < chesses.length; i++) {
      final chess = chesses[i];
      final x = chess.x;
      final y = chess.y;
      pattern += "$player$x$y, ";
    }
    return pattern;
  }

  void savePattern() {
    String pattern = "";
    pattern += getPattern(0, playersChesses[0]);
    pattern += getPattern(1, playersChesses[1]);
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
    final player1Chesses = playersChesses[0];
    final player2Chesses = playersChesses[0];
    if ((player1Chesses.length == 1 &&
            player1Chesses.first.shape == ChessShape.king) &&
        (player2Chesses.length == 1 &&
            player2Chesses.first.shape == ChessShape.king)) {
      reason = "1 king to 1 king";
      updateDrawgame();
      return;
    }
    if ((player1Chesses.length == 2 &&
            player2Chesses.length == 1 &&
            player1Chesses
                .where((element) => element.shape == ChessShape.king)
                .isNotEmpty &&
            player1Chesses
                .where((element) =>
                    element.shape == ChessShape.knight ||
                    element.shape == ChessShape.bishop)
                .isNotEmpty) &&
        player2Chesses.first.shape == ChessShape.king) {
      final secondPiece =
          player1Chesses.where((element) => element.shape != ChessShape.king);
      reason = "1 king to 1 king and 1 ${secondPiece.first.shape.name}";
      updateDrawgame();
      return;
    }
    if ((player2Chesses.length == 2 &&
            player1Chesses.length == 1 &&
            player2Chesses
                .where((element) => element.shape == ChessShape.king)
                .isNotEmpty &&
            player2Chesses
                .where((element) =>
                    element.shape == ChessShape.knight ||
                    element.shape == ChessShape.bishop)
                .isNotEmpty) &&
        player1Chesses.first.shape == ChessShape.king) {
      final secondPiece =
          player2Chesses.where((element) => element.shape != ChessShape.king);
      reason = "1 king to 1 king and 1 ${secondPiece.first.shape.name}";
      updateDrawgame();
      return;
    }
    if (drawMoveCount == maxDrawMoveCount) {
      reason = "50 moves without capturing";
      updateDrawgame();
    }
  }

  void checkIfCanMove() {
    final next = nextIndex(2, currentPlayer);
    final chesses = playersChesses[next];
    int moveCount = 0;
    if (chesses.isNotEmpty) {
      for (int i = 0; i < chesses.length; i++) {
        final chess = chesses[i];
        final x = chess.x;
        final y = chess.y;

        if (canMove(x, y)) {
          moveCount++;
        }
      }
      if (moveCount == 0) {
        message = "Stalemate";
        reason = "Stalemate";
        updateDrawgame();
      }
    }
  }

  void updateDrawgame() {
    won = false;
    pauseGame();
    drawMoveCount = 0;
    roundsCount++;
    pausePlayerTime = true;
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
    updateMatchRecord();
    roundsCount++;
    player1Time = maxChessDraughtTime;
    player2Time = maxChessDraughtTime;
    pausePlayerTime = true;
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
    final playerChesses = playersChesses[nextIndex(2, currentPlayer)];
    if (playerChesses.isEmpty) {
      updateWingame(false);
    }
  }

  void changePlayer() {
    checkForDraw();
    checkIfCanMove();
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

  bool isDown(ChessDirection direction) {
    return direction == ChessDirection.bottomLeft ||
        direction == ChessDirection.bottomRight ||
        direction == ChessDirection.bottom;
  }

  ChessDirection getKnightDirection(int x, int y) {
    ChessDirection direction = ChessDirection.noDirection;
    if (x == -1 && y == -2) {
      direction = ChessDirection.topTopLeft;
    } else if (x == 1 && y == -2) {
      direction = ChessDirection.topTopRight;
    } else if (x == -1 && y == 2) {
      direction = ChessDirection.bottomBottomLeft;
    } else if (x == 1 && y == 2) {
      direction = ChessDirection.bottomBottomRight;
    } else if (x == -2 && y == -1) {
      direction = ChessDirection.topLeftLeft;
    } else if (x == 2 && y == -1) {
      direction = ChessDirection.topRightRight;
    } else if (x == -2 && y == 1) {
      direction = ChessDirection.bottomLeftLeft;
    } else if (x == 2 && y == 1) {
      direction = ChessDirection.bottomRightRight;
    }
    return direction;
  }

  ChessDirection getDiagonalDirection(int x, int y) {
    ChessDirection direction = ChessDirection.noDirection;
    if (x < 0 && y < 0) {
      direction = ChessDirection.topLeft;
    } else if (x > 0 && y > 0) {
      direction = ChessDirection.bottomRight;
    } else if (x < 0 && y > 0) {
      direction = ChessDirection.bottomLeft;
    } else if (x > 0 && y < 0) {
      direction = ChessDirection.topRight;
    }
    return direction;
  }

  ChessDirection getEdgeDirection(int x, int y) {
    ChessDirection direction = ChessDirection.noDirection;
    if (x == 0 && y < 0) {
      direction = ChessDirection.top;
    } else if (x == 0 && y > 0) {
      direction = ChessDirection.bottom;
    } else if (x < 0 && y == 0) {
      direction = ChessDirection.left;
    } else if (x > 0 && y == 0) {
      direction = ChessDirection.right;
    }
    return direction;
  }

  ChessDirection getDiagonalAndEdgeDirection(int x, int y) {
    ChessDirection direction = ChessDirection.noDirection;
    if (x < 0 && y < 0) {
      direction = ChessDirection.topLeft;
    } else if (x > 0 && y > 0) {
      direction = ChessDirection.bottomRight;
    } else if (x < 0 && y > 0) {
      direction = ChessDirection.bottomLeft;
    } else if (x > 0 && y < 0) {
      direction = ChessDirection.topRight;
    } else if (x == 0 && y < 0) {
      direction = ChessDirection.top;
    } else if (x == 0 && y > 0) {
      direction = ChessDirection.bottom;
    } else if (x < 0 && y == 0) {
      direction = ChessDirection.left;
    } else if (x > 0 && y == 0) {
      direction = ChessDirection.right;
    }
    return direction;
  }

  ChessDirection getChessDirection(int x, int y, ChessShape shape) {
    ChessDirection direction = ChessDirection.noDirection;
    if (x == -1 && y == -2 && shape == ChessShape.knight) {
      direction = ChessDirection.topTopLeft;
    } else if (x == 1 && y == -2 && shape == ChessShape.knight) {
      direction = ChessDirection.topTopRight;
    } else if (x == -1 && y == 2 && shape == ChessShape.knight) {
      direction = ChessDirection.bottomBottomLeft;
    } else if (x == 1 && y == 2 && shape == ChessShape.knight) {
      direction = ChessDirection.bottomBottomRight;
    } else if (x == -2 && y == -1 && shape == ChessShape.knight) {
      direction = ChessDirection.topLeftLeft;
    } else if (x == 2 && y == -1 && shape == ChessShape.knight) {
      direction = ChessDirection.topRightRight;
    } else if (x == -2 && y == 1 && shape == ChessShape.knight) {
      direction = ChessDirection.bottomLeftLeft;
    } else if (x == 2 && y == 1 && shape == ChessShape.knight) {
      direction = ChessDirection.bottomRightRight;
    } else if (x < 0 && y < 0 && (x.abs() == y.abs())) {
      direction = ChessDirection.topLeft;
    } else if (x > 0 && y > 0 && (x.abs() == y.abs())) {
      direction = ChessDirection.bottomRight;
    } else if (x < 0 && y > 0 && (x.abs() == y.abs())) {
      direction = ChessDirection.bottomLeft;
    } else if (x > 0 && y < 0 && (x.abs() == y.abs())) {
      direction = ChessDirection.topRight;
    } else if (x == 0 && y < 0) {
      direction = ChessDirection.top;
    } else if (x == 0 && y > 0) {
      direction = ChessDirection.bottom;
    } else if (x < 0 && y == 0) {
      direction = ChessDirection.left;
    } else if (x > 0 && y == 0) {
      direction = ChessDirection.right;
    }
    return direction;
  }

  bool isKnightDirection(ChessDirection direction) {
    return (direction == ChessDirection.topTopRight ||
        direction == ChessDirection.bottomBottomRight ||
        direction == ChessDirection.topRightRight ||
        direction == ChessDirection.bottomRightRight ||
        direction == ChessDirection.topTopLeft ||
        direction == ChessDirection.bottomBottomLeft ||
        direction == ChessDirection.topLeftLeft ||
        direction == ChessDirection.bottomLeftLeft);
  }

  int getKnightX(KnightChessDirection direction, int x) {
    int newX = 0;
    int step = 0;
    if (direction == KnightChessDirection.topRightRight ||
        direction == KnightChessDirection.bottomRightRight ||
        direction == KnightChessDirection.topLeftLeft ||
        direction == KnightChessDirection.bottomLeftLeft) {
      step = 2;
    } else {
      step = 1;
    }
    if (direction == KnightChessDirection.topTopRight ||
        direction == KnightChessDirection.bottomBottomRight ||
        direction == KnightChessDirection.topRightRight ||
        direction == KnightChessDirection.bottomRightRight) {
      newX = x + step;
    } else if (direction == KnightChessDirection.topTopLeft ||
        direction == KnightChessDirection.bottomBottomLeft ||
        direction == KnightChessDirection.topLeftLeft ||
        direction == KnightChessDirection.bottomLeftLeft) {
      newX = x - step;
    }
    return newX;
  }

  int getKnightY(KnightChessDirection direction, int y) {
    int newY = 0;
    int step = 0;
    if (direction == KnightChessDirection.topTopRight ||
        direction == KnightChessDirection.bottomBottomRight ||
        direction == KnightChessDirection.topTopLeft ||
        direction == KnightChessDirection.bottomBottomLeft) {
      step = 2;
    } else {
      step = 1;
    }
    if (direction == KnightChessDirection.bottomBottomRight ||
        direction == KnightChessDirection.bottomRightRight ||
        direction == KnightChessDirection.bottomBottomLeft ||
        direction == KnightChessDirection.bottomLeftLeft) {
      newY = y + step;
    } else if (direction == KnightChessDirection.topTopRight ||
        direction == KnightChessDirection.topRightRight ||
        direction == KnightChessDirection.topTopLeft ||
        direction == KnightChessDirection.topLeftLeft) {
      newY = y - step;
    }
    return newY;
  }

  int getChessX(ChessDirection direction, int x, int step) {
    int newX = x;
    int knightStep = 0;
    if (direction == ChessDirection.topRightRight ||
        direction == ChessDirection.bottomRightRight ||
        direction == ChessDirection.topLeftLeft ||
        direction == ChessDirection.bottomLeftLeft) {
      knightStep = 2;
    } else {
      knightStep = 1;
    }
    if (direction == ChessDirection.topTopRight ||
        direction == ChessDirection.bottomBottomRight ||
        direction == ChessDirection.topRightRight ||
        direction == ChessDirection.bottomRightRight) {
      newX = x + knightStep;
    } else if (direction == ChessDirection.topTopLeft ||
        direction == ChessDirection.bottomBottomLeft ||
        direction == ChessDirection.topLeftLeft ||
        direction == ChessDirection.bottomLeftLeft) {
      newX = x - knightStep;
    } else if (direction == ChessDirection.topRight ||
        direction == ChessDirection.bottomRight ||
        direction == ChessDirection.right) {
      newX = x + step;
    } else if (direction == ChessDirection.topLeft ||
        direction == ChessDirection.bottomLeft ||
        direction == ChessDirection.left) {
      newX = x - step;
    }
    return newX;
  }

  int getChessY(ChessDirection direction, int y, int step) {
    int newY = y;
    int knightStep = 0;
    if (direction == ChessDirection.topTopRight ||
        direction == ChessDirection.bottomBottomRight ||
        direction == ChessDirection.topTopLeft ||
        direction == ChessDirection.bottomBottomLeft) {
      knightStep = 2;
    } else {
      knightStep = 1;
    }
    if (direction == ChessDirection.bottomBottomRight ||
        direction == ChessDirection.bottomRightRight ||
        direction == ChessDirection.bottomBottomLeft ||
        direction == ChessDirection.bottomLeftLeft) {
      newY = y + knightStep;
    } else if (direction == ChessDirection.topTopRight ||
        direction == ChessDirection.topRightRight ||
        direction == ChessDirection.topTopLeft ||
        direction == ChessDirection.topLeftLeft) {
      newY = y - knightStep;
    } else if (direction == ChessDirection.bottomRight ||
        direction == ChessDirection.bottomLeft ||
        direction == ChessDirection.bottom) {
      newY = y + step;
    } else if (direction == ChessDirection.topRight ||
        direction == ChessDirection.topLeft ||
        direction == ChessDirection.top) {
      newY = y - step;
    }
    return newY;
  }

  int getX(ChessDirection direction, int x, int step) {
    int newX = x;

    if (direction == ChessDirection.topRight ||
        direction == ChessDirection.bottomRight ||
        direction == ChessDirection.right) {
      newX = x + step;
    } else if (direction == ChessDirection.topLeft ||
        direction == ChessDirection.bottomLeft ||
        direction == ChessDirection.left) {
      newX = x - step;
    }
    return newX;
  }

  int getY(ChessDirection direction, int y, int step) {
    int newY = y;
    if (direction == ChessDirection.bottomRight ||
        direction == ChessDirection.bottomLeft ||
        direction == ChessDirection.bottom) {
      newY = y + step;
    } else if (direction == ChessDirection.topRight ||
        direction == ChessDirection.topLeft ||
        direction == ChessDirection.top) {
      newY = y - step;
    }
    return newY;
  }

  bool exceedRange(int x, int y) =>
      x > gridSize - 1 || x < 0 || y > gridSize - 1 || y < 0;

  List<int> convertToGrid(int pos, int gridSize) {
    return [pos % gridSize, pos ~/ gridSize];
  }

  int convertToPosition(List<int> grids, int gridSize) {
    return grids[0] + (grids[1] * gridSize);
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
                          children: [
                            if (landScape) ...[
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 2,
                                  child: CustomGrid(
                                      height: wonChessSize * 2,
                                      width: padding,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      items: playersWonChesses[wonPiecesIndex],
                                      gridSize: gridSize,
                                      itemBuilder: (pindex) {
                                        final chesses =
                                            playersWonChesses[wonPiecesIndex];
                                        final chess = chesses[pindex];
                                        return Container(
                                          height: wonChessSize,
                                          width: wonChessSize,
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
                                                          chesses.length <=
                                                              8) ||
                                                      pindex == 8
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                              topRight: pindex == 7 ||
                                                      (pindex ==
                                                              chesses.length -
                                                                  1 &&
                                                          chesses.length <= 8)
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                              bottomRight: pindex ==
                                                          chesses.length - 1 ||
                                                      pindex == 7
                                                  ? const Radius.circular(10)
                                                  : Radius.zero,
                                            ),
                                          ),
                                          child: SvgPicture.asset(
                                            getAsset(chess.shape),
                                            width:
                                                wonChessSize.percentValue(75),
                                            height:
                                                wonChessSize.percentValue(75),
                                            color: chess.color == 1
                                                ? Colors.white
                                                : Colors.black,
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
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!landScape) ...[
                                        CustomGrid(
                                            height: wonChessSize * 2,
                                            width: padding,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            items: playersWonChesses[index],
                                            gridSize: gridSize,
                                            itemBuilder: (pindex) {
                                              final chesses =
                                                  playersWonChesses[index];
                                              final chess = chesses[pindex];
                                              return Container(
                                                height: wonChessSize,
                                                width: wonChessSize,
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
                                                                chesses.length <=
                                                                    8) ||
                                                            pindex == 8
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                    topRight: pindex == 7 ||
                                                            (pindex ==
                                                                    chesses.length -
                                                                        1 &&
                                                                chesses.length <=
                                                                    8)
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                    bottomRight: pindex ==
                                                                chesses.length -
                                                                    1 ||
                                                            pindex == 7
                                                        ? const Radius.circular(
                                                            10)
                                                        : Radius.zero,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: SvgPicture.asset(
                                                  getAsset(chess.shape),
                                                  width: wonChessSize
                                                      .percentValue(75),
                                                  height: wonChessSize
                                                      .percentValue(75),
                                                  color: chess.color == 1
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              );
                                            }),
                                      ],
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
                    child: Container(
                      color: Colors.white,
                      child: GridView(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridSize),
                          children: List.generate(gridSize * gridSize, (index) {
                            final coordinates = convertToGrid(index, gridSize);
                            final x = coordinates[0];
                            final y = coordinates[1];
                            final chessTile = chessTiles[index];
                            return ChessTileWidget(
                                blink: hintPositions.contains(index) &&
                                    !finishedRound,
                                gameId: gameId,
                                key: Key(chessTile.id),
                                x: x,
                                y: y,
                                chessTile: chessTile,
                                highLight: chessTile == selectedChessTile,
                                onPressed: () {
                                  if (gameId != "" && currentPlayerId != myId) {
                                    showToast(1,
                                        "Its ${getUsername(currentPlayerId)}'s turn");
                                    return;
                                  }
                                  if (choosePawnPromotion) {
                                    showToast(currentPlayer, "Select piece");
                                    return;
                                  }
                                  if (gameId != "") {
                                    updateDetails(index);
                                  } else {
                                    playChess(index);
                                  }
                                },
                                size: size);
                          })),
                    ))),
            if (choosePawnPromotion) ...[
              Positioned(
                  top: currentPlayer == 1
                      ? landScape
                          ? 0
                          : padding - 10 - size
                      : null,
                  bottom: currentPlayer == 0
                      ? landScape
                          ? 0
                          : padding - 10 - size
                      : null,
                  left: pawnPositionChessTile!.x < 4
                      ? landScape
                          ? padding - 10 - size
                          : 0
                      : null,
                  right: pawnPositionChessTile!.x >= 4
                      ? landScape
                          ? padding - 10 - size
                          : 0
                      : null,
                  child: Container(
                    height: size,
                    width: size * 4,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5)),
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: List.generate(4, (index) {
                          return GestureDetector(
                            onTap: () {
                              if (gameId != "" && currentPlayerId != myId) {
                                showToast(1,
                                    "Its ${getUsername(currentPlayerId)}'s turn");
                                return;
                              }
                              if (gameId != "") {
                                updatePawnPromotionDetails(index);
                              } else {
                                updateChessPromotion(index);
                              }
                            },
                            child: Container(
                              height: size,
                              width: size,
                              alignment: Alignment.center,
                              child: RotatedBox(
                                quarterTurns: currentPlayer == 0 ? 2 : 0,
                                child: SvgPicture.asset(
                                  getAsset(chessShapes[index]),
                                  width: size / 2,
                                  height: size / 2,
                                  color: currentPlayer == 1
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        })),
                  ))
            ],
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
                        "Tap on any chess piece\nMake your move",
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
                  game: "Chess",
                  playersScores: playersScores,
                  users: users,
                  playersSize: 2,
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
