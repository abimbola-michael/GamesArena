// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/models/games/whot.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/firebase_service.dart';
import '../../components/game_timer.dart';
import '../../components/custom_grid.dart';
import '../../components/custom_toast.dart';
import '../../components/games/whot_card.dart';
import '../../enums/emums.dart';
import '../../models/models.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../paused_game_page.dart';
import '../tabs/games_page.dart';

class WhotGamePage extends StatefulWidget {
  final String? matchId;
  final String? gameId;
  final List<User?>? users;
  final int? playersSize;
  final String? indices;
  final int? id;

  const WhotGamePage(
      {super.key,
      this.matchId,
      this.gameId,
      this.users,
      this.playersSize,
      this.indices,
      this.id});

  @override
  State<WhotGamePage> createState() => _WhotGamePageState();
}

class _WhotGamePageState extends State<WhotGamePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  WhotDetails? prevDetails;
  List<Whot> whots = [], playedWhots = [], newWhots = [];
  List<List<Whot>> playersWhots = [];
  List<WhotCardVisibility> cardVisibilities = [];
  List<String> playerMessages = [];
  List<String> playersToasts = [];
  List<int> playersScores = [];
  List<String> whotIndices = [];

  double whot_width = 0,
      whot_height = 0,
      whot_needshape_width = 0,
      whot_needshape_height = 0;
  int startCards = 4;
  WhotCardShape? shapeNeeded;
  bool awaiting = false;
  bool needShape = false;
  String message = "";
  bool showMessage = false;
  int playersSize = 2;
  int currentPlayer = -1, pickPlayer = -1;
  Timer? timer, perTimer;
  int playerTime = 30, gameTime = 0, adsTime = 0, roundsCount = 0;
  bool adLoaded = false;
  bool paused = true,
      finishedRound = false,
      checkout = false,
      completedPlayertime = false;
  InterstitialAd? _interstitialAd;
  double padding = 0;
  String matchId = "";
  String gameId = "";
  int id = 0;
  String myId = "";
  String opponentId = "";
  //String pickId = "";
  int pickCount = 1;
  List<User?>? users;
  List<User?> notReadyUsers = [];
  List<Playing> playing = [];

  int myPlayer = 0;
  int opponentSize = 0;
  String currentPlayerId = "", partnerPlayerId = "";
  String updatePlayerId = "";
  int currentPlayerIndex = 0;
  StreamSubscription? detailsSub;
  StreamSubscription<List<Playing>>? playingSub;
  FirebaseService fs = FirebaseService();
  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool hastLastCard = false;
  bool changingGame = false;
  String hintMessage = "";
  List<int> hintPositions = [];
  bool hintGeneralMarket = false;
  bool hintShapeNeeded = false;
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
    whot_height = (minSize - 80) / 3;
    whot_width = whot_height.percentValue(65);
    padding = (context.screenHeight - context.screenWidth).abs() / 2;
  }

  @override
  void initState() {
    super.initState();
    timerController = StreamController.broadcast();
    gameTime = maxGameTime;

    playerTime = maxPlayerTime;
    timerController.sink.add(gameTime);
    if (kIsWeb) ServicesBinding.instance.keyboard.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    id = widget.id ?? 0;
    myId = fs.myId;
    users = widget.users;
    matchId = widget.matchId ?? "";
    gameId = widget.gameId ?? "";
    if (widget.indices != null && widget.indices != "") {
      whotIndices = widget.indices!.split(",");
    } else {
      whotIndices = getRandomIndex(54);
    }
    checkFirstime();
    initDetails();
    resetScores();
    readDetails();
    addInitialWhots();
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
    opponentSize = (playersSize / 2).ceil();
    playersToasts = List.generate(playersSize, (index) => "");
    playerMessages = List.generate(playersSize, (index) => "");
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
      if (gameTime <= 0) {
        tenderCards();
      } else {
        if (!completedPlayertime && !awaiting) {
          if (playerTime <= 0) {
            playerTime = maxPlayerTime;
            if (gameId != "" &&
                playing.isNotEmpty &&
                playing.indexWhere(
                        (element) => element.id == currentPlayerId) ==
                    -1) {
              getNextPlayer();
              return;
            }
            playIfTimeOut();
            setState(() {});
          } else {
            playerTime--;
          }
          if (adsTime >= maxAdsTime) {
            loadAd();
            adsTime = 0;
          } else {
            adsTime++;
          }
        }
        gameTime--;
      }
      timerController.sink.add(gameTime);
      //setState(() {});
    });
  }

  void playIfTimeOut() {
    if (gameId != "") {
      completedPlayertime = true;
      if (currentPlayerId == myId) {
        if (needShape && shapeNeeded == null) {
          final index = Random().nextInt(5);
          updateDetails(-1, index, "");
        } else {
          updateDetails(-1, -1, "");
        }
      } else {}
    } else {
      if (needShape && shapeNeeded == null) {
        final index = Random().nextInt(5);
        playShape(index);
      } else {
        pickWhot();
      }
    }
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

  @override
  bool get wantKeepAlive => true;

  void showToast(int playerIndex, String message) {
    setState(() {
      playersToasts[playerIndex] = message;
    });
  }

  String getMessage(int index) {
    String message = playerMessages[index];
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

  void shareCards() async {
    if (awaiting) return;
    if (whots.isEmpty) return;
    for (int i = 0; i < playersSize; i++) {
      playersWhots.add([]);
    }
    awaiting = true;
    final cardsToShare = (startCards * playersSize) + 1;
    int j = 0;
    for (int i = 0; i < cardsToShare; i++) {
      if (i < whots.length) {
        final whot = whots.first;
        await Future.delayed(const Duration(milliseconds: 100));
        if (i == cardsToShare - 1) {
          playWhot(-1);
        } else {
          playersWhots[j].insert(0, whot);
          j = j == playersSize - 1 ? 0 : j + 1;
        }
        whots.removeAt(0);
        setState(() {});
      }
    }
    awaiting = false;
    completedPlayertime = false;

    message = "";
    setState(() {});
  }

  void showPossiblePlayPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    if (cardVisibilities[currentPlayer] == WhotCardVisibility.visible) return;
    final playerWhots = playersWhots[currentPlayer];
    for (int i = 0; i < playerWhots.length; i++) {
      hintPositions.add(i);
    }
    //getHintMessage(true);
    setState(() {});
  }

  void getHintPositions() {
    if (!firstTime) return;
    hintPositions.clear();
    final playerWhots = playersWhots[currentPlayer];
    if (needShape) {
      for (int i = 0; i < playerWhots.length; i++) {
        final whot = playerWhots[i];
        if (!hintPositions.contains(whot.shape)) {
          hintPositions.add(whot.shape);
        }
      }
    } else {
      final currentWhot = playedWhots.first;
      if (((currentWhot.number == 14 && pickPlayer != currentPlayer) ||
              (currentWhot.number == 2 && pickPlayer == currentPlayer)) &&
          pickPlayer != -1) {
        setState(() {
          hintGeneralMarket = true;
        });
        return;
      }
      bool containsOther = false;
      for (int i = 0; i < playerWhots.length; i++) {
        final whot = playerWhots[i];
        if (whot.number == 20 ||
            (currentWhot.number == 20 &&
                shapeNeeded != null &&
                whot.shape == shapeNeeded!.index)) {
          hintPositions.add(i);
        } else {
          if (!containsOther &&
              (currentWhot.number == whot.number ||
                  currentWhot.shape == whot.shape)) {
            containsOther = true;
          }
          if (whot.number == 20 ||
              currentWhot.number == whot.number ||
              currentWhot.shape == whot.shape ||
              whot.number == 20) {
            hintPositions.add(i);
          }
        }
      }
      hintGeneralMarket = hintPositions.isEmpty || !containsOther;
    }
    // getHintMessage(false);
    setState(() {});
  }

  void getHintMessage(bool played) {
    if (played) {
      hintMessage = "Tap to open cards";
    } else {
      if (needShape) {
        if (shapeNeeded != null) {
          hintMessage = "Play cards that match the requested shape";
        } else {
          hintMessage =
              "Choose the shape you need depending on the cards you have";
        }
      } else {
        hintMessage = "Play cards that match the played card number or shape";
      }
    }
    setState(() {});
  }

  void checkFirstime() async {
    sharedPref = await SharedPreferences.getInstance();
    int playTimes = sharedPref!.getInt(playedWhotGame) ?? 0;
    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref!.setInt(playedWhotGame, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void playWhot(int index) async {
    if (!mounted) return;

    if (needShape && index != -1) {
      showToast(currentPlayer, "Select shape");
      return;
    }
    Whot whot = index == -1 ? whots.first : playersWhots[currentPlayer][index];
    final currentWhot = playedWhots.isEmpty ? whots.first : playedWhots.first;
    if (shapeNeeded != null &&
        shapeNeeded != whotCardShapes[whot.shape] &&
        whot.number != 20 &&
        index != -1) {
      showToast(currentPlayer,
          "This is not ${shapeNeeded!.name}\n Go to Market if you don't have");
      return;
    }
    final next = nextPlayer();
    final prev = prevPlayer();
    final next2 = nextPlayer(true);
    final prev2 = prevPlayer(true);
    if (currentWhot.number == whot.number ||
        currentWhot.shape == whot.shape ||
        whot.number == 20 ||
        (shapeNeeded != null && shapeNeeded == whotCardShapes[whot.shape])) {
      final number = whot.number;
      if (index != -1) {
        // if (playedWhots.isNotEmpty && playedWhots.first.number == 1) {
        //   for (int i = 0; i < playersSize; i++) {
        //     if (i != currentPlayer) {
        //       playerMessages[i] = playerMessages[i].replaceAll("Hold On", "");
        //     }
        //   }
        // }
        playedWhots.insert(0, whot);
        final currentPlayerWhots = playersWhots[currentPlayer];
        if (currentPlayerWhots.isNotEmpty) {
          currentPlayerWhots.removeAt(index);
        }
      } else {
        playedWhots.add(whot);
      }

      playerMessages[currentPlayer] = "";
      playerMessages[prev] = "";

      String lastMessage = "";
      hastLastCard = false;
      // if (playersWhots[currentPlayer].length == 2) {
      //   lastMessage = "Semi Last Card ";
      //   hastLastCard = true;
      // } else
      if (playersWhots[currentPlayer].length == 1) {
        lastMessage = "Last Card ";
        hastLastCard = true;
      } else if (playersWhots[currentPlayer].isEmpty) {
        if (number != 1 &&
            number != 8 &&
            number != 14 &&
            number != 2 &&
            number != 20) {
          lastMessage = "Check Up";
        }
      }
      // if (lastMessage != "") {
      //   if (playersSize > 2) {
      //     lastMessage +=
      //         ": ${users != null ? "${users![currentPlayer]?.username ?? ""}\n" : "${currentPlayer + 1}"}\n";
      //   } else {
      //     lastMessage += "\n";
      //   }
      // }

      if (number == 1 || number == 8 || number == 14 || number == 2) {
        String nextMessage = number == 1
            ? "Hold On"
            : number == 8
                ? "Suspension"
                : number == 2
                    ? "Pick 2"
                    : "General Market";
        if (number == 14) {
          pickCount = 1;
          pickPlayer = currentPlayer;
        } else if (number == 2) {
          pickCount = 2;
          pickPlayer = next;
        }
// || number == 1
        if (number == 14) {
          for (int i = 0; i < playersSize; i++) {
            if (i != currentPlayer) {
              playerMessages[i] = "$lastMessage$nextMessage";
            }
            // else {
            //   if (number == 1) {
            //     playerMessages[currentPlayer] += "Continue";
            //   }
            // }
          }
        } else {
          playerMessages[next] = "";
          playerMessages[next2] = "";
          if (lastMessage != "") {
            for (int i = 0; i < playersSize; i++) {
              if (i != currentPlayer) {
                playerMessages[i] = lastMessage;
              }
            }
          }
          playerMessages[next] += nextMessage;
          if (number == 8 || number == 1) {
            playerMessages[next2] += "Continue";
          }
        }
      } else {
        if (lastMessage != "") {
          for (int i = 0; i < playersSize; i++) {
            if (i != currentPlayer) {
              playerMessages[i] = lastMessage;
            }
          }
        }
        needShape = number == 20;
        if (index != -1 && number != 20) {
          checkWinGame();
        }
      }

      if (shapeNeeded != null && shapeNeeded == whotCardShapes[whot.shape]) {
        needShape = false;
        shapeNeeded = null;
      }
// || number == 1
      if (number == 20) {
        playerTime = maxPlayerTime;
        if (index == -1) {
          showPossiblePlayPositions();
        } else {
          getHintPositions();
        }
      } else {
        changePlayer(number == 8 || number == 1);
        showPossiblePlayPositions();
      }
      hintGeneralMarket = number == 2 || number == 14;
      awaiting = false;
      setState(() {});
    } else {
      showToast(currentPlayer, "Cards Don't Match");
    }
  }

  void playShape(int index) {
    shapeNeeded = whotCardShapes[index];
    final next = nextPlayer();
    playerMessages[next] =
        "${playerMessages[currentPlayer].contains("I need") ? "" : "${playerMessages[currentPlayer]} "}I need ${shapeNeeded!.name}";
    needShape = false;
    changePlayer(false);
    showPossiblePlayPositions();
    setState(() {});
  }

  void pickWhot() {
    if (!mounted || awaiting || whots.isEmpty) return;
    // if (shapeNeeded == null) {
    //   message = "";
    // }
    for (int i = 0; i < pickCount; i++) {
      final whot = whots.first;
      playersWhots[currentPlayer].insert(0, whot);
      whots.removeAt(0);
      awaiting = false;
      if (whots.isEmpty) {
        tenderCards();
        return;
      }
    }

    // if (playedWhots.isNotEmpty && playedWhots.first.number == 1) {
    //   for (int i = 0; i < playersSize; i++) {
    //     if (i != currentPlayer) {
    //       playerMessages[i] = playerMessages[i].replaceAll("Hold On", "");
    //     }
    //   }
    // }
    resetLastOrSemiLastCard();
    final next = nextPlayer();
    final prev = prevPlayer();
    playerMessages[currentPlayer] = "";
    playerMessages[prev] = "";
    changePlayer(false, true);
    if (pickPlayer == currentPlayer) {
      pickPlayer = -1;
    }
    pickCount = 1;
    hastLastCard = false;
    showPossiblePlayPositions();
    setState(() {});
  }

  void resetLastOrSemiLastCard() {
    if (hastLastCard && playersWhots[currentPlayer].length == 1) {
      for (int i = 0; i < playersSize; i++) {
        if (i != currentPlayer) {
          final message = playerMessages[i];
          if (message.startsWith("Last Card ")) {
            playerMessages[i].replaceAll("Last Card ", "");
          }
          // else if (message.startsWith("Semi Last Card ")) {
          //   playerMessages[i].replaceAll("Semi Last Card ", "");
          // }
        }
      }
    }
  }

  void getNewWhots() {
    List<Whot> newWhots = [];
    if (playedWhots.isNotEmpty) {
      newWhots.addAll(playedWhots);
      newWhots.removeAt(0);
      final indices = newWhots.map((value) => value.id).toList();
      for (int i = 0; i < 10; i++) {
        indices.shuffle();
      }
      if (gameId == "") {
        updateNewWhots(indices);
      } else {
        updateDetails(-1, -1, indices.join(","));
      }
    } else {
      if (gameId == "") {
        pickWhot();
      } else {
        updateDetails(-1, -1, "");
      }
    }
  }

  void updateNewWhots(List<String> indices) {
    List<Whot> newPlayedWhot = [];
    List<Whot> newWhots = [], convertedWhots = [];
    if (playedWhots.isNotEmpty) {
      newPlayedWhot.add(playedWhots[0]);
      newWhots.addAll(playedWhots);
      newWhots.removeAt(0);
      for (int i = 0; i < indices.length; i++) {
        final id = indices[i];
        convertedWhots.add(newWhots.firstWhere((element) => element.id == id));
      }
      newWhots = convertedWhots;
      whots.addAll(newWhots);
      playedWhots.clear();
      playedWhots.addAll(newPlayedWhot);
      whotIndices = indices;
      setState(() {});
      showToast(currentPlayer, "Updated new whots");
      pickWhot();
    }
  }

  void hideCards() {
    if (needShape && shapeNeeded == null) return;
    for (int i = 0; i < playersSize; i++) {
      cardVisibilities[i] = WhotCardVisibility.turned;
      // if (i == playerIndex && gameId != "") {
      //   continue;
      // } else {
      //   cardVisibilities[i] = WhotCardVisibility.turned;
      // }
    }
    //if (gameId != "" || (needShape && shapeNeeded == null)) return;
    // if (playersSize == 2) {
    //   cardVisibilities[currentPlayer == 0 ? 1 : 0] = WhotCardVisibility.turned;
    //   cardVisibilities[currentPlayer] = WhotCardVisibility.turned;
    // } else {
    //   if (currentPlayer == 0 || currentPlayer == 1) {
    //     cardVisibilities[currentPlayer] = WhotCardVisibility.turned;
    //     cardVisibilities[currentPlayer == 0 ? 1 : 0] =
    //         WhotCardVisibility.hidden;
    //     cardVisibilities[2] = WhotCardVisibility.turned;
    //     if (playersSize == 4) {
    //       cardVisibilities[3] = WhotCardVisibility.hidden;
    //     }
    //   } else if (currentPlayer == 2 || currentPlayer == 3) {
    //     cardVisibilities[currentPlayer] = WhotCardVisibility.turned;
    //     if (playersSize == 4) {
    //       cardVisibilities[currentPlayer == 2 ? 3 : 2] =
    //           WhotCardVisibility.hidden;
    //     }
    //     cardVisibilities[0] = WhotCardVisibility.turned;
    //     cardVisibilities[1] = WhotCardVisibility.hidden;
    //   }
    // }
    // if (gameId != "") {
    //   cardVisibilities[playerIndex] = WhotCardVisibility.visible;
    //   if (playersSize == 4) {
    //     cardVisibilities[playerIndex == 2 ? 3 : 2] = WhotCardVisibility.turned;
    //   }
    // }
    setState(() {});
  }

  void changePlayer(bool suspend, [bool picked = false]) {
    hintGeneralMarket = false;
    playerTime = maxPlayerTime;
    // message = "Player $currentPlayer ${picked ? "picked" : "played"} Your Turn";
    getNextPlayer();
    if (suspend) getNextPlayer();
    if (gameId != "" || (playersSize == 2 && suspend)) {
      return;
    }
    hideCards();
  }

  int prevPlayer([bool doubleCount = false]) {
    if (gameId != "") {
      final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      int prevPlayerIndex = prevIndex(playersSize, currentPlayerIndex);
      String playerId = playerIds[prevPlayerIndex];
      while (playing.indexWhere((element) => element.id == playerId) == -1) {
        prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
        playerId = playerIds[prevPlayerIndex];
      }
      if (doubleCount) {
        prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
        playerId = playerIds[prevPlayerIndex];
        while (playing.indexWhere((element) => element.id == playerId) == -1) {
          prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
          playerId = playerIds[prevPlayerIndex];
        }
      }
      return prevPlayerIndex;
    } else {
      int prevPlayerIndex = prevIndex(playersSize, currentPlayer);
      if (doubleCount) {
        prevPlayerIndex = prevIndex(playersSize, prevPlayerIndex);
      }
      return prevPlayerIndex;
    }
  }

  int nextPlayer([bool doubleCount = false]) {
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
      if (doubleCount) {
        nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
        playerId = playerIds[nextPlayerIndex];
        while (playing.indexWhere((element) => element.id == playerId) == -1) {
          nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
          playerId = playerIds[nextPlayerIndex];
        }
      }
      return nextPlayerIndex;
    } else {
      int nextPlayerIndex = nextIndex(playersSize, currentPlayer);
      if (doubleCount) {
        nextPlayerIndex = nextIndex(playersSize, nextPlayerIndex);
      }
      return nextPlayerIndex;
    }
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

  void startMessageFuture() {
    if (showMessage) return;
    setState(() {
      showMessage = true;
    });
    Future.delayed(const Duration(seconds: 3)).then((value) {
      setState(() {
        showMessage = false;
        message = "";
      });
    });
  }

  Future tenderCards() async {
    int lowestCount = -1;
    List<int> counts = [];
    List<int> playersWhotsCount = [];
    List<int> winners = [];
    bool hasWinner = false;

    for (int i = 0; i < playersWhots.length; i++) {
      final playerWhots = playersWhots[i];
      int count = 0;
      List<String> messages = [];
      if (playerWhots.isEmpty) {
        lowestCount = count;
        counts.add(0);
        playerMessages[i] = "0 card";
        winners.clear();
        winners.add(i);
        hasWinner = true;
        continue;
      }
      playerMessages[i] = "Counting Cards";
      await Future.delayed(const Duration(seconds: 1));
      for (int j = 0; j < playerWhots.length; j++) {
        final whot = playerWhots[j];
        WhotCardShape shape = whotCardShapes[whot.shape];
        int value = 0;
        if (shape == WhotCardShape.star) {
          value = 2 * whot.number;
        } else {
          value = whot.number;
        }
        count += value;

        String message = "${whot.number}${shape.name}($value)";
        messages.add(message);
      }
      counts.add(count);
      playerMessages[i] = "$count cards";
      //playerMessages[i] = "${messages.join("+")} = $count";
      playersWhotsCount.add(count);
      setState(() {});
      if (!hasWinner) {
        if (lowestCount == -1) {
          lowestCount = count;
        } else if (count < lowestCount) {
          lowestCount = count;
          winners.clear();
          winners.add(i);
        } else if (count == lowestCount) {
          winners.add(i);
        }
      }
    }
    counts.sort();
    for (int i = 0; i < playerMessages.length; i++) {
      final message = playerMessages[i];
      final position = counts
          .indexWhere((element) => "$element" == message.split(" ").first);
      playerMessages[i] =
          "${position == 0 ? "1st" : position == 1 ? "2nd" : position == 2 ? "3rd" : "4th"} - $message";
    }
    setState(() {});
    if (winners.isNotEmpty) {
      toastWinner(winners);
      updateWinGame();
    }
  }

  void updateWinGame() {
    pauseGame();
    if (gameId == "") {
      whotIndices = getRandomIndex(54);
    } else {
      if (myId == currentPlayerId) {
        updateDetails(-1, -1, getRandomIndex(54).join(","));
      }
      updateMatchRecord();
    }
    roundsCount++;
    finishedRound = true;
    completedPlayertime = true;
    hintPositions.clear();
    setState(() {});
  }

  void checkWinGame() async {
    if (playersWhots[currentPlayer].isEmpty) {
      if (playersSize > 2) {
        tenderCards();
      } else {
        toastWinner([currentPlayer]);
        updateWinGame();
      }
    }
  }

  void toastDraw() {
    String message = "It's a draw";
    for (int i = 0; i < playersSize; i++) {
      showToast(i, message);
    }
  }

  void toastWinner(List<int> players) {
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
      message = "$name Won";
    } else {
      message = "It's a tie between $name";
    }

    for (int i = 0; i < playersSize; i++) {
      showToast(i, message);
    }
  }

  void resetScores() {
    playersScores = List.generate(playersSize, (index) => 0);
  }

  void addInitialWhots() {
    getCurrentPlayer();
    finishedRound = false;
    needShape = false;
    shapeNeeded = null;
    hintPositions.clear();
    whots.clear();
    playedWhots.clear();
    playersWhots.clear();
    cardVisibilities.clear();
    for (int i = 0; i < playersSize; i++) {
      playerMessages[i] = "";
    }
    cardVisibilities.addAll(
        List.generate(playersSize, (index) => WhotCardVisibility.turned));
    whots.addAll(getWhots());
    whots = whots.arrangeWithStringList(whotIndices);
    shareCards();
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
          if (value.game != whotGame) {
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
      if (newgame != "" && newgame != whotGame) {
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
      detailsSub = fs.getWhotDetails(gameId).listen((details) async {
        if (details != null) {
          final playPos = details.playPos;
          final shapeNeeded = details.shapeNeeded;
          if (playPos != -1) {
            playWhot(playPos);
          } else {
            if (shapeNeeded != -1) {
              playShape(shapeNeeded);
            } else {
              List<String> indices = details.whotIndices == ""
                  ? []
                  : details.whotIndices.split(",");
              if (indices.isNotEmpty && !whotIndices.equals(indices)) {
                whotIndices = indices;
                if (!finishedRound) {
                  completedPlayertime = false;
                  updateNewWhots(indices);
                }
              }
              if (indices.isEmpty) {
                pickWhot();
              }
            }
          }
          completedPlayertime = false;
          setState(() {});
        }
      });
    }
  }

  void updateDetails(int playPos, int shapeNeeded, String whotIndices) {
    if (matchId != "" && gameId != "" && users != null) {
      final details = WhotDetails(
        currentPlayerId: myId,
        playPos: playPos,
        shapeNeeded: shapeNeeded,
        whotIndices: whotIndices,
      );
      fs.setWhotDetails(
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
          whotGame,
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
        resetIfPlayerLeaveGame();
        initDetails();
        addInitialWhots();
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
      resetIfPlayerLeaveGame();
      initDetails();
      resetScores();
      addInitialWhots();
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
      if (newgame == whotGame) {
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

  void flipCards(int index) {
    WhotCardVisibility cardVisibility = cardVisibilities[index];
    if (cardVisibility == WhotCardVisibility.turned) {
      cardVisibilities[index] = WhotCardVisibility.visible;
      getHintPositions();
    } else {
      cardVisibilities[index] = WhotCardVisibility.turned;
      showPossiblePlayPositions();
    }
    setState(() {});
  }

  String getCardVisibilityString(int index) {
    WhotCardVisibility cardVisibility = cardVisibilities[index];
    return "${cardVisibility == WhotCardVisibility.visible ? "Turn" : cardVisibility == WhotCardVisibility.turned ? "Hide" : "Show"} Cards";
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

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if ((key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.escape) &&
          !paused) {
        pauseGame();
      } else if (key == LogicalKeyboardKey.enter && paused) {
        startGame();
      } else if (key == LogicalKeyboardKey.space && !paused) {
        if (gameId != "" && currentPlayerId != myId) {
          showToast(myPlayer, "Its ${getUsername(currentPlayerId)}'s turn");
          return false;
        }
        if (pickCount >= whots.length) {
          getNewWhots();
        } else {
          if (gameId != "") {
            updateDetails(-1, -1, "");
          } else {
            pickWhot();
          }
        }
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
          quarterTurns: gameId != ""
              ? myPlayer == 0
                  ? 2
                  : myPlayer == 1 && playersSize > 2
                      ? 1
                      : myPlayer == 3
                          ? 3
                          : 0
              : 0,
          child: Stack(
            children: [
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
                                        : Colors.black.withOpacity(0.5)),
                              ),
                            ),
                            GameTimer(
                              timerStream: timerController.stream,
                            ),
                          ],
                        ),
                      ),
                    ));
              }),
              ...List.generate(playersSize + 1, (index) {
                bool isEdgeTilt = gameId != "" &&
                    playersSize > 2 &&
                    (myPlayer == 1 || myPlayer == 3);
                final value = isEdgeTilt ? !landScape : landScape;
                if (index == 0) {
                  return Center(
                    child: playedWhots.isEmpty || whots.isEmpty
                        ? null
                        : RotatedBox(
                            quarterTurns: currentPlayer == 0 ||
                                    (playersSize > 2 &&
                                        ((value && currentPlayer == 3) ||
                                            (!value && currentPlayer == 1)))
                                ? 2
                                : 0,
                            child: SizedBox(
                              height: value ? whot_height : minSize,
                              width: value ? minSize : whot_height,
                              child: ColumnOrRow(
                                column: !value,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  RotatedBox(
                                    quarterTurns: currentPlayer == 3 ||
                                            (currentPlayer == 1 &&
                                                playersSize > 2)
                                        ? value
                                            ? 3
                                            : 1
                                        : 0,
                                    child: SizedBox(
                                      height: whot_height,
                                      width: whot_width,
                                    ),
                                  ),
                                  RotatedBox(
                                    quarterTurns: currentPlayer == 3 ||
                                            (currentPlayer == 1 &&
                                                playersSize > 2)
                                        ? value
                                            ? 3
                                            : 1
                                        : 0,
                                    child: Stack(
                                      children: [
                                        WhotCard(
                                          blink: false,
                                          height: whot_height,
                                          width: whot_width,
                                          whot: playedWhots.first,
                                          isBackCard: false,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 4,
                                          child: WhotCountWidget(
                                            count: playedWhots.length,
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            textColor: Colors.black,
                                          ),
                                        ),
                                        if (shapeNeeded != null &&
                                            playedWhots.isNotEmpty &&
                                            playedWhots.first.number == 20) ...[
                                          Positioned(
                                            bottom: 4,
                                            left: 4,
                                            child: WhotCard(
                                              blink: false,
                                              height: whot_width / 2,
                                              width: whot_width / 2,
                                              whot: Whot(
                                                  "", -1, shapeNeeded!.index),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  RotatedBox(
                                    quarterTurns: currentPlayer == 3 ||
                                            (currentPlayer == 1 &&
                                                playersSize > 2)
                                        ? value
                                            ? 3
                                            : 1
                                        : 0,
                                    child: Stack(
                                      children: [
                                        WhotCard(
                                          blink: hintGeneralMarket &&
                                              !needShape &&
                                              firstTime,
                                          height: whot_height,
                                          width: whot_width,
                                          whot: whots.first,
                                          isBackCard: true,
                                          onPressed: () {
                                            if (gameId != "" &&
                                                currentPlayerId != myId) {
                                              showToast(myPlayer,
                                                  "Its ${getUsername(currentPlayerId)}'s turn");
                                              return;
                                            }

                                            if (pickCount >= whots.length) {
                                              getNewWhots();
                                            } else {
                                              if (gameId != "") {
                                                updateDetails(-1, -1, "");
                                              } else {
                                                pickWhot();
                                              }
                                            }
                                          },
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 4,
                                          child: WhotCountWidget(
                                            count: whots.length,
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            textColor: Colors.white,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  );
                } else {
                  index = index - 1;
                  if (playersWhots.isEmpty && index > playersWhots.length - 1) {
                    return Container();
                  }
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
                            // height: whot_width / 2,
                            //     width: ((whot_width / 2) * 5) +
                            //         (whot_width.percentValue(5) * 4),
                            //     alignment: Alignment.center,
                            if (needShape && currentPlayer == index) ...[
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return WhotCard(
                                        blink: firstTime &&
                                            hintPositions.contains(index) &&
                                            !awaiting,
                                        height: whot_width / 2,
                                        width: whot_width / 2,
                                        whot: Whot("", -1, index),
                                        onPressed: () {
                                          if (gameId != "" &&
                                              currentPlayerId != myId) {
                                            showToast(myPlayer,
                                                "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
                                            return;
                                          }
                                          if (gameId != "") {
                                            updateDetails(-1, index, "");
                                          } else {
                                            playShape(index);
                                          }
                                        });
                                  }))
                            ],
                            StreamBuilder<int>(
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: whot_height,
                                  width: minSize,
                                  alignment: Alignment.center,
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      primary:
                                          (gameId != "" && index == myPlayer) ||
                                              (gameId == "" &&
                                                  index == currentPlayer),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: playersWhots[index].length,
                                      itemBuilder: ((context, whotindex) {
                                        final whot =
                                            playersWhots[index][whotindex];
                                        return WhotCard(
                                          blink: firstTime &&
                                              index == currentPlayer &&
                                              hintPositions
                                                  .contains(whotindex) &&
                                              !needShape &&
                                              !awaiting,
                                          key: Key(whot.id),
                                          height: whot_height,
                                          width: whot_width,
                                          whot: whot,
                                          isBackCard: cardVisibilities[index] ==
                                              WhotCardVisibility.turned,
                                          onLongPressed: () {
                                            flipCards(index);
                                          },
                                          onPressed: () {
                                            if (gameId != "" &&
                                                index != myPlayer) {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "You can't flip your opponent's card");
                                              return;
                                            }
                                            if (gameId == "" &&
                                                currentPlayer != index) {
                                              showToast(index,
                                                  "Its ${users != null ? users![currentPlayer]!.username : "Player ${currentPlayer + 1}"}'s turn");
                                              return;
                                            }
                                            if (cardVisibilities[index] ==
                                                WhotCardVisibility.turned) {
                                              cardVisibilities[index] =
                                                  WhotCardVisibility.visible;
                                              getHintPositions();
                                              setState(() {});
                                              return;
                                            }
                                            if (gameId != "" &&
                                                currentPlayerId != myId) {
                                              showToast(myPlayer,
                                                  "Its ${getUsername(currentPlayerId)}'s turn");
                                              return;
                                            }

                                            final currentNumber =
                                                playedWhots.first.number;
                                            if (currentNumber == 14 &&
                                                pickPlayer != -1 &&
                                                pickPlayer != currentPlayer) {
                                              showToast(
                                                  index, "Pick General Market");
                                              return;
                                            }
                                            if (currentNumber == 2 &&
                                                pickPlayer != -1 &&
                                                pickPlayer == currentPlayer) {
                                              showToast(
                                                  index, "Pick 2 From Market");
                                              return;
                                            }
                                            if (gameId != "") {
                                              updateDetails(whotindex, -1, "");
                                            } else {
                                              playWhot(whotindex);
                                            }
                                          },
                                        );
                                      })),
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  users != null
                                      ? users![index]?.username ?? ""
                                      : "Player ${index + 1}",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: currentPlayer == index
                                          ? Colors.blue
                                          : darkMode
                                              ? Colors.white
                                              : Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                                WhotCountWidget(
                                    count: playersWhots[index].length)
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }),
              if (firstTime && !paused && !seenFirstHint) ...[
                RotatedBox(
                  quarterTurns: gameId != ""
                      ? myPlayer == 0
                          ? 2
                          : myPlayer == 1 && playersSize > 2
                              ? 3
                              : myPlayer == 3
                                  ? 1
                                  : 0
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
                            "Tap any card to open\nLong press any card to hide\nPlay a matching card",
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
                  quarterTurns: gameId != ""
                      ? myPlayer == 0
                          ? 2
                          : myPlayer == 1 && playersSize > 2
                              ? 3
                              : myPlayer == 3
                                  ? 1
                                  : 0
                      : 0,
                  child: PausedGamePage(
                    context: context,
                    readAboutGame: readAboutGame,
                    game: "Whot",
                    playersScores: playersScores,
                    users: users,
                    playersSize: playersSize,
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
            ],
          ),
        ),
      ),
    );
  }
}
