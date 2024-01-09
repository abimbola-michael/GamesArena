// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:gamesarena/components/circle_progress_bar.dart';
import 'package:gamesarena/components/games/ludo_tile.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:riverpod/riverpod.dart';

import '../../blocs/firebase_service.dart';
import '../../components/blinking_border_container.dart';
import '../../components/game_timer.dart';
import '../../components/custom_toast.dart';
import '../../components/games/ludo_dice.dart';
import '../../custom_paint/ludo_triangle_paint.dart';
import '../../models/games/ludo.dart';
import '../../models/models.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../paused_game_page.dart';
import '../tabs/games_page.dart';

class LudoGamePage extends StatefulWidget {
  final String? matchId;
  final String? gameId;
  final List<User?>? users;
  final int? playersSize;
  final String? indices;
  final int? id;

  const LudoGamePage({
    super.key,
    this.matchId,
    this.gameId,
    this.users,
    this.playersSize,
    this.indices,
    this.id,
  });

  @override
  State<LudoGamePage> createState() => _LudoGamePageState();
}

class _LudoGamePageState extends State<LudoGamePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool played = false;
  LudoDetails? prevDetails;
  double gridLength = 0, houseLength = 0, cellSize = 0;
  bool started = false;
  bool sixsix = false;
  int playersSize = 2;

  LudoTile? selectedLudoTile;
  Ludo? selectedLudo;
  List<LudoColor> colors = [];
  List<List<Ludo>> ludos = [], activeLudos = [];
  List<List<Ludo>> playersWonLudos = [];
  List<List<LudoTile>> ludoTiles = [];
  List<List<int>> playersHouseIndices = [];
  List<int> diceValues = [0, 0];
  List<int> playersScores = [];
  List<String> ludoIndices = [];
  List<String> playersToasts = [];

  int currentPlayer = -1;
  bool showRollDice = true, roll = false;
  String message = "Your Turn";
  Timer? timer, perTimer;
  int playerTime = 30, gameTime = 0, adsTime = 0, roundsCount = 0;
  bool adLoaded = false;
  bool paused = true,
      finishedRound = false,
      checkout = false,
      pausePlayerTime = false;
  InterstitialAd? _interstitialAd;
  double padding = 0;
  FirebaseService fs = FirebaseService();
  String matchId = "";
  String gameId = "";
  int id = 0;
  String myId = "";
  String opponentId = "";
  List<User?>? users;
  List<User?> notReadyUsers = [];
  List<Playing> playing = [];
  int myPlayer = 0, playerIndex = 0;
  int opponentSize = 0;

  String currentPlayerId = "", partnerPlayerId = "";
  String updatePlayerId = "";

  int currentPlayerIndex = 0;
  StreamSubscription? detailsSub;
  StreamSubscription<List<Playing>>? playingSub;
  String indices = "";

  String hintMessage = "";
  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool changingGame = false;
  Map<int, List<int>> hintPositions = {};
  bool hintHouse = false;
  bool hintRollDice = true;
  bool hintEnterHouse = false;
  int myLudoIndex = 0;
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
    cellSize = (minSize - 2) / 15;
    gridLength = cellSize * 3;
    houseLength = (((minSize - 2) - gridLength) / 2);
    padding = (context.screenHeight - context.screenWidth).abs() / 2;
  }

  @override
  void initState() {
    super.initState();
    timerController = StreamController.broadcast();
    timerController.sink.add(gameTime);
    if (kIsWeb) ServicesBinding.instance.keyboard.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    id = widget.id ?? 0;
    myId = fs.myId;
    users = widget.users;
    matchId = widget.matchId ?? "";
    gameId = widget.gameId ?? "";
    indices = widget.indices ?? "";
    if (widget.indices != null && widget.indices != "") {
      ludoIndices = widget.indices!.split(",");
    } else {
      ludoIndices = getRandomIndex(4);
    }

    checkFirstime();
    initDetails();
    resetScores();
    readDetails();
    addInitialLudos();
  }

  void resetIfPlayerLeaveGame() {
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

  void initDetails() {
    if (users != null) {
      playersSize = users!.length;
    } else {
      playersSize = widget.playersSize ?? 2;
    }
    if (playersSize == 2) {
      playersHouseIndices.add([0, 1]);
      playersHouseIndices.add([2, 3]);
    } else {
      for (int i = 0; i < playersSize; i++) {
        playersHouseIndices.add([i]);
      }
    }
    opponentSize = gameId != "" ? playersSize - 1 : (playersSize / 2).ceil();
    playersToasts = List.generate(playersSize, (index) => "");
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
      if (playerTime <= 0) {
        playerTime = maxPlayerTime;
        // if (gameId != "" &&
        //     //currentPlayerId == myId &&
        //     playing.isNotEmpty &&
        //     playing.indexWhere((element) => element.id == currentPlayerId) ==
        //         -1) {
        //   getNextPlayer();
        //   return;
        // }
        playIfTimeOut();
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
      gameTime++;
      timerController.sink.add(gameTime);
      //setState(() {});
    });
  }

  void changePlayerIfTimeOut() async {
    if (gameId != "") {
      //pausePlayerTime = true;
      if (currentPlayerId == myId) {
        updateDiceDetails(0, 0);
      }
    } else {
      diceValues = [0, 0];
      showRollDice = true;
      selectedLudoTile = null;
      selectedLudo = null;
      changePlayer();
    }
  }

  void playIfTimeOut() async {
    changePlayerIfTimeOut();
    // if (showRollDice) {
    //   changePlayerIfTimeOut();
    // } else {
    //   final dice1 = diceValues[0];
    //   final dice2 = diceValues[1];
    //   final totalDice = dice1 + dice2;
    //   final playerLudos = activeLudos[currentPlayer]
    //       .where((element) => (element.step + totalDice) < 56)
    //       .toList();
    //   if (playerLudos.isNotEmpty) {
    //     final index = Random().nextInt(playerLudos.length);
    //     final ludo = playerLudos[index];
    //     final pos = convertToPosition([ludo.x, ludo.y], 6);
    //     final houseIndex = ludo.currentHouseIndex;
    //     //if (gameId != "") {
    //     pausePlayerTime = true;
    //     if (gameId != "") {
    //       if (currentPlayerId == myId) {
    //         if (hintPositions.isNotEmpty) {
    //           final posEntry = hintPositions.entries.last;
    //           await updateDetails(houseIndex, pos, false);
    //           await updateDetails(posEntry.key, posEntry.value.last, false);
    //         } else {
    //           changePlayerIfTimeOut();
    //         }
    //       }
    //     } else {
    //       if (hintPositions.isNotEmpty) {
    //         playLudo(houseIndex, pos);
    //         final positions = getHighestPosition(houseIndex);
    //         final newHouseIndex = positions[0];
    //         final newPos = positions[1];
    //         print("newHouseIndex: $newHouseIndex, newPos: $newPos");
    //         playLudo(newHouseIndex, newPos);
    //       } else {
    //         print("empty hint positions");
    //         changePlayerIfTimeOut();
    //       }
    //     }
    //     //}
    //   } else {
    //     changePlayerIfTimeOut();
    //     // if (dice1 == 6 || dice2 == 6) {
    //     //   final secondDice = dice1 == 6 ? dice2 : dice1;
    //     //   final houses = playersHouseIndices[currentPlayer];
    //     //   int houseIndex = 0;
    //     // } else {
    //     //   changePlayerIfTimeOut();
    //     // }
    //   }
    // }
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
    playersScores = List.generate(playersSize, (index) => 0);
  }

  void addInitialLudos() {
    getCurrentPlayer();
    pausePlayerTime = false;
    finishedRound = false;
    hintPositions.clear();
    ludoTiles.clear();
    ludos.clear();
    activeLudos.clear();
    playersWonLudos.clear();
    colors.clear();
    diceValues = [0, 0];
    activeLudos.clear();
    activeLudos = List.generate(playersSize, (index) => []);
    playersWonLudos = List.generate(4, (index) => []);
    List<Ludo> ludoList = getLudos();
    colors.addAll(ludoColors);
    colors = colors.arrangeWithStringList(ludoIndices);
    ludos = ludoList.groupListToList((ludo) => ludo.houseIndex);
    for (int i = 0; i < 4; i++) {
      ludoTiles.add(List.generate(18, (index) {
        final grids = convertToGrid(index, 6);
        final x = grids[0];
        final y = grids[1];
        return LudoTile(x, y, "$index", [], i);
      }));
    }
    setState(() {});
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
          if (currentPlayer == playerIndex) {
            getNextPlayer();
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
          if (value.game != ludoGame) {
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
      if (newgame != "" && newgame != ludoGame) {
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

      detailsSub = fs.getLudoDetails(gameId).listen((details) async {
        if (details != null) {
          played = false;
          pausePlayerTime = false;
          final playPos = details.playPos;
          final playHouseIndex = details.playHouseIndex;
          final selectedFromHouse = details.selectedFromHouse;
          final enteredHouse = details.enteredHouse;
          if (enteredHouse) {
            enterHouse();
            return;
          }
          if (playPos != -1 && playHouseIndex != -1) {
            if (selectedFromHouse) {
              selectLudo(playHouseIndex, playPos);
            } else {
              playLudo(playHouseIndex, playPos);
            }
          } else {
            int dice1 = details.dice1;
            int dice2 = details.dice2;
            if (dice1 != -1 && dice2 != -1) {
              diceValues = [dice1, dice2];
              updateDice();
            }
          }
          pausePlayerTime = false;
          setState(() {});
        }
      });
    }
  }

  Future updateDiceDetails(int dice1, int dice2) async {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = LudoDetails(
        currentPlayerId: myId,
        dice1: dice1,
        dice2: dice2,
        playPos: -1,
        playHouseIndex: -1,
        selectedFromHouse: false,
        enteredHouse: false,
        ludoIndices: "",
      );
      await fs.setLudoDetails(
        gameId,
        details,
        prevDetails,
      );
      prevDetails = details;
    }
  }

  void updateEnterHouseDetails() {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = LudoDetails(
        currentPlayerId: myId,
        enteredHouse: true,
        selectedFromHouse: false,
        playPos: -1,
        playHouseIndex: -1,
        dice1: diceValues.first,
        dice2: diceValues.second ?? 0,
        ludoIndices: "",
      );
      fs.setLudoDetails(
        gameId,
        details,
        prevDetails,
      );
      prevDetails = details;
    }
  }

  Future updateDetails(
      int playHouseIndex, int playPos, bool selectedFromHouse) async {
    if (matchId != "" && gameId != "" && users != null) {
      if (played) return;
      played = true;
      final details = LudoDetails(
        currentPlayerId: myId,
        playPos: playPos,
        playHouseIndex: playHouseIndex,
        selectedFromHouse: selectedFromHouse,
        enteredHouse: false,
        dice1: diceValues.first,
        dice2: diceValues.second ?? 0,
        ludoIndices: "",
      );
      await fs.setLudoDetails(
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
      updateAction(context, fs, playing, users!, gameId, matchId, myId,
          start ? "start" : "restart", ludoGame, gameTime > 0, id, gameTime);
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
        timerController.sink.add(gameTime);
        resetIfPlayerLeaveGame();
        initDetails();
        addInitialLudos();
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
      timerController.sink.add(gameTime);
      resetIfPlayerLeaveGame();
      initDetails();
      resetScores();
      addInitialLudos();
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
        resetIfPlayerLeaveGame();
        gotoOnlineGamePage(context, game, gameId, matchId, users!, null, id);
      } else {
        gotoOfflineGamePage(context, game, playersSize, id);
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
        fs.leaveGame(gameId, matchId, playing, gameTime > 0, id, gameTime);
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
      if (newgame == ludoGame) {
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
    // int toastIndex = playersSize == 2
    //     ? playerIndex
    //     : playerIndex < 2
    //         ? 0
    //         : 1;
    setState(() {
      playersToasts[playerIndex] = message;
    });
  }

  Alignment getAlignment(int index) {
    if (index == 0) return Alignment.topLeft;
    if (index == 1) return Alignment.topRight;
    if (index == 2) return Alignment.bottomRight;
    if (index == 3) return Alignment.bottomLeft;
    return Alignment.topLeft;
  }

  List<int> getHouseIndices(int player) {
    if (playersSize == 2) {
      return player == 0 ? [0, 1] : [2, 3];
    } else {
      return [player];
    }
  }

  int getPlayer(int index) {
    return playersSize > 2
        ? index
        : index > 1
            ? 1
            : 0;
  }

  void updateDice() {
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    showRollDice = false;
    roll = false;
    if (dice1 == 6 || dice2 == 6) {
      sixsix = dice1 == 6 && dice2 == 6;
    }
    changePlayerAfterMoving();
    playerTime = maxPlayerTime;
    setState(() {});
  }

  void rollDice() async {
    if (roll) return;
    setState(() {
      roll = true;
    });
    // final rand = Random();
    // final dice1 = rand.nextInt(6) + 1;
    // final dice2 = rand.nextInt(6) + 1;
    // diceValues = [dice1, dice2];
    // if (gameId != "") {
    //   updateDiceDetails(dice1, dice2);
    // } else {
    //   updateDice();
    // }
  }

  void enterHouse() {
    int dice1 = diceValues[0];
    int dice2 = diceValues[1];
    if (selectedLudoTile == null) return;
    final selectedLudo = selectedLudoTile!.ludos.first;
    int stepCount = 0;
    int totalStepCount = 56 - selectedLudo.step;
    //int totalStepCount = 6 - selX;
    if ((totalStepCount == dice1 ||
        totalStepCount == dice2 ||
        totalStepCount == (dice1 + dice2))) {
      if (totalStepCount == dice1) {
        stepCount = dice1;
      } else if (totalStepCount == dice2) {
        stepCount = dice2;
      } else if (totalStepCount == (dice1 + dice2)) {
        stepCount = dice1 + dice2;
      }
      if (stepCount == dice1) {
        dice1 = 0;
      } else if (stepCount == dice2) {
        dice2 = 0;
      } else if (stepCount == (dice1 + dice2)) {
        dice2 = 0;
        dice1 = 0;
      }
      selectedLudo.step += stepCount;
      selectedLudo.currentHouseIndex = selectedLudo.houseIndex;
      selectedLudo.x = -1;
      selectedLudo.y = -1;
      diceValues = [dice1, dice2];
      activeLudos[currentPlayer]
          .removeWhere((element) => element.id == selectedLudo.id);
      playersWonLudos[selectedLudo.houseIndex].add(selectedLudo);

      hintEnterHouse = false;
      selectedLudoTile!.ludos.removeAt(0);
      selectedLudoTile = null;
      showToast(currentPlayer, "Entered House");
      checkWinGame();
      changePlayerAfterMoving();
      // if (diceValues[0] != 0 && diceValues[1] != 0) {
      //   showPossiblePlayPositions();
      // }
      setState(() {});
    } else {
      showToast(currentPlayer,
          "You can't enter house yet. you need $totalStepCount more steps to enter");
    }
  }

  void selectLudo(int houseIndex, int index) {
    int player = getPlayer(houseIndex);
    if (player != currentPlayer && selectedLudo == null) {
      final houses = playersHouseIndices[currentPlayer];
      List<String> playerColors = [];
      for (int i = 0; i < houses.length; i++) {
        final house = houses[i];
        final color = colors[house];
        playerColors.add(color.name);
      }
      showToast(currentPlayer,
          "This is not your ludo. Your ludo ${playerColors.length == 1 ? "color is ${playerColors.first}" : "colors are ${playerColors.first} and ${playerColors.second}"} ");
      return;
    }
    final ludo = ludos[houseIndex][index];
    if (selectedLudo != null && selectedLudo == ludo) {
      selectedLudo = null;
      hintPositions.clear();
      showPossiblePlayPositions();
    } else {
      if (selectedLudoTile != null) {
        selectedLudoTile = null;
      }
      selectedLudo = ludo;
      getHintPositions(houseIndex, index);
    }
    setState(() {});
  }

  List<int> getHighestPosition(int houseIndex) {
    if (hintPositions[houseIndex] == null) {
      houseIndex = nextLudoHouseIndex(houseIndex);
    }
    while (hintPositions[houseIndex] != null) {
      houseIndex = nextLudoHouseIndex(houseIndex);
    }
    // final largestHouseIndex =
    //     hintPositions.keys.toList().sortedList((val) => val, false).last;
    // final largestPos =
    //     hintPositions[largestHouseIndex]!.sortedList((val) => val, false).last;
    // for(final entry in hintPositions.entries){
    //   final houseIndex = entry.key;
    //   final positions = entry.value;
    //   for(int i = 0; i < positions.length; i++){
    //     final pos = positions[i];
    //     f

    //   }
    // }
    return [houseIndex, hintPositions[houseIndex]!.last];
  }

  void getHintPositions(int houseIndex, int pos) {
    //if (!firstTime) return;
    hintPositions.clear();
    final coordinates = convertToGrid(pos, 6);
    final x = coordinates[0];
    final y = coordinates[1];
    int dice1 = diceValues[0];
    int dice2 = diceValues[1];
    final selectedLudo = this.selectedLudo != null
        ? null
        : ludoTiles[houseIndex][pos].ludos.first;

    if (this.selectedLudo != null) {
      final secondDice = dice1 == 6 ? dice2 : dice1;
      if (hintPositions[houseIndex] != null) {
        hintPositions[houseIndex]!.add(1);
      } else {
        hintPositions[houseIndex] = [1];
      }
      if (secondDice != 0) {
        if (secondDice > 4) {
          final remainder = secondDice - 4;
          final newPos = 18 - remainder;
          int nextHouse = nextLudoHouseIndex(houseIndex);
          if (hintPositions[nextHouse] != null) {
            hintPositions[nextHouse]!.add(newPos);
          } else {
            hintPositions[nextHouse] = [newPos];
          }
        } else {
          final newPos = secondDice + 1;
          if (hintPositions[houseIndex] != null) {
            hintPositions[houseIndex]!.add(newPos);
          } else {
            hintPositions[houseIndex] = [newPos];
          }
        }
      }
    } else {
      List<int> stepCounts = [];
      int totalSteps = dice1 + dice2;
      if (dice1 != 0) {
        stepCounts.add(dice1);
      }
      if (dice2 != 0) {
        stepCounts.add(dice2);
      }
      if (totalSteps != dice1 && totalSteps != dice2) {
        stepCounts.add(totalSteps);
      }
      for (int i = 0; i < stepCounts.length; i++) {
        final stepCount = stepCounts[i];
        int ludoStep = selectedLudo!.step;
        if (!hintEnterHouse && ludoStep + stepCount == 56) {
          hintEnterHouse = true;
        }
        final selCount = y == 0
            ? 5 - x
            : y == 1 && ludoStep >= 50
                ? 6 - x
                : (x + 5 + y);
        if (stepCount > selCount) {
          final remainder = stepCount - selCount;
          final nextHouse = nextLudoHouseIndex(houseIndex);
          if (selectedLudoTile != null &&
              selectedLudoTile!.houseIndex == selectedLudo.houseIndex &&
              selectedLudo.step >= 44) return;
          final newPos =
              getStepPosition(5, 2, remainder - 1, (ludoStep + stepCount) > 43);
          if (newPos != -1) {
            if (hintPositions[nextHouse] != null) {
              hintPositions[nextHouse]!.add(newPos);
            } else {
              hintPositions[nextHouse] = [newPos];
            }
          }
        } else {
          final newPos = getStepPosition(x, y, stepCount, ludoStep > 43);
          if (newPos != -1) {
            if (hintPositions[houseIndex] != null) {
              hintPositions[houseIndex]!.add(newPos);
            } else {
              hintPositions[houseIndex] = [newPos];
            }
          }
        }
      }
    }
    //getHintMessage();
    setState(() {});
  }

  int getStepPosition(int x, int y, int step, [bool enteringHouse = false]) {
    int newX = x;
    int newY = y;
    int newStep = step;

    if (y == 2) {
      if (newX - newStep >= 0) {
        newX -= newStep;
      } else {
        newStep = newStep - newX;
        newStep -= 1;
        newX = 0;
        newY = 1;
        if (newStep > 0) {
          if (!enteringHouse) {
            newStep -= 1;
            newY = 0;
          }
          if (newStep > 0) {
            if (newX + newStep > 5) {
              newX = 5;
              return -1;
            } else {
              newX += newStep;
              newStep = newStep - newX;
            }
          }
        }
      }
    } else {
      if (!enteringHouse && y == 1) {
        newStep -= 1;
        newY = 0;
      }
      if (newStep > 0) {
        if (newX + newStep > 5) {
          newX = 5;
          return -1;
        } else {
          newX += newStep;
        }
      }
    }
    return convertToPosition([newX, newY], 6);
  }

  void getHintMessage() {
    if (!firstTime) return;
    if (showRollDice) {
      hintMessage = "Tap to roll dice";
    } else {
      final hasSix = diceValues[0] == 6 || diceValues[1] == 6;
      if (hasSix) {
        hintMessage =
            "Tap on any ludo in house to bring out or play any active ludo";
      } else {
        hintMessage = "Tap on your ludo and count the dice step";
      }
    }

    message = hintMessage;
    setState(() {});
  }

  void checkFirstime() async {
    sharedPref = await SharedPreferences.getInstance();
    int playTimes = sharedPref!.getInt(playedLudoGame) ?? 0;

    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref!.setInt(playedLudoGame, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void showPossiblePlayPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    if (showRollDice) return;
    final playerLudos = activeLudos[currentPlayer];
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    hintHouse = dice1 == 6 || dice2 == 6;
    if (playerLudos.isNotEmpty) {
      for (int i = 0; i < playerLudos.length; i++) {
        final ludo = playerLudos[i];
        if ((dice1 != 0 && ludo.step + dice1 <= 56) ||
            (dice2 != 0 && ludo.step + dice2 <= 56)) {
          int pos = convertToPosition([ludo.x, ludo.y], 6);
          if (hintPositions[ludo.currentHouseIndex] != null) {
            hintPositions[ludo.currentHouseIndex]!.add(pos);
          } else {
            hintPositions[ludo.currentHouseIndex] = [pos];
          }
        }
      }
    }
    getHintMessage();
    setState(() {});
  }

  void switchLudo(int index, int pos) {
    LudoTile ludoTile = ludoTiles[index][pos];
    if (ludoTile.ludos.length < 2) {
      return;
    }
    int player = getPlayer(ludoTile.ludos.first.houseIndex);
    if (player != currentPlayer) {
      showToast(player,
          "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
      return;
    }
    final lastLudo = ludoTile.ludos.last;
    ludoTile.ludos[ludoTile.ludos.length - 1] =
        ludoTile.ludos[ludoTile.ludos.length - 2];
    ludoTile.ludos[ludoTile.ludos.length - 2] = lastLudo;
    showToast(currentPlayer, "Ludo switched");
    setState(() {});
  }

  void playLudo(int index, int pos) {
    LudoTile ludoTile = ludoTiles[index][pos];
    if (selectedLudoTile != null && selectedLudoTile == ludoTile) {
      selectedLudoTile = null;
      if (selectedLudo != null) selectedLudo = null;
      hintPositions.clear();
      showPossiblePlayPositions();
      setState(() {});
      return;
    }
    if (ludoTile.ludos.isNotEmpty) {
      int player = getPlayer(ludoTile.ludos.first.houseIndex);
      if (player != currentPlayer &&
          selectedLudoTile == null &&
          selectedLudo == null) {
        final houses = playersHouseIndices[currentPlayer];
        List<String> playerColors = [];
        for (int i = 0; i < houses.length; i++) {
          final house = houses[i];
          final color = colors[house];
          playerColors.add(color.name);
        }
        showToast(currentPlayer,
            "This is not your ludo. Your ludo ${playerColors.length == 1 ? "color is ${playerColors.first}" : "colors are ${playerColors.first} and ${playerColors.second}"} ");
        return;
      }
      if (showRollDice && player == currentPlayer) {
        showToast(currentPlayer, "Roll the dice first");
        return;
      }

      if (selectedLudoTile != null || selectedLudo != null) {
        moveLudo(ludoTile, index, pos);
      } else {
        selectedLudoTile = ludoTile;
        getHintPositions(index, pos);
      }
      selectedLudo = null;
      setState(() {});
    } else {
      if (selectedLudoTile != null || selectedLudo != null) {
        moveLudo(ludoTile, index, pos);
      }
    }
  }

  bool canCapture(Ludo ludo, int stepCount) {
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    if (stepCount == (dice1 + dice2)) return true;
    if ((dice1 == 6 && dice2 == stepCount) ||
        (dice2 == 6 && dice1 == stepCount)) return true;
    if (dice1 == 0 || dice2 == 0) return true;
    if (activeLudos.isEmpty) return stepCount > 0;
    final playerLudos = activeLudos[currentPlayer]
        .where((element) => element.id != ludo.id)
        .toList();
    if (playerLudos.isEmpty) return false;
    final ludoStep = dice1 == stepCount ? dice2 : dice1;
    if (ludoStep == 6 && hasPlayerInHouse()) return true;
    final playableLudos = playerLudos
        .where((element) => (element.step + ludoStep) <= 56)
        .toList();
    if (playableLudos.isNotEmpty) {
      return true;
    }
    return false;
    //return (ludo.step + dice1 + dice2) > 56;
  }

  void moveLudo(LudoTile ludoTile, int houseIndex, int pos) {
    int dice1 = diceValues[0];
    int dice2 = diceValues[1];
    if (this.selectedLudo != null) {
      if (this.selectedLudo!.houseIndex != houseIndex && (pos < 16)) {
        //checking if it is selected from and placed in the right the right house
        changeSelectionIfAnother(ludoTile, pos);
        return;
      }
      if (dice1 == 6) {
        dice1 = 0;
      } else if (dice2 == 6) {
        dice2 = 0;
      }
    }
    int totalStepCount = 0;
    final coordinates = convertToGrid(pos, 6);
    final x = coordinates[0];
    final y = coordinates[1];
    final selectedLudo = this.selectedLudo ?? selectedLudoTile!.ludos.first;
    final selectedHouseIndex =
        this.selectedLudo?.houseIndex ?? selectedLudoTile!.houseIndex;
    final selectedPos =
        this.selectedLudo != null ? 1 : int.parse(selectedLudoTile!.id);
    final prevCoordinates = convertToGrid(selectedPos, 6);
    final selX = prevCoordinates[0];
    final selY = prevCoordinates[1];
    if (y == 0 &&
        x == 0 &&
        houseIndex == selectedLudo.houseIndex &&
        selectedLudo.step == -1) {
      //checking if coming out and not starting from the first position
      changeSelectionIfAnother(ludoTile, pos);
      return;
    }
    if (y == 1 && x != 0 && houseIndex != selectedLudo.houseIndex) {
      //making sure that the ludo is not going to the wrong path and about to enter the house
      changeSelectionIfAnother(ludoTile, pos);
      return;
    }
    bool isBackMove = false;
    if (selectedHouseIndex == houseIndex) {
      if (y == selY) {
        isBackMove = (selY < 2 && x < selX) || (selY == 2 && x > selX);
      } else {
        isBackMove =
            (selY == 1 && selectedLudo.step >= 50 && (y == 0 || y == 2)) ||
                y > selY;
      }

      final xDiff = (x - selX).abs();
      final yDiff = (y - selY).abs();
      final count = selY == y ? xDiff : (selX + x + yDiff);
      totalStepCount += count;
    } else {
      final prevHouse = prevLudoHouseIndex(selectedHouseIndex);
      if (prevHouse == houseIndex ||
          prevLudoHouseIndex(prevHouse) == houseIndex) {
        //check for backward movement
        changeSelectionIfAnother(ludoTile, pos);
        return;
      }
      final nextHouse = nextLudoHouseIndex(selectedHouseIndex);
      if (houseIndex == nextHouse) {
        if (selectedHouseIndex == selectedLudo.houseIndex &&
            selectedLudo.step >= 44) {
          //checking for maximum length of possible next house movement
          changeSelectionIfAnother(ludoTile, pos);
          return;
        }
        final selCount = selY == 0
            ? 5 - selX
            : selY == 1 && selectedLudo.step >= 50
                ? 6 - selX
                : (selX + 5 + selY);
        totalStepCount += selCount;
        final houseCount = y == 2 ? 6 - x : (x + 6 + (2 - y));
        totalStepCount += houseCount;
      }
    }

    int stepCount = 0;
    if (!isBackMove &&
        (totalStepCount > 0 ||
            (totalStepCount == 0 && this.selectedLudo != null)) &&
        (totalStepCount == dice1 ||
            totalStepCount == dice2 ||
            totalStepCount == (dice1 + dice2))) {
      final step = selectedLudo.step;
      if (totalStepCount == dice1) {
        stepCount = dice1;
      } else if (totalStepCount == dice2) {
        stepCount = dice2;
      } else if (totalStepCount == (dice1 + dice2)) {
        stepCount = dice1 + dice2;
      }
      final finalStep = step + stepCount;
      if (selectedLudo.houseIndex == houseIndex &&
          ((finalStep >= 50 && finalStep <= 55 && y != 1) ||
              (finalStep >= 44 && finalStep <= 49 && y != 2) ||
              (finalStep >= 1 && finalStep <= 5 && y != 0))) {
        String msg = "";
        if (finalStep >= 50 && finalStep <= 55 && y != 1) {
          msg =
              "You are meant to enter your house now. Go through the center path";
        } else if (finalStep >= 44 && finalStep <= 49 && y != 2) {
          msg = "you are on the wrong path";
        } else if (finalStep >= 1 && finalStep <= 5 && y != 0) {
          msg = "You shoud follow the arrow path to start";
        }
        showToast(currentPlayer, msg);
        return;
      }

      if (ludoTile.ludos.isNotEmpty &&
          getPlayer(selectedLudo.houseIndex) !=
              getPlayer(ludoTile.ludos.first.houseIndex)) {
        if (!canCapture(selectedLudo, totalStepCount)) {
          showToast(currentPlayer,
              "You have to play your total dice at once since you can't play another");
          return;
        }
        if (selectedLudo.step == -1 && this.selectedLudo != null) {
          selectedLudo.step = 0;
        }
        final ludo = ludoTile.ludos.first;
        ludo.step = -1;
        ludo.x = -1;
        ludo.y = -1;
        ludo.currentHouseIndex = ludo.houseIndex;
        ludos[ludo.houseIndex].add(ludo);
        ludoTile.ludos.removeAt(0);
        activeLudos[getPlayer(ludo.houseIndex)]
            .removeWhere((element) => element.id == ludo.id);

        selectedLudo.step = 56;
        selectedLudo.x = -1;
        selectedLudo.y = -1;
        selectedLudo.currentHouseIndex = selectedLudo.houseIndex;

        activeLudos[currentPlayer]
            .removeWhere((element) => element.id == selectedLudo.id);
        playersWonLudos[selectedLudo.houseIndex].add(selectedLudo);
      } else {
        if (selectedLudo.step == -1 && this.selectedLudo != null) {
          selectedLudo.step = 0;
        }
        selectedLudo.step += stepCount;
        selectedLudo.currentHouseIndex = ludoTile.houseIndex;
        selectedLudo.x = ludoTile.x;
        selectedLudo.y = ludoTile.y;

        ludoTile.ludos.insert(0, selectedLudo);
        if (this.selectedLudo != null) {
          activeLudos[currentPlayer].add(selectedLudo);
        }
      }

      if (this.selectedLudo != null) {
        ludos[this.selectedLudo!.houseIndex]
            .removeWhere((element) => element.id == selectedLudo.id);
        this.selectedLudo = null;
      } else {
        selectedLudoTile!.ludos.removeAt(0);
      }

      if (stepCount == dice1) {
        dice1 = 0;
      } else if (stepCount == dice2) {
        dice2 = 0;
      } else if (stepCount == (dice1 + dice2)) {
        dice2 = 0;
        dice1 = 0;
      }
      diceValues = [dice1, dice2];
      selectedLudoTile = null;
      hintPositions.clear();
      checkWinGame();
      changePlayerAfterMoving();
      setState(() {});
    } else {
      changeSelectionIfAnother(ludoTile, pos);
      //Fluttertoast.showToast(msg: "Invalid Position. Recount");
    }
  }

  void changeSelectionIfAnother(LudoTile ludoTile, int pos) {
    if (ludoTile.ludos.isNotEmpty) {
      int player = getPlayer(ludoTile.ludos.first.houseIndex);
      if (player != currentPlayer) {
        showToast(player,
            "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
        return;
      }
      selectedLudoTile = ludoTile;
      getHintPositions(ludoTile.houseIndex, pos);
      setState(() {});
    }
  }

  void resetIfCantEnterHouse() {
    final playerLudos = activeLudos[currentPlayer];
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    final hasSix = dice1 == 6 || dice2 == 6;
    if (dice1 == 0 && dice2 == 0) {
      showRollDice = true;
      return;
    }
    if (playerLudos.isEmpty && (!hasSix || !hasPlayerInHouse())) {
      //diceValues = [0, 0];
      showRollDice = true;
      return;
    }
    final ludosEnteringHouse =
        playerLudos.where((element) => element.step > 50).toList();
    if (ludosEnteringHouse.isNotEmpty &&
        ludosEnteringHouse.length == playerLudos.length) {
      int count = 0;
      for (int i = 0; i < ludosEnteringHouse.length; i++) {
        final ludo = ludosEnteringHouse[i];
        final value = dice1 == 0
            ? dice2
            : dice2 == 0
                ? dice1
                : dice1 < dice2
                    ? dice1
                    : dice2;
        if ((ludo.step + value) <= 56) {
          count++;
        }
      }
      if (count == 0 && (!hasSix || !hasPlayerInHouse())) {
        //diceValues = [0, 0];
        showRollDice = true;
      }
    }
  }

  bool hasPlayerInHouse() {
    final houseIndices = playersHouseIndices[currentPlayer];
    int ludosCount = 0;
    for (int i = 0; i < houseIndices.length; i++) {
      final houseIndex = houseIndices[i];
      final playerHouseLudos = ludos[houseIndex];
      ludosCount += playerHouseLudos.length;
    }
    return ludosCount > 0;
  }

  void changePlayerAfterMoving() {
    hintHouse = false;
    hintEnterHouse = false;
    playerTime = maxPlayerTime;
    final dice1 = diceValues[0];
    final dice2 = diceValues[1];
    resetIfCantEnterHouse();
    if (showRollDice) {
      if (sixsix) {
        sixsix = false;
      } else {
        changePlayer();
      }
      setState(() {});
    } else {
      if (dice1 != 0 && dice2 != 0) {
        showPossiblePlayPositions();
      }
    }

    if (diceValues[0] != 0 || diceValues[1] != 0) {
      if (selectedLudoTile == null) {
        showPossiblePlayPositions();
      }
    }
  }

  void checkWinGame() async {
    final houseIndices = playersHouseIndices[currentPlayer];
    int ludosCount = 0;
    for (int i = 0; i < houseIndices.length; i++) {
      final houseIndex = houseIndices[i];
      final playerLudos = ludos[houseIndex];
      ludosCount += playerLudos.length;
    }
    if (ludosCount == 0 && activeLudos[currentPlayer].isEmpty) {
      pauseGame();
      playersScores[currentPlayer]++;
      updateMatchRecord();
      roundsCount++;
      pausePlayerTime = true;
      finishedRound = true;
      hintPositions.clear();
      toastWinner(currentPlayer);
      setState(() {});
    }
  }

  void toastDraw() {
    String message = "It's a draw";
    showToast(0, message);
    showToast(1, message);
  }

  void toastWinner(int player) {
    String message =
        "${users != null ? users![player]?.username ?? "" : "Player ${player + 1}"} Won";
    showToast(0, message);
    showToast(1, message);
  }

  int prevLudoHouseIndex(int selectedHouseIndex) {
    return selectedHouseIndex == 0 ? 3 : selectedHouseIndex - 1;
  }

  int nextLudoHouseIndex(int selectedHouseIndex) {
    return selectedHouseIndex == 3 ? 0 : selectedHouseIndex + 1;
  }

  void changePlayer() {
    playerTime = maxPlayerTime;
    message = "Your Turn";
    getNextPlayer();
    hintPositions.clear();
    setState(() {});
  }

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

  Color convertToColor(LudoColor color) {
    if (color == LudoColor.blue) return Colors.blue;
    if (color == LudoColor.red) return Colors.red;
    if (color == LudoColor.yellow) return const Color(0xffF6BE00);
    if (color == LudoColor.green) return Colors.green;
    return const Color(0xffF6BE00);
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
      } else if (key == LogicalKeyboardKey.space && !paused && showRollDice) {
        if (gameId != "" && currentPlayerId != myId) {
          showToast(
              playersSize - 1, "Its ${getUsername(currentPlayerId)}'s turn");
          return false;
        }
        rollDice();
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
        quarterTurns: gameId != "" &&
                (myPlayer == 0 || (myPlayer == 1 && playersSize > 2))
            ? 2
            : 0,
        child: Stack(
          children: [
            ...List.generate(playersSize, (index) {
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(
                              //       horizontal: 12.0),
                              //   child:
                              // Row(
                              //   crossAxisAlignment: CrossAxisAlignment.center,
                              //   mainAxisAlignment: currentPlayer == index &&
                              //           showRollDice &&
                              //           !roll
                              //       ? MainAxisAlignment.spaceBetween
                              //       : MainAxisAlignment.center,
                              //   children: [
                              //     if (currentPlayer == index &&
                              //         showRollDice &&
                              //         !roll &&
                              //         !landScape) ...[
                              //       const SizedBox(width: 80),
                              //     ],
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
                                            color: darkMode
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.black
                                                    .withOpacity(0.5)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    GameTimer(
                                      timerStream: timerController.stream,
                                    ),
                                    // if (currentPlayer == index
                                    //     //&&
                                    //     //showRollDice &&
                                    //     //!roll
                                    //     ) ...[
                                    //   const SizedBox(height: 4),
                                    //   GestureDetector(
                                    //       behavior: HitTestBehavior.opaque,
                                    //       onTap: () {
                                    //         if (gameId != "" &&
                                    //             currentPlayerId != myId) {
                                    //           showToast(playerIndex,
                                    //               "Its ${getUsername(currentPlayerId)}'s turn");
                                    //           return;
                                    //         }
                                    //         rollDice();
                                    //       },
                                    //       child: BlinkingBorderContainer(
                                    //         blink: firstTime &&
                                    //             hintRollDice &&
                                    //             showRollDice,
                                    //         width: minSize / 2,
                                    //         height: 40,
                                    //         alignment: Alignment.center,
                                    //         decoration: BoxDecoration(
                                    //             border: Border.all(
                                    //                 color: darkMode
                                    //                     ? Colors.white
                                    //                     : Colors.black,
                                    //                 width: 1.5),
                                    //             color: darkMode
                                    //                 ? lightestWhite
                                    //                 : lightestBlack,
                                    //             borderRadius:
                                    //                 BorderRadius.circular(
                                    //                     30)),
                                    //         child: StreamBuilder<int>(
                                    //             stream:
                                    //                 timerController.stream,
                                    //             builder: (context, snapshot) {
                                    //               return Text(
                                    //                 "Roll Dice - $playerTime",
                                    //                 style: TextStyle(
                                    //                     fontSize: 18,
                                    //                     color: darkMode
                                    //                         ? Colors.white
                                    //                         : Colors.black),
                                    //                 textAlign:
                                    //                     TextAlign.center,
                                    //               );
                                    //             }),
                                    //       )),
                                    // ],
                                    if (currentPlayer == index &&
                                        !showRollDice) ...[
                                      const SizedBox(height: 4),
                                      StreamBuilder<int>(
                                          stream: timerController.stream,
                                          builder: (context, snapshot) {
                                            return Text(
                                              "Your Turn - $playerTime",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
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
                              // if (currentPlayer == index &&
                              //     showRollDice &&
                              //     !roll) ...[
                              //   //const SizedBox(width: 20),
                              //   GestureDetector(
                              //       behavior: HitTestBehavior.opaque,
                              //       onTap: () {
                              //         if (gameId != "" &&
                              //             currentPlayerId != myId) {
                              //           showToast(playerIndex,
                              //               "Its ${getUsername(currentPlayerId)}'s turn");
                              //           return;
                              //         }
                              //         rollDice();
                              //       },
                              //       child: BlinkingBorderContainer(
                              //         blink: firstTime &&
                              //             hintRollDice &&
                              //             showRollDice,
                              //         width: 80,
                              //         height: 80,
                              //         alignment: Alignment.center,
                              //         decoration: BoxDecoration(
                              //             border: Border.all(
                              //                 color: darkMode
                              //                     ? Colors.white
                              //                     : Colors.black,
                              //                 width: 3),
                              //             color: darkMode
                              //                 ? lightestWhite
                              //                 : lightestBlack,
                              //             borderRadius:
                              //                 BorderRadius.circular(40)),
                              //         child: StreamBuilder<int>(
                              //             stream: timerController.stream,
                              //             builder: (context, snapshot) {
                              //               return CircleProgressBar(
                              //                   progress: 30 - playerTime,
                              //                   total: 30,
                              //                   width: 80,
                              //                   height: 80,
                              //                   progressColor:
                              //                       Colors.purple,
                              //                   strokeColor:
                              //                       tintColorLight,
                              //                   backgroundColor:
                              //                       Colors.transparent,
                              //                   strokeWidth: 4,
                              //                   child: Image.asset(
                              //                     "assets/images/die.png",
                              //                     width: 40,
                              //                     height: 40,
                              //                   ));
                              //             }),
                              //       )),
                              // ],
                              //],
                              //   ),
                              // ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RotatedBox(
                                    quarterTurns: gameId != "" &&
                                            myPlayer != index &&
                                            getPartnerPlayer() != index
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
                          if (playersToasts[index] != "") ...[
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: CustomToast(
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
            }),
            if (showRollDice && !roll) ...[
              Positioned(
                top: currentPlayer == 0 ||
                        (currentPlayer == 1 && playersSize > 2)
                    ? 30
                    : null,
                bottom: (currentPlayer == 1 && playersSize == 2) ||
                        (currentPlayer > 1)
                    ? 30
                    : null,
                left: currentPlayer == 0 || currentPlayer == 3 ? 10 : null,
                right: currentPlayer == 1 || currentPlayer == 2 ? 10 : null,
                child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (gameId != "" && currentPlayerId != myId) {
                        showToast(playerIndex,
                            "Its ${getUsername(currentPlayerId)}'s turn");
                        return;
                      }
                      rollDice();
                    },
                    child: BlinkingBorderContainer(
                      blink: firstTime && hintRollDice && showRollDice,
                      width: 70,
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.transparent,
                              //color: darkMode ? Colors.white : Colors.black,
                              width: 3),
                          color: darkMode ? lightestWhite : lightestBlack,
                          borderRadius: BorderRadius.circular(35)),
                      child: StreamBuilder<int>(
                          stream: timerController.stream,
                          builder: (context, snapshot) {
                            return TweenAnimationBuilder(
                                tween: Tween<double>(
                                    begin: (30 - playerTime).toDouble(),
                                    end: (30 - playerTime + 1).toDouble()),
                                duration: const Duration(seconds: 1),
                                builder: (context, value, child) {
                                  return CircleProgressBar(
                                      progress: value,
                                      total: 30,
                                      width: 70,
                                      height: 70,
                                      progressColor: Colors.purple,
                                      strokeColor: tintColorLight,
                                      backgroundColor: Colors.transparent,
                                      strokeWidth: 4,
                                      child: Image.asset(
                                        "assets/images/die.png",
                                        width: 35,
                                        height: 35,
                                      ));
                                });
                          }),
                    )),
              ),
            ],
            Center(
              child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: darkMode ? Colors.white : Colors.black,
                            width: 1)),
                    child: Stack(
                      children: List.generate(5, (index) {
                        if (index == 4) {
                          return Align(
                            alignment: Alignment.center,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (gameId != "" && currentPlayerId != myId) {
                                  final username = getUsername(currentPlayerId);
                                  Fluttertoast.showToast(
                                      msg: "It's $username's turn");
                                  return;
                                }
                                if (gameId != "") {
                                  updateEnterHouseDetails();
                                } else {
                                  enterHouse();
                                }
                              },
                              child: BlinkingBorderContainer(
                                blink: hintEnterHouse,
                                width: gridLength,
                                height: gridLength,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: darkMode
                                            ? Colors.white
                                            : Colors.black,
                                        width: 1)),
                                child: roll
                                    ? RollingDice(
                                        onUpdate: (dice1, dice2) {},
                                        onComplete: (dice1, dice2) {
                                          if (gameId != "") {
                                            updateDiceDetails(dice1, dice2);
                                          } else {
                                            diceValues = [dice1, dice2];
                                            updateDice();
                                          }
                                        },
                                        size: gridLength ~/ 4,
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          diceValues.isEmpty ||
                                                  diceValues[0] == 0
                                              ? Container()
                                              : Dice(
                                                  value: diceValues[0],
                                                  size: gridLength ~/ 4,
                                                ),
                                          diceValues.isEmpty ||
                                                  (diceValues[0] == 0 &&
                                                      diceValues[1] == 0)
                                              ? Container()
                                              : const SizedBox(
                                                  width: 8,
                                                ),
                                          diceValues.isEmpty ||
                                                  diceValues[1] == 0
                                              ? Container()
                                              : Dice(
                                                  value: diceValues[1],
                                                  size: gridLength ~/ 4,
                                                ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        } else {
                          return Align(
                            alignment: getAlignment(index),
                            child: SizedBox(
                              child: RotatedBox(
                                quarterTurns: index,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: houseLength,
                                      width: houseLength,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: darkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              width: 1),
                                          color: convertToColor(colors[index])),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: houseLength,
                                            height: houseLength,
                                            child: GridView(
                                              padding: EdgeInsets.zero,
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2),
                                              children: List.generate(4,
                                                  // playersWonLudos[index].length,
                                                  (lindex) {
                                                return Container(
                                                  key: Key(lindex.toString()),
                                                  // key: Key(
                                                  //     playersWonLudos[index]
                                                  //             [lindex]
                                                  //         .id),
                                                  width: houseLength / 2,
                                                  height: houseLength / 2,
                                                  margin:
                                                      const EdgeInsets.all(8),
                                                  alignment: lindex == 0
                                                      ? Alignment.topLeft
                                                      : lindex == 1
                                                          ? Alignment.topRight
                                                          : lindex == 2
                                                              ? Alignment
                                                                  .bottomLeft
                                                              : Alignment
                                                                  .bottomRight,
                                                  child: lindex <
                                                          playersWonLudos[index]
                                                              .length
                                                      ? LudoDisc(
                                                          size: cellSize
                                                              .percentValue(60),
                                                          color: convertToColor(
                                                              colors[index]))
                                                      : null,
                                                  // child: Container(
                                                  //   height: houseLength / 4,
                                                  //   width: houseLength / 4,
                                                  //   // decoration: BoxDecoration(
                                                  //   //     color: Theme.of(context)
                                                  //   //         .scaffoldBackgroundColor,
                                                  //   //     borderRadius:
                                                  //   //         BorderRadius
                                                  //   //             .circular(
                                                  //   //                 houseLength /
                                                  //   //                     8),
                                                  //   //     border: Border.all(
                                                  //   //         color: darkMode
                                                  //   //             ? Colors.white
                                                  //   //             : Colors.black,
                                                  //   //         width: 2)),
                                                  //   padding: EdgeInsets.all(
                                                  //       ((houseLength / 4) /
                                                  //               2) -
                                                  //           cellSize / 2),
                                                  //   child: lindex <
                                                  //           playersWonLudos[
                                                  //                   index]
                                                  //               .length
                                                  //       ? LudoDisc(
                                                  //           size: cellSize
                                                  //               .percentValue(
                                                  //                   60),
                                                  //           color:
                                                  //               convertToColor(
                                                  //                   colors[
                                                  //                       index]))
                                                  //       : null,
                                                  // ),
                                                );
                                              }),
                                            ),
                                          ),
                                          Container(
                                            width: gridLength,
                                            height: gridLength,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: darkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    width: 2),
                                                color: Theme.of(context)
                                                    .scaffoldBackgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        gridLength / 2)
                                                // color:
                                                //     convertToColor(colors[index]),
                                                ),
                                            child: GridView(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2),
                                              children: List.generate(4,
                                                  //ludos[index].length,
                                                  (lindex) {
                                                // final ludo =
                                                //     ludos[index][lindex];

                                                final ludoIndex = ludos[index]
                                                    .indexWhere((ludo) =>
                                                        (index * 4) + lindex ==
                                                        int.parse(ludo.id));
                                                if (ludoIndex == -1) {
                                                  return SizedBox(
                                                    width: cellSize,
                                                    height: cellSize,
                                                  );
                                                }

                                                final ludo =
                                                    ludos[index][ludoIndex];
                                                final player = getPlayer(index);
                                                return GestureDetector(
                                                  key: Key(ludo.id),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    if (gameId != "" &&
                                                        currentPlayerId !=
                                                            myId) {
                                                      showToast(playerIndex,
                                                          "Its ${getUsername(currentPlayerId)}'s turn");
                                                      return;
                                                    }

                                                    if (gameId == "" &&
                                                        player !=
                                                            currentPlayer) {
                                                      showToast(currentPlayer,
                                                          "Its Player ${currentPlayer + 1}'s turn");
                                                      return;
                                                    }
                                                    if (showRollDice) {
                                                      showToast(currentPlayer,
                                                          "Roll the dice first");
                                                      return;
                                                    }

                                                    int dice1 = diceValues[0];
                                                    int dice2 = diceValues[1];
                                                    if (dice1 == 6 ||
                                                        dice2 == 6) {
                                                      if (gameId != "") {
                                                        updateDetails(index,
                                                            ludoIndex, true);
                                                      } else {
                                                        selectLudo(
                                                            index, ludoIndex);
                                                      }
                                                    }
                                                  },
                                                  child:
                                                      BlinkingBorderContainer(
                                                    blink: firstTime &&
                                                        hintHouse &&
                                                        playersHouseIndices[
                                                                currentPlayer]
                                                            .contains(index),
                                                    width: cellSize,
                                                    height: cellSize,
                                                    decoration: BoxDecoration(
                                                        color:
                                                            selectedLudo == ludo
                                                                ? Colors.purple
                                                                : null,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    cellSize /
                                                                        2)),
                                                    alignment: Alignment.center,
                                                    child: LudoDisc(
                                                        size: cellSize
                                                            .percentValue(60),
                                                        color: convertToColor(
                                                            colors[index])),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                            width: houseLength,
                                            height: gridLength,
                                            child: Column(
                                              children:
                                                  List.generate(3, (colindex) {
                                                return Expanded(
                                                  key: ValueKey(colindex),
                                                  child: Row(
                                                    children: List.generate(6,
                                                        (rowindex) {
                                                      final lindex =
                                                          convertToPosition([
                                                        rowindex,
                                                        colindex
                                                      ], 6);
                                                      final ludoTile =
                                                          ludoTiles[index]
                                                              [lindex];
                                                      return LudoTileWidget(
                                                        blink: hintPositions
                                                                .containsKey(
                                                                    index) &&
                                                            hintPositions[
                                                                    index]!
                                                                .contains(
                                                                    lindex),
                                                        key: Key(ludoTile.id),
                                                        ludoTile: ludoTile,
                                                        colors: colors,
                                                        size: cellSize,
                                                        pos: lindex,
                                                        highLight:
                                                            selectedLudoTile ==
                                                                ludoTile,
                                                        onDoubleTap: () {
                                                          if (gameId != "" &&
                                                              currentPlayerId !=
                                                                  myId) {
                                                            showToast(
                                                                playerIndex,
                                                                "Its ${getUsername(currentPlayerId)}'s turn");
                                                            return;
                                                          }
                                                        },
                                                        onPressed: () {
                                                          if (gameId != "" &&
                                                              currentPlayerId !=
                                                                  myId) {
                                                            showToast(
                                                                playerIndex,
                                                                "Its ${getUsername(currentPlayerId)}'s turn");
                                                            return;
                                                          }
                                                          if (gameId != "") {
                                                            updateDetails(
                                                              index,
                                                              lindex,
                                                              false,
                                                            );
                                                          } else {
                                                            playLudo(
                                                                index, lindex);
                                                          }
                                                        },
                                                        color: colors[index],
                                                      );
                                                    }),
                                                  ),
                                                );
                                              }),
                                            )),
                                        CustomPaint(
                                            size: Size(
                                                ((minSize - 2) / 2) -
                                                    houseLength,
                                                gridLength),
                                            painter: LudoTrianglePainter(
                                                color: convertToColor(
                                                    colors[index]))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                  )),
            ),
            if (firstTime && !paused && !seenFirstHint) ...[
              RotatedBox(
                quarterTurns: gameId != "" &&
                        (myPlayer == 0 || (myPlayer == 1 && playersSize > 2))
                    ? 2
                    : 0,
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: lighterBlack,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: const Center(
                      child: Text(
                          "Tap on roll dice button to roll dice\nPlay your dice value",
                          style: TextStyle(color: Colors.white, fontSize: 18),
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
                quarterTurns: gameId != "" &&
                        (myPlayer == 0 || (myPlayer == 1 && playersSize > 2))
                    ? 2
                    : 0,
                child: PausedGamePage(
                  context: context,
                  readAboutGame: readAboutGame,
                  game: "Ludo",
                  playersScores: playersScores,
                  users: users,
                  playersSize: playersSize,
                  finishedRound: finishedRound,
                  startingRound: gameTime == 0,
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
          ],
        ),
      )),
    );
  }
}
