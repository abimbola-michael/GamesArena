// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gamesarena/features/game/views/watch_game_controls_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/utils/constants.dart';

import '../../records/models/match_round.dart';
import '../models/concede_or_left.dart';
import '../models/game_action.dart';
import '../providers/game_action_provider.dart';
import '../providers/game_page_provider.dart';
import '../views/paused_game_view.dart';
import '../services.dart';
import '../utils.dart';
import '../../games/card/whot/widgets/whot_card.dart';
import '../../subscription/pages/subscription_page.dart';
import '../../subscription/services/services.dart';
import '../../user/services.dart';
import '../../../main.dart';
import '../../../shared/dialogs/comfirmation_dialog.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/game_timer.dart';
import '../../../theme/colors.dart';

abstract class BaseGamePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? arguments;
  final void Function(GameAction gameAction) onGameActionPressed;
  const BaseGamePage(
    this.arguments,
    this.onGameActionPressed, {
    super.key,
  });

  @override
  ConsumerState<BaseGamePage> createState();
  //State<BaseGamePage> createState() => _BaseGamePageState();
}

abstract class BaseGamePageState<T extends BaseGamePage>
    extends ConsumerState<T>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  void onInitState();
  void onDispose();
  void onInit();
  void onStart();
  void onResume();
  void onPause();
  void onConcede(int index);
  void onLeave(int index);
  void onPlayerTimeEnd();
  void onTimeEnd();
  void onKeyEvent(KeyEvent event);
  void onSpaceBarPressed();
  Future onDetailsChange(Map<String, dynamic>? map);
  void onPlayerChange(int player);
  Widget buildBody(BuildContext context);
  Widget buildBottomOrLeftChild(int index);

  abstract int? maxPlayerTime;
  abstract int? maxGameTime;

  //watch

  int detailDelay = 2000;
  bool seeking = false;

  bool loadingDetails = false;
  bool awaitingDetails = false;

  bool showWatchControls = false;
  int watchDetailIndex = -1;
  int moreWatchDetailIndex = -1;
  int moreWatchDetailParentIndex = -1;
  int controlsVisiblityTimer = 0;
  int maxControlsVisiblityTimer = 5;

  int watchDetailsLimit = 3;
  int durationSkipLimit = 10 * 1000;
  //int watchInterval = 0;
  //int maxWatchInterval = 3;
  bool watching = false;

  int timeStart = 0;
  int watchTime = 0;
  int? timeEnd;

  //match

  int playerTime = 0;
  String gameName = "";
  int pauseIndex = 0;
  bool stopPlayerTime = false;
  bool matchEnded = false;
  bool roundEnded = false;
  bool isOnline = false;

  String matchId = "";
  String gameId = "";
  Match? match;
  List<User?>? users;
  int playersSize = 2;
  String? indices;
  int recordId = 0;
  int roundId = 0;
  int lastRecordId = 0;
  int lastRecordIdRoundId = 0;
  int page = 0;

  //String timeStart = "";

  //Call
  String? callMode;
  bool calling = false;

  StreamSubscription? signalSub;
  bool isAudioOn = true,
      isVideoOn = true,
      isFrontCameraSelected = true,
      isOnSpeaker = false;
  RTCVideoRenderer? _localRenderer;
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, String> videoOverlayVisibility = {};
  //final Map<String, List<RTCIceCandidate>> _rtcIceCandidates = {};
  MediaStream? _localStream;

  //Player
  //bool isWatch = false;
  bool isWatchMode = false;

  //bool finishedReadingDetails = false;

  //Map<String, dynamic>? gatheredGameDetails;
  List<Map<String, dynamic>> gatheredGameDetails = [];

  List<Map<String, dynamic>>? gameDetails;
  // Map<int, List<Map<String, dynamic>>?> recordGameDetails = {};
  Map<int, Map<int, List<Map<String, dynamic>>?>> recordGameDetails = {};

  StreamSubscription? playersSub;
  StreamSubscription? detailsSub;

  int pageIndex = 0;
  int myPageIndex = -1;

  List<Player> players = [];
  List<Player> allPlayers = [];
  List<Player> currentPlayers = [];

  List<List<Player>> tournamentPlayers = [];

  bool firstTime = false, seenFirstHint = false, readAboutGame = false;
  bool changingGame = false;
  bool isCheckoutMode = false;
  String reason = "";
  late StreamController<int> timerController;
  StreamController<int>? timerController2;
  late StreamController<int> watchTimerController;

  //Time
  Timer? timer, watchTimer;
  int duration = 0, gameTime = 0, gameTime2 = 0;

  //Ads
  int adsCount = 0;
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

  //Sizing
  double padding = 0;
  double minSize = 0, maxSize = 0;
  bool landScape = false;

  //Card
  double cardWidth = 0, cardHeight = 0;

  String message = "", hintMessage = "";

  List<int> playersCounts = [];
  List<int> playersScores = [];
  List<int>? winners;
  List<ConcedeOrLeft> concedeOrLeftPlayers = [];

  List<String> playersToasts = [];
  List<String> playersMessages = [];

  bool gottenDependencies = false;
  bool isCard = false;
  bool showMessage = true;
  bool isChessOrDraught = false;
  bool isPuzzle = false;
  bool isQuiz = false;

  //bool notNeedPlayertime = false;
  bool isMyTurn = false;
  bool detailsSent = false;

  final FocusNode _focusNode = FocusNode();
  int availableDuration = 0;
  bool? isSubscribed;
  bool isTournament = false;
  PageController? pageController;

  @override
  void initState() {
    super.initState();
    maxPlayerTime ??= 30;
    resetPlayerTime();

    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    onInitState();
    init();
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
    // if (!gottenDependencies) {
    //   if (context.args != null) {
    //     gameName = context.args["gameName"] ?? "";
    //     matchId = context.args["matchId"] ?? "";
    //     gameId = context.args["gameId"] ?? "";
    //     match = context.args["match"];

    //     users = context.args["users"];
    //     players = context.args["players"] ?? [];
    //     playersSize = context.args["playersSize"] ?? 2;
    //     indices = context.args["indices"];
    //     recordId = context.args["recordId"] ?? 1;
    //     recordGameDetails = context.args["recordGameDetails"] ?? {};
    //     isWatch = context.args["isWatch"] ?? false;
    //     adsTime = context.args["adsTime"] ?? 0;
    //   }
    //   gottenDependencies = true;
    //   init();
    // }
  }

  @override
  void dispose() {
    pageController?.dispose();
    timerController.close();
    timerController2?.close();
    watchTimerController.close();

    WidgetsBinding.instance.removeObserver(this);
    if (!changingGame) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
    detailsSub?.cancel();
    playersSub?.cancel();
    disposeForCall();

    stopTimer();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    onDispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      if (!paused ||
          (gameId.isNotEmpty && getMyPlayer(players)?.action != "pause")) {
        pause();
      }
    }
  }

  void init() {
    if (widget.arguments != null) {
      final arguments = widget.arguments!;
      gameName = arguments["gameName"] ?? "";
      matchId = arguments["matchId"] ?? "";
      gameId = arguments["gameId"] ?? "";
      match = arguments["match"];
      users = arguments["users"];
      players = arguments["players"] ?? [];
      playersSize = arguments["playersSize"] ?? 2;
      indices = arguments["indices"];
      recordId = arguments["recordId"] ?? 0;
      roundId = arguments["roundId"] ?? 0;
      page = arguments["page"] ?? 0;
      recordGameDetails = arguments["recordGameDetails"] ?? {};
      //isWatch = arguments["isWatch"] ?? false;
      adsTime = arguments["adsTime"] ?? 0;
      pageIndex = arguments["pageIndex"] ?? 0;
      playersScores = arguments["playersScores"] ?? [];
      isTournament = arguments["isTournament"] ?? false;
    }
    isOnline = gameId.isEmpty;
    isCard = gameName == "Whot";
    isChessOrDraught = gameName == chessGame || gameName == draughtGame;
    isPuzzle = allPuzzleGames.contains(gameName);
    isQuiz = gameName.endsWith("Quiz");

    isMyTurn = currentPlayerId == myId;

    timerController = StreamController.broadcast();
    if (isChessOrDraught) {
      timerController2 = StreamController.broadcast();
    }
    watchTimerController = StreamController.broadcast();

    matchEnded = match?.time_end != null;
    //recordId = match?.records?.values.length ?? 0;

    checkFirstime();
    checkSubscription();
    //if (playersScores.isEmpty) initScores();
    initMessages();
    initPlayersCounts();
    initToasts();
    getCurrentPlayer();
    readPlayers();
    //if (!isWatch)
    readDetails();
    onStart();
    if (gameId.isEmpty) onInit();
    pauseIndex = gameId.isEmpty
        ? playersSize == 1
            ? 0
            : playersSize == 2
                ? 1
                : 2
        : myPlayer;
    if (maxGameTime != null) {
      gameTime = maxGameTime!;
      gameTime2 = maxGameTime!;
    } else {
      gameTime = 0;
      gameTime2 = 0;
    }
    if (isTournament) {
      pageController = PageController();
    }
  }

  void getOfflineDetails() {
    if (gameId.isEmpty) {}
  }

  bool get isMyMove =>
      !awaiting && gameId.isNotEmpty && currentPlayerId == myId;

  void resetPlayerTime() {
    stopPlayerTime = false;
    playerTime = maxPlayerTime!;
  }

  void stopTimer([bool pause = true]) {
    if (pause) paused = true;

    timer?.cancel();
    timer = null;
    watchTimer?.cancel();
    watchTimer = null;
  }

  void startTimer() {
    pausePlayerTime = false;
    paused = false;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || awaiting) return;

      if (isWatch & isWatchMode && !loadingDetails && watchTime < end) {
        if (showWatchControls) {
          if (controlsVisiblityTimer >= maxControlsVisiblityTimer) {
            controlsVisiblityTimer = 0;
            showWatchControls = false;
            setState(() {});
          } else {
            controlsVisiblityTimer++;
          }
        }
      }
      if (!loadingDetails) duration++;

      if (isSubscribed != null) {
        if (isSubscribed!) {
          if (availableDuration > 0) {
            availableDuration--;
          } else {
            showToast(
                "Your subscription has expired. Please subscribe to continue without ads");
            gotoSubscription();
          }
        }
        if (availableDuration == 0) {
          if (adsTime >= maxAdsTime) {
            loadAd();
            adsTime = 0;
          } else {
            adsTime++;
          }
        }
      }

      if (currentPlayer == 1 && isChessOrDraught) {
        if (maxGameTime != null && gameTime2 <= 0) {
          timer.cancel();
          onTimeEnd();
          updateWin(0);
        }

        gameTime2--;
        timerController2?.sink.add(gameTime2);
      } else {
        if (maxGameTime != null && gameTime <= 0) {
          timer.cancel();
          onTimeEnd();
          if (isChessOrDraught) {
            updateWin(1);
          }
        }
        if (maxGameTime != null) {
          gameTime--;
        } else {
          gameTime++;
        }
        timerController.sink.add(gameTime);
      }
      if (!isChessOrDraught && !stopPlayerTime) {
        if (playerTime <= 0) {
          playerTime = maxPlayerTime!;
          onPlayerTimeEnd();
          setState(() {});
          if (isPuzzle) {
            setGatheredDetails();
          }
        } else {
          playerTime--;
        }
      }
    });

    if (!isWatch || !isWatchMode) return;

    watchTimer?.cancel();
    watchTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted || awaitingDetails) return;

      if (!loadingDetails && watchTime < end) {
        watchTime += 60;
        if (watchTime >= end) {
          watchTime = end;
        }
        watchTimerController.sink.add(watchTime);

        readWatchDetails();
      }
    });
  }

  void checkSubscription() async {
    final duration = await getAvailableDuration();
    isSubscribed = duration.isSubscription;
    availableDuration = duration.duration;
  }

  void gotoSubscription() {
    context.pushTo(const SubscriptionPage());
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;
    final gamePageId = ref.read(gamePageProvider);
    final pageId = "$recordId-$roundId";
    // final pageId =
    //     "${widget.arguments?["recordId"]}-${widget.arguments?["roundId"]}";

    // print(
    //     "gamePageId = $gamePageId, pageId = $pageId, ${pageId == gamePageId}");
    if (pageId != gamePageId) return false;
    if (event is KeyDownEvent) {
      if ((key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.escape) &&
          !paused) {
        if (!finishedRound) {
          pause();
        }
      } else if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space) {
        // print("spance = $isWatchMode, $paused, $finishedRound");
        if (isWatchMode) {
          togglePlayPause();
        } else {
          if (finishedRound) {
            watch();
          } else {
            if (paused) {
              start(false, true);
            } else {
              onSpaceBarPressed();
            }
          }
        }
      } else {
        if (isWatchMode) {
          if (key == LogicalKeyboardKey.arrowLeft) {
            rewind();
          } else if (key == LogicalKeyboardKey.arrowRight) {
            forward();
          } else if (key == LogicalKeyboardKey.arrowUp) {
            nextDetail();
          } else if (key == LogicalKeyboardKey.arrowDown) {
            previousDetail();
          }
        } else {
          onKeyEvent(event);
        }
      }
    }
    return false;
  }

  void getCurrentPlayer() {
    if (gameId != "") {
      final playerIds = players.map((e) => e.id).toList();
      currentPlayerId = isPuzzle || isQuiz ? myId : playerIds.last;
      final currentPlayerIndex =
          playerIds.indexWhere((element) => element == currentPlayerId);
      currentPlayer = currentPlayerIndex;
    } else {
      currentPlayer = playersSize - 1;
    }
  }

  int getPlayerIndex(String playerId) {
    if (gameId != "") {
      //final playerIds = users!.map((e) => e!.user_id).toList();
      final currentPlayerIndex =
          players.indexWhere((element) => element.id == playerId);
      return currentPlayerIndex;
    } else {
      return int.tryParse(playerId) ?? -1;
    }
  }

  void changePlayer({int? player, bool suspend = false}) {
    if (player != null) {
      onPlayerChange(player);

      currentPlayer = player;
      final playerId = getPlayerId(currentPlayer);
      if (playerId != null) {
        currentPlayerId = playerId;
      }

      setState(() {});
      return;
    }
    //setGatheredDetails();
    playerTime = maxPlayerTime!;
    //message = "Play";
    getNextPlayer();
    if (suspend) getNextPlayer();
    setState(() {});
  }

  void resetConcedeOrLeft() {
    // if (gameId.isNotEmpty) {
    //   concedeOrLeftPlayers.removeWhere((element) =>
    //       element.action == "leave" &&
    //       players
    //               .firstWhereNullable((player) => player.id == element.playerId)
    //               ?.matchId ==
    //           matchId);
    // }

    // concedeOrLeftPlayers.removeWhere((element) => element.action == "concede");
    // setState(() {});

    if (concedeOrLeftPlayers.isEmpty) return;
    List<int> newScores = getNewPlayersScores();

    for (int i = 0; i < concedeOrLeftPlayers.length; i++) {
      final concedeOrLeft = concedeOrLeftPlayers[i];
      final playerId = concedeOrLeft.playerId;
      final action = concedeOrLeft.action;
      if (action == "concede") continue;
      users?.removeWhere((element) => element?.user_id == playerId);
      players.removeWhere((element) => element.id == playerId);

      playersSize -= 1;
    }

    playersScores = newScores;
    initPlayersCounts();
    initToasts();
    initMessages();
    if (users != null) {
      final index = users!
          .indexWhere((element) => element != null && element.user_id == myId);
      myPlayer = index;
    }
    concedeOrLeftPlayers.clear();

    setState(() {});
  }

  bool isPlayerActive(int player) {
    return getConcedeOrLeft(player) == null;
  }

  bool isPlayerAvailable(int player) {
    final concedeOrLeft = getConcedeOrLeft(player);
    return concedeOrLeft == null || concedeOrLeft.action == "concede";
  }

  ConcedeOrLeft? getConcedeOrLeft(int player) {
    final index =
        concedeOrLeftPlayers.indexWhere((element) => element.index == player);
    return index != -1 ? concedeOrLeftPlayers[index] : null;
  }

  List<int> getNewPlayersScores() {
    List<int> scores = [];
    int length = gameId.isNotEmpty ? players.length : playersSize;
    for (int i = 0; i < length; i++) {
      if (concedeOrLeftPlayers.indexWhere(
              (element) => element.index == i && element.action == "leave") !=
          -1) {
        continue;
      }
      scores.add(playersScores[i]);
    }
    return scores;
  }

  List<Player> getActivePlayers() {
    List<Player> activePlayers = [];
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      if (concedeOrLeftPlayers
              .indexWhere((element) => element.playerId == player.id) !=
          -1) {
        continue;
      }
      activePlayers.add(player);
    }
    return activePlayers;
  }

  List<Player> getAvailablePlayers() {
    List<Player> availablePlayers = [];
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      if (concedeOrLeftPlayers.indexWhere((element) =>
              element.playerId == player.id && element.action == "leave") !=
          -1) {
        continue;
      }
      availablePlayers.add(player);
    }
    return availablePlayers;
  }

  List<int> getActivePlayersIndices() {
    List<int> playersIndices = [];
    int length = gameId.isNotEmpty ? players.length : playersSize;

    for (int i = 0; i < length; i++) {
      if (concedeOrLeftPlayers.indexWhere((element) => element.index == i) !=
          -1) {
        continue;
      }
      playersIndices.add(i);
    }
    return playersIndices;
  }

  List<int> getAvailablePlayersIndices() {
    List<int> players = [];
    int length = gameId.isNotEmpty ? players.length : playersSize;

    for (int i = 0; i < length; i++) {
      if (concedeOrLeftPlayers.indexWhere(
              (element) => element.index == i && element.action == "leave") !=
          -1) {
        continue;
      }
      players.add(i);
    }
    return players;
  }

  List<String> getPlayersUsernames(List<int> players) {
    return players
        .map((player) => getPlayerUsername(playerIndex: player))
        .toList();
  }

  String getPlayerUsername({String? playerId, int playerIndex = 0}) {
    final index = users?.indexWhere((e) => e?.user_id == playerId) ?? -1;
    return index != -1 ? users![index]!.username : "Player ${playerIndex + 1}";
  }

  int getPrevPlayerIndex([int? playerIndex]) {
    final indices = getActivePlayersIndices();
    if (indices.isEmpty) return -1;
    if (indices.length == 1) return indices.first;
    int index = (playerIndex ?? currentPlayer);
    int length = gameId.isNotEmpty ? players.length : playersSize;
    if (index < 0 || index > length - 1) return -1;
    index = prevIndex(length, index);
    while (indices.indexWhere((element) => element == index) == -1) {
      index = prevIndex(length, index);
    }

    return index;
  }

  int getNextPlayerIndex([int? playerIndex]) {
    final indices = getActivePlayersIndices();

    if (indices.isEmpty) return -1;
    if (indices.length == 1) return indices.first;
    int index = (playerIndex ?? currentPlayer);

    int length = gameId.isNotEmpty ? players.length : playersSize;

    if (index < 0 || index > length - 1) return -1;
    index = nextIndex(length, index);
    while (indices.indexWhere((element) => element == index) == -1) {
      index = nextIndex(length, index);
    }
    return index;
  }

  void getPrevPlayer() {
    final index = getPrevPlayerIndex();
    if (gameId.isNotEmpty) {
      final playerIds = players.map((e) => e.id).toList();
      currentPlayerId = playerIds[index];
    }
    onPlayerChange(index);
    currentPlayer = index;
  }

  void getNextPlayer() {
    final index = isPuzzle || isQuiz ? currentPlayer : getNextPlayerIndex();
    if (gameId.isNotEmpty) {
      final playerIds = players.map((e) => e.id).toList();
      currentPlayerId = playerIds[index];
    }
    onPlayerChange(index);

    currentPlayer = index;
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

  int getCardPartnerPlayer() {
    if (playersSize == 2) return -1;
    return myPlayer == 0
        ? 2
        : myPlayer == 2
            ? 0
            : myPlayer == 1 && playersSize > 2
                ? 3
                : 1;
  }

  // void getFirstPlayer() {
  //   if (gameId != "") {
  //     final playerIds = users!.map((e) => e!.user_id).toList();
  //     currentPlayerId = playerIds.last;
  //     final currentPlayerIndex =
  //         playerIds.indexWhere((element) => element == currentPlayerId);
  //     currentPlayer = currentPlayerIndex;
  //   } else {
  //     currentPlayer = playersSize - 1;
  //   }
  // }

  void updateMyAction(String action) {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1) return;
    players[index] = players[index].copyWith(action: action);
    showToast("You $action${action.endsWith("e") ? "d" : "ed"}");

    final outputAction = executeGameAction();
    if (((maxGameTime != null && gameTime == maxGameTime) ||
            (maxGameTime == null && gameTime == 0) ||
            finishedRound) &&
        (outputAction == "start" || outputAction == "restart")) {
      getCurrentPlayer();
      onInit();
    }
    if (!mounted) return;
    setState(() {});
  }

  void updateMyChangedGame(String game) {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1) return;
    players[index] = players[index].copyWith(game: game, action: "pause");
    showToast("You changed game to $game");
    executeGameChange();
    setState(() {});
  }

  void updateMyCallMode({String? callMode}) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1) return;
    final player = players[index];
    player.callMode = callMode;
    await executeCallAction(players[index]);
    setState(() {});
  }

  void executeGameChange() {
    String newgame = getChangedGame(getAvailablePlayers());
    if (newgame.isEmpty || gameName == newgame) return;
    //recordId++;

    change(newgame, true);
  }

  String executeGameAction() {
    String action = getAction(getAvailablePlayers());
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
    //  else if (action == "concede") {
    //   concede(true);
    // }
    return action;
  }

  Future executeCallAction(Player player, [bool isRemoved = false]) async {
    final myCallMode = getMyCallMode(players);

    if (isRemoved && callMode != null) {
      if (player.id == myId) {
        await _leaveCall();
        callMode = null;
        calling = false;
      } else {
        _disposeForUser(player.id);
        if (players
            .where((element) =>
                element.id != myId && element.callMode == myCallMode)
            .isEmpty) {
          calling = false;
        }
      }
      return;
    }
    if (myCallMode == null) {
      if (callMode != null) {
        await _leaveCall();
        callMode = null;
        calling = false;
      }
    } else {
      if (player.id == myId && player.callMode != null) {
        if (callMode != null && callMode != player.callMode) {
          callMode = player.callMode;
          await updateCallMode(gameId, matchId, callMode);
        } else {
          if (callMode == null) {
            callMode = player.callMode;
            await _startCall();
            final callers = players
                .where((element) =>
                    element.id != myId && element.callMode == player.callMode)
                .toList();

            calling = callers.isNotEmpty;
          }
          //  else {
          //   _toggleCallMode();
          // }
        }
      } else {
        if (player.callMode == myCallMode) {
          //_disposeForUser(player.id);
          sendOffer(player.id);
          calling = true;
        } else {
          if (callMode != null) {
            if (player.callMode == null) {
              _disposeForUser(player.id);
              if (players
                  .where((element) =>
                      element.id != myId && element.callMode == myCallMode)
                  .isEmpty) {
                calling = false;
              }
            }
            // else {
            //   callMode = player.callMode;
            // }
          }
        }
      }
    }
  }

  void checkFirstime() async {
    final name = allQuizGames.contains(gameName) ? "Quiz" : gameName;
    int playTimes = sharedPref.getInt(name) ?? 0;
    if (playTimes < maxHintTime) {
      readAboutGame = playTimes == 0;
      playTimes++;
      sharedPref.setInt(name, playTimes);
      firstTime = true;
    } else {
      firstTime = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future readPlayers() async {
    bool hasEnded = false;

    // if (match != null && match!.time_end != null) {
    //   if (!isWatch &&
    //       match!.recordsCount != null &&
    //       recordId < match!.recordsCount!) {
    //     recordId = match!.recordsCount!;
    //   }
    //   hasEnded = true;
    //   final playersIds = match!.players!;
    //   players = playersIds.map((e) => Player(id: e, time: timeNow)).toList();
    // }

    // if (users == null || users!.length != players.length) {
    //   users = await playersToUsers(players.map((e) => e.id).toList());
    // }

    //recordId = (match!.records?.keys.length ?? 1) - 1;

    if (match?.records?["$recordId"]?["rounds"]?["$roundId"] != null) {
      final record = MatchRecord.fromMap(match!.records?["$recordId"]);
      MatchRound round = MatchRound.fromMap(
          match!.records?["$recordId"]["rounds"]["$roundId"]);
      players = List.generate(
          round.players.length,
          (index) =>
              Player(id: round.players[index], time: timeNow, order: index));
      playersScores = round.scores.toList().cast();
      winners = round.winners;
      hasEnded = round.time_end != null;
    } else {
      initScores();
      if (gameId.isNotEmpty && match != null) {
        if (players.isEmpty) {
          players = List.generate(
              match!.players!.length,
              (index) => Player(
                  id: match!.players![index], time: timeNow, order: index));
        }
      } else {
        players = List.generate(playersSize,
            (index) => Player(id: "$index", time: timeNow, order: index));
      }
    }

    if (gameId.isEmpty || match == null) return;
    players.sortList((player) => player.order, false);

    if (users == null || users!.isEmpty) {
      users = await playersToUsers(players.map((e) => e.id).toList());
    }

    final index = players.indexWhere((element) => element.id == myId);
    myPlayer = index;

    setState(() {});
    if (hasEnded) {
      return;
    }
    final lastTime = players
        .sortedList((player) => player.time_modified, false)
        .lastOrNull
        ?.time_modified;

    final playerIds = players.map((player) => player.id).toList();

    playersSub = getPlayersChange(gameId,
            matchId: matchId, lastTime: lastTime, players: playerIds)
        .listen((playersChanges) async {
      for (int i = 0; i < playersChanges.length; i++) {
        final playersChange = playersChanges[i];
        final value = playersChange.value;

        final playerIndex =
            players.indexWhere((element) => element.id == value.id);
        final userIndex =
            users!.indexWhere((element) => element?.user_id == value.id);
        final username =
            userIndex == -1 ? "" : users![userIndex]?.username ?? "";

        if (playerIndex != -1) {
          if (playersChange.removed) {
            value.game = null;
            value.matchId = null;
          }
          final actionMessage = value.game != null && value.game != gameName
              ? "changed to ${value.game}"
              : players[playerIndex].action != value.action &&
                      (value.action ?? "").isNotEmpty
                  ? value.action ?? ""
                  : "";
          if (actionMessage.isNotEmpty) {
            final title =
                "$username ${value.game != gameName ? actionMessage : "$actionMessage${actionMessage.endsWith("e") ? "d" : "ed"}"}";
            if (value.game != gameName
                ? value.game != getMyPlayer(players)?.game
                : value.action != "pause" &&
                    value.action != "concede" &&
                    value.action != "leave" &&
                    value.action != getMyPlayer(players)?.action) {
              final result = await context.showComfirmationDialog(
                  title: title,
                  message:
                      "Do you also want to ${value.game != gameName ? "change" : value.action!} game?");
              if (result == true) {
                if (value.game != gameName) {
                  change(value.game!);
                } else {
                  if (value.action == "pause") {
                    if (!paused) {
                      pause();
                    }
                  } else if (value.action == "start") {
                    if (paused) {
                      start();
                    }
                  } else if (value.action == "restart") {
                    //recordId++;
                    restart();
                  }
                }
              }
            } else {
              showToast(title);
            }
          }
          if (players[playerIndex].callMode != value.callMode) {
            if (value.callMode != null) {
              final title = "$username started ${value.callMode} call";
              if (value.callMode != getMyPlayer(players)?.callMode) {
                if (!mounted) return;
                final result = await context.showComfirmationDialog(
                    title: title, message: "Do you accept?");
                if (result == true) {
                  await updateCallMode(gameId, matchId, callMode);
                  updateMyCallMode(callMode: value.callMode!);
                }
              } else {
                showToast(title);
              }
            } else {
              final title = "$username ended call";
              showToast(title);
            }
          }

          players[playerIndex] = value;
        } else {
          showToast("$username joined");
          players.add(value);
        }

        if (!mounted) return;
        executeGameAction();
        executeGameChange();
        executeCallAction(value, playersChange.removed);

        setState(() {});

        // if (players.isEmpty ||
        //     players.indexWhere((element) => element.id == myId) == -1) {
        //   context.pop();
        //   return;
        // } else if (players.length == 1 && players.first.id == myId) {
        //   leave();
        //   //context.pop();
        // }
      }
    });
  }

  int get end => (timeEnd ?? timeStart + (duration * 1000));

  Future readWatchDetails(
      {int? time,
      int? detailIndex,
      int? moreDetailIndex,
      int? prevTime,
      int? prevDetailIndex,
      int? prevMoreDetailIndex}) async {
    //trying to match the watch position

    if (time != null || detailIndex != null || moreDetailIndex != null) {
      seeking = true;

      // if ((time != null && prevTime != null && time < prevTime) ||
      //     (detailIndex != null &&
      //         prevDetailIndex != null &&
      //         (detailIndex < prevDetailIndex ||
      //             (moreDetailIndex != null &&
      //                 prevMoreDetailIndex != null &&
      //                 detailIndex == watchDetailIndex &&
      //                 moreDetailIndex < prevMoreDetailIndex)))) {
      //   start(true, true);
      //   watchDetailIndex = 0;
      //   moreWatchDetailIndex = -1;
      //   watchTime = 0;
      // } else {
      //   if (prevTime != null) {
      //     watchTime = prevTime;
      //   }
      //   if (prevDetailIndex != null) {
      //     watchDetailIndex = prevDetailIndex;
      //   }
      //   if (prevMoreDetailIndex != null) {
      //     moreWatchDetailIndex = prevMoreDetailIndex;
      //   }
      // }

      if (detailIndex != null && moreDetailIndex != null) {
        if (watchDetailIndex >= 0 && watchDetailIndex <= detailIndex) {
          while (watchDetailIndex <= detailIndex) {
            final gameDetail = gameDetails![watchDetailIndex];
            print(
                "detailIndex = $detailIndex, moreWatchDetailIndex = $moreWatchDetailIndex");

            final moreDetails =
                gameDetail["moreDetails"] as List<Map<String, dynamic>>?;

            if (moreDetails != null && moreDetails.isNotEmpty) {
              print("Starting");

              if (moreWatchDetailIndex == -1) {
                updateGameDetails(gameDetail);
                watchTime = (gameDetail["time"] as String).toInt;

                if (watchDetailIndex == detailIndex && moreDetailIndex == -1) {
                  break;
                }
                moreWatchDetailIndex = 0;
              } else {
                print("More");

                final moreGameDetail = moreDetails[moreWatchDetailIndex];
                updateGameDetails(moreGameDetail);
                watchTime = (moreGameDetail["time"] as String).toInt;

                if (watchDetailIndex == detailIndex &&
                    moreWatchDetailIndex == moreDetailIndex) {
                  break;
                }

                if (moreWatchDetailIndex == moreDetails.length - 1) {
                  print("isLast");
                  if (watchDetailIndex == detailIndex) {
                    break;
                  }
                  watchDetailIndex++;
                  moreWatchDetailIndex = -1;
                } else {
                  print("Incrementing");

                  moreWatchDetailIndex++;
                }
              }
            } else {
              print("No More");
              updateGameDetails(gameDetail);
              watchTime = (gameDetail["time"] as String).toInt;
              if (watchDetailIndex == detailIndex && moreDetailIndex == -1) {
                break;
              }
              watchDetailIndex++;
              moreWatchDetailIndex = -1;
            }
          }
        }
      } else if (time != null) {
        if (time >= timeStart && time <= end) {
          while (watchDetailIndex < gameDetails!.length) {
            final gameDetail = gameDetails![watchDetailIndex];

            final gameTime = (gameDetail["time"] as String).toInt;
            if (gameTime > time) {
              break;
            }
            final moreDetails =
                gameDetail["moreDetails"] as List<Map<String, dynamic>>?;

            if (moreDetails != null && moreDetails.isNotEmpty) {
              if (moreWatchDetailIndex == -1) {
                updateGameDetails(gameDetail);
                moreWatchDetailIndex = 0;
              } else {
                final moreGameDetail = moreDetails[moreWatchDetailIndex];
                final moreGameTime = (moreGameDetail["time"] as String).toInt;
                if (moreGameTime > time) {
                  break;
                }
                updateGameDetails(moreGameDetail);

                if (moreWatchDetailIndex == moreDetails.length - 1) {
                  watchDetailIndex++;
                  moreWatchDetailIndex = -1;
                } else {
                  moreWatchDetailIndex++;
                }
              }
            } else {
              updateGameDetails(gameDetail);
              watchDetailIndex++;
              moreWatchDetailIndex = -1;
            }

            //watchTime = (gameDetail["time"] as String).toInt;
          }
        }
      }
      seeking = false;
    } else {
      if (gameDetails != null &&
          watchDetailIndex >= 0 &&
          watchDetailIndex < gameDetails!.length) {
        final gameDetail = gameDetails![watchDetailIndex];
        final detailTime = (gameDetail["time"] as String).toInt;
        if (watchTime >= detailTime) {
          final moreDetails =
              gameDetail["moreDetails"] as List<Map<String, dynamic>>?;

          if (moreDetails != null && moreDetails.isNotEmpty) {
            if (moreWatchDetailIndex == -1) {
              updateGameDetails(gameDetail);
              moreWatchDetailIndex = 0;
            } else {
              final moreGameDetail = moreDetails[moreWatchDetailIndex];
              final moreGameTime = (moreGameDetail["time"] as String).toInt;

              if (watchTime >= moreGameTime) {
                updateGameDetails(moreGameDetail);

                if (moreWatchDetailIndex == moreDetails.length - 1) {
                  moreWatchDetailIndex = -1;
                  watchDetailIndex++;
                } else {
                  moreWatchDetailIndex++;
                }
              }
            }
          } else {
            updateGameDetails(gameDetail);
            moreWatchDetailIndex = -1;
            //moreWatchDetailParentIndex = -1;
            watchDetailIndex++;
          }
        }
      }
    }

    if (watchDetailIndex >= gameDetails!.length - watchDetailsLimit &&
        gameId.isNotEmpty &&
        !finishedRound) {
      final playerIds = players.map((player) => player.id).toList();

      var lastTime = gameDetails?.lastOrNull?["time"];

      if (detailIndex != null) {
        if (!loadingDetails) {
          loadingDetails = true;

          setState(() {});
        }
        final remaining = detailIndex - gameDetails!.length - 1;
        final newGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime, limit: remaining, players: playerIds);
        gameDetails!.addAll(newGameDetails);
      } else if (time != null) {
        if (!loadingDetails) {
          loadingDetails = true;

          setState(() {});
        }

        final newGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime, timeEnd: time.toString(), players: playerIds);
        gameDetails!.addAll(newGameDetails);
      }
      if (watchDetailIndex >= gameDetails!.length - watchDetailsLimit) {
        if (!loadingDetails) {
          loadingDetails = true;

          setState(() {});
        }

        lastTime = gameDetails?.lastOrNull?["time"];
        final newGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime, limit: watchDetailsLimit, players: playerIds);
        gameDetails!.addAll(newGameDetails);
      }
    }

    loadingDetails = false;

    if (finishedRound && watchTime >= end) {
      stopWatching();
    } else {
      setState(() {});
    }
  }

  Future readDetails() async {
    if (detailsSub != null) {
      await detailsSub!.cancel();
      detailsSub = null;
    }

    final start =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_start"];

    final end =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_end"];

    if (start != null) {
      timeStart = (start as String).toInt;
    }
    if (end != null) {
      timeEnd = (end as String).toInt;
    }

    finishedRound = end != null;

    final playerIds = players.map((player) => player.id).toList();

    if (!recordGameDetails.containsKey(recordId) ||
        !recordGameDetails[recordId]!.containsKey(roundId)) {
      if (!recordGameDetails.containsKey(recordId)) {
        recordGameDetails[recordId] = {};
      }
      if (!recordGameDetails[recordId]!.containsKey(roundId)) {
        recordGameDetails[recordId]![roundId] = [];
      }
    }

    gameDetails = recordGameDetails[recordId]![roundId];

    int index = 0;
    int endIndex = gameDetails!.length;

    var lastTime = gameDetails?.lastOrNull?["time"];

    if (gameId.isNotEmpty) {
      loadingDetails = true;
      setState(() {});

      final newGameDetails = await getGameDetails(
          gameId, matchId, recordId, roundId,
          time: lastTime,
          limit: isWatch && !finishedRound ? watchDetailsLimit * 2 : null,
          players: playerIds);

      loadingDetails = false;
      gameDetails!.addAll(newGameDetails);
      if (finishedRound) {
        setState(() {});
        return;
      }
      if (newGameDetails.isEmpty) {
        stopWatching();
      } else {
        if (index >= 0 && index < gameDetails!.length) {
          while (index < endIndex) {
            watchDetailIndex = index;

            final gameDetail = gameDetails![index];
            updateGameDetails(gameDetail, readMoreDetails: true);
            index++;
          }
        }
      }

      if (finishedRound) return;
      lastTime = gameDetails?.lastOrNull?["time"];

      detailsSub = getGameDetailsChange(gameId, matchId, recordId, roundId,
              time: lastTime, players: playerIds)
          .listen((detailsChanges) {
        for (int i = 0; i < detailsChanges.length; i++) {
          final detailsChange = detailsChanges[i];
          final gameDetail = detailsChange.value;
          gameDetails ??= [];
          watchDetailIndex = gameDetails!.length;
          gameDetails!.add(gameDetail);
          updateGameDetails(gameDetail, readMoreDetails: true);
        }
        if (finishedRound) {
          detailsSub?.cancel();
          detailsSub = null;
          playersSub?.cancel();
          playersSub = null;
          //stopWatching();
        }
      });
    }
  }

  Future updateGameDetails(Map<String, dynamic> gameDetail,
      {bool readMoreDetails = false}) async {
    final playerId = gameDetail["id"];
    final duration = gameDetail["duration"] as int?;
    final playerTime = gameDetail["playerTime"] as int?;

    final action = gameDetail["action"];

    if (duration != null) {
      if (this.duration < duration) {
        this.duration = duration;
      }
    }

    if (playerTime != null) {
      if (isChessOrDraught) {
        if (getPlayerIndex(playerId) == 1) {
          if ((gameTime2 - playerTime).abs() > 3) {
            gameTime2 = playerTime;
          }
        } else {
          if ((gameTime - playerTime).abs() > 3) {
            gameTime = playerTime;
          }
        }
      } else {
        if ((this.playerTime - playerTime).abs() > 3) {
          this.playerTime = playerTime;
        }
      }
    }

    if (action != null) {
      if (action == "concede") {
        concede(playerId, true);
      } else if (action == "leave") {
        leave(playerId, true);
      }
    } else {
      awaitingDetails = true;
      await onDetailsChange(gameDetail);
      awaitingDetails = false;
    }
    if (readMoreDetails && gameDetail["moreDetails"] != null) {
      final moreDetails = gameDetail["moreDetails"] as List<dynamic>;
      for (int i = 0; i < moreDetails.length; i++) {
        final detail = moreDetails[i];
        //detail["id"] = playerId;
        await updateGameDetails(detail);
      }
    }
  }

  Future setGatheredDetails() async {
    if (gatheredGameDetails.isEmpty || isWatch || finishedRound) return;
    // print("gatheredGameDetails = $gatheredGameDetails");
    Map<String, dynamic> detail;
    if (isPuzzle) {
      detail = gatheredGameDetails.first;
      if (gatheredGameDetails.length > 1) {
        detail["moreDetails"] = gatheredGameDetails.sublist(1);
      }
    } else {
      if (gatheredGameDetails.length > 1) {
        detail = gatheredGameDetails[gatheredGameDetails.length - 2];
        detail["moreDetails"] = [gatheredGameDetails.last];
      } else {
        detail = gatheredGameDetails.first;
      }
    }

    gatheredGameDetails.clear();
    return addDetails(detail);
  }

  Future setActionDetails(String action) async {
    await setGatheredDetails();
    return addDetails({"action": action});
  }

  Future<List<Map<String, dynamic>>> setDetails(
      List<Map<String, dynamic>> details) async {
    List<Map<String, dynamic>> outputDetails = [];
    for (int i = 0; i < details.length; i++) {
      final detail = details[i];
      final outputDetail = await setDetail(detail, i == details.length - 1);
      outputDetails.add(outputDetail);
    }
    return outputDetails;
  }

  Future<Map<String, dynamic>> setDetail(Map<String, dynamic> detail,
      [bool add = true]) async {
    detail["time"] = timeNow;
    detail["duration"] = duration;
    detail["id"] = gameId.isEmpty ? "$currentPlayer" : myId;

    detail["playerTime"] = isChessOrDraught
        ? currentPlayer == 1
            ? gameTime2
            : gameTime
        : playerTime;

    gatheredGameDetails.add(detail.removeNull());
    if (add) {
      setGatheredDetails();
    }
    return detail;
  }

  Future addDetails(Map<String, dynamic> detail) async {
    if (awaiting || !mounted) return {};
    gameDetails ??= [];

    detail["game"] = gameName;
    detail["recordId"] = recordId;
    detail["roundId"] = roundId;
    detail["index"] = gameDetails!.length;

    gameDetails!.add(detail);

    if (gameId.isNotEmpty) {
      awaiting = true;
      await setGameDetails(gameId, matchId, detail);
      awaiting = false;
    }
  }

// Future setActionDetails(String action) async {
  //   if (isPuzzle && gatheredGameDetails != null) {
  //     await setDetail(gatheredGameDetails!);
  //     gatheredGameDetails = null;
  //   }
  //   return setDetail({"action": action});
  // }

  // Future<Map<String, dynamic>> setDetail(Map<String, dynamic> map) async {
  //   if (map.isEmpty) return {};

  //   map["time"] = timeNow;
  //   map["duration"] = duration;

  //   map["playerTime"] = isChessOrDraught
  //       ? currentPlayer == 1
  //           ? gameTime2
  //           : gameTime
  //       : playerTime;

  //   if (isPuzzle && playerTime < maxPlayerTime!) {
  //     if (gatheredGameDetails == null) {
  //       gatheredGameDetails = map;
  //     } else {
  //       if (gatheredGameDetails!["moreDetails"] == null) {
  //         gatheredGameDetails!["moreDetails"] = [map];
  //       } else {
  //         gatheredGameDetails!["moreDetails"].add(map);
  //       }
  //     }
  //     return {};
  //   }
  //   //print("playerTime = $playerTime, map = $map");

  //   if (awaiting || !mounted) return {};
  //   map["game"] = gameName;
  //   map["id"] = gameId.isEmpty ? "$currentPlayer" : myId;
  //   map["recordId"] = recordId;
  //   map["roundId"] = roundId;

  //   gameDetails ??= [];
  //   watchDetailIndex = gameDetails!.length;
  //   gameDetails!.add(map);

  //   if (gameId.isNotEmpty) {
  //     awaiting = true;
  //     await setGameDetails(gameId, matchId, map);
  //     awaiting = false;
  //   }

  //   return map;
  // }

  Future<bool> get allowNextMove async {
    if (!seeking) {
      await Future.delayed(Duration(milliseconds: detailDelay));
      // if (seeked) {
      //   seeked = false;
      //   return false;
      // }
    }
    return true;
  }

  bool itsMyTurnToPlay(bool isClick, [int? player]) {
    if (isClick) toggleLayoutPressed();

    if (seeking) return true;

    if (awaiting || !mounted || (finishedRound && isClick)) {
      return false;
    }

    if (isClick && gameId.isNotEmpty && currentPlayerId != myId) {
      showPlayerToast(myPlayer, "Its ${getUsername(currentPlayerId)}'s turn");
      return false;
    }
    if (player != null && currentPlayer != player) {
      showPlayerToast(player,
          "Its ${getPlayerUsername(playerId: currentPlayerId, playerIndex: currentPlayer)}'s turn");
      return false;
    }
    return true;
  }

  void loadAd() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    if (kIsWeb || !isAndroidAndIos || privateKey == null) {
      return;
    }

    final mobileAdUnit = privateKey!.mobileAdUnit;
    InterstitialAd.load(
        adUnitId: mobileAdUnit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {
                  adsCount++;
                  if (adsCount % 3 == 0 && isSubscribed == false) {
                    gotoSubscription();
                  }
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

  void incrementCount(int player, [int count = 1]) {
    playersCounts[player] += count;
    setState(() {});
  }

  void decrementCount(int player, [int count = 1]) {
    playersCounts[player] -= count;
    setState(() {});
  }

  void updateCount(int player, int count) {
    playersCounts[player] = count;
    setState(() {});
  }

  void setInitialCount(int count) {
    playersCounts = List.generate(playersSize, (index) => count);
  }

  void initPlayersCounts() {
    playersCounts = List.generate(playersSize, (index) => -1);
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

  void showPlayerToast(int playerIndex, String message) {
    if (!isPlayerActive(playerIndex)) return;
    playersToasts[playerIndex] = message;

    setState(() {});
  }

  void showPlayersToast(List<int> indices, String message) {
    for (int i = 0; i < indices.length; i++) {
      final index = indices[i];
      if (!isPlayerActive(index)) continue;
      playersToasts[index] = message;
    }
    setState(() {});
  }

  void showAllPlayersToast(String message) {
    for (int i = 0; i < playersSize; i++) {
      if (!isPlayerActive(i)) continue;
      playersToasts[i] = message;
    }
    setState(() {});
  }

  String getConcedeOrLeftMessage(ConcedeOrLeft concedeOrLeft) {
    return concedeOrLeft.action == "concede" ? "Conceded" : "Left";
  }

  String getMessage(int index) {
    String message = playersMessages[index];
    String fullMessage = "";

    fullMessage = message.isNotEmpty
        ? message
        : currentPlayer == index
            ? "Play"
            : "";
    if (currentPlayer == index) {
      return "$fullMessage - ${playerTime.toDurationString(false)}";
    } else {
      return fullMessage;
    }
  }

  String getPlayerName(int player) {
    return users == null || users!.isEmpty || player >= users!.length
        ? "Player $player"
        : users![player]?.username ?? "";
  }

  void updateWinForPlayerWithHighestCount() {
    final players = getHighestCountPlayer(playersCounts);
    if (players.length == 1) {
      updateWin(players.first,
          reason:
              "${getPlayerName(players.first)} won with ${playersCounts[players.first]} points");
    } else {
      if (players.isEmpty) return;
      if (players.length == playersSize) {
        updateDraw(
            reason: "It's a draw with ${playersCounts[players.first]} points");
      } else {
        updateTie(players,
            reason:
                "${players.map((player) => getPlayerName(player)).join(" and ")} tied with ${playersCounts[players.first]} points");
      }
    }
  }

  void updateTie(List<int> players, {String? reason}) {
    if (players.length == 1) {
      return updateWin(players.first, reason: reason);
    }
    if (players.length == playersSize) {
      return updateDraw(reason: reason);
    }
    reason ??= this.reason;

    updateMatchRound(players, true);

    toastWinners(players, reason: reason);
    pause();
  }

  void updateWin(int player, {String? reason}) {
    reason ??= this.reason;

    updateMatchRound([player], true);

    toastWinner(player, reason: reason);
    pause();
  }

  void updateDraw({String? reason}) {
    reason ??= this.reason;
    updateMatchRound([]);

    toastDraw(reason: reason);
    pause();
  }

  void toastDraw({String? reason}) {
    String message = "It's a draw";
    if (reason != null) {
      message += " with $reason";
    }
    for (int i = 0; i < playersSize; i++) {
      showPlayerToast(i, message);
    }
  }

  void toastWinner(int player, {String? reason}) {
    String message =
        "${users != null ? users![player]?.username ?? "" : "Player $player"} won";
    if (reason != null) {
      message += " with $reason";
    }
    for (int i = 0; i < playersSize; i++) {
      showPlayerToast(i, message);
    }
    // if (isCard) {

    // } else {
    //   showPlayerToast(0, message);
    //   showPlayerToast(1, message);
    // }
  }

  void toastWinners(List<int> players, {String? reason}) {
    String message = "";
    String name = "";
    if (users != null) {
      final usernames = players.map((e) => users![e]!.username).toList();
      name = usernames.toStringWithCommaandAnd((username) => username);
    } else {
      name = players.toStringWithCommaandAnd(
          (players) => "${players + 1}", "Player ");
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
      showPlayerToast(i, message);
    }
  }

  List<int> convertToGrid(int pos, int gridSize) {
    return [pos % gridSize, pos ~/ gridSize];
  }

  int convertToPosition(List<int> grids, int gridSize) {
    return grids[0] + (grids[1] * gridSize);
  }

  String getUsername(String userId) => users == null || users!.isEmpty
      ? ""
      : users
              ?.firstWhereNullable(
                  (element) => element != null && element.user_id == userId)
              ?.username ??
          "";

  Future startOrRestart(bool start) async {
    if (gameId != "" && matchId != "") {
      await updateAction(
          context,
          players,
          users!,
          gameId,
          matchId,
          myId,
          start ? "start" : "restart",
          gameName,
          maxGameTime != null ? gameTime < maxGameTime! : gameTime > 0,
          recordId,
          gameTime);
      // if (!start) {
      //   setActionGameDetails(
      //       gameId, matchId, "restart", gameName, duration, recordId);
      // }
    }
  }

  // void executeWatchAction() {
  //   watchDetailIndex = -1;
  //   watchInterval = 0;
  //   final value = match!.records!["$recordId"];
  //   if (value != null) {
  //     final record = MatchRecord.fromMap(match!.records!["$recordId"]);
  //     if (record.game != gameName) {
  //       change(record.game, true);
  //     } else {
  //       restart(true);
  //     }
  //   }
  // }

  void previous() {
    updateGameAction("previous");
  }

  void next() {
    updateGameAction("next");
  }

  void previousDetail() {
    controlsVisiblityTimer = 0;
    if (gameDetails == null) return;

    if (watchDetailIndex < 0) {
      return;
    }

    int prevWatchDetailIndex = watchDetailIndex;
    int prevMoreWatchDetailIndex = moreWatchDetailIndex;

    final moreDetails = gameDetails![watchDetailIndex]["moreDetails"]
        as List<Map<String, dynamic>>?;

    print(
        "prev start watchDetailIndex = $watchDetailIndex, moreWatchDetailIndex $moreWatchDetailIndex, ${gameDetails![watchDetailIndex]}");

    if (moreDetails != null && moreDetails.isNotEmpty) {
      if (moreWatchDetailIndex == -1) {
        moreWatchDetailIndex = moreDetails.length - 1;
      } else {
        if (moreWatchDetailIndex == 0) {
          if (watchDetailIndex <= 0) {
            return;
          }
          watchDetailIndex--;
          moreWatchDetailIndex = -1;
        } else {
          moreWatchDetailIndex--;
        }
      }
    } else {
      if (watchDetailIndex <= 0) {
        return;
      }
      watchDetailIndex--;
      moreWatchDetailIndex = -1;
    }
    print(
        "prev watchDetailIndex = $watchDetailIndex, moreWatchDetailIndex $moreWatchDetailIndex");
    readWatchDetails(
        detailIndex: watchDetailIndex,
        moreDetailIndex: moreWatchDetailIndex,
        prevDetailIndex: prevWatchDetailIndex,
        prevMoreDetailIndex: prevMoreWatchDetailIndex);

    print(
        "after watchDetailIndex = $watchDetailIndex, moreWatchDetailIndex $moreWatchDetailIndex");
  }

  void nextDetail() {
    controlsVisiblityTimer = 0;

    if (gameDetails == null) return;

    if (watchDetailIndex > gameDetails!.length - 1) {
      stopWatching();
      return;
    }

    int prevWatchDetailIndex = watchDetailIndex;
    int prevMoreWatchDetailIndex = moreWatchDetailIndex;

    final moreDetails = gameDetails![watchDetailIndex]["moreDetails"]
        as List<Map<String, dynamic>>?;

    if (moreDetails != null && moreDetails.isNotEmpty) {
      if (moreWatchDetailIndex == -1) {
        moreWatchDetailIndex = 0;
      } else {
        if (moreWatchDetailIndex == moreDetails.length - 1) {
          if (watchDetailIndex >= gameDetails!.length - 1) {
            stopWatching();
            return;
          }
          watchDetailIndex++;
          moreWatchDetailIndex = -1;
        } else {
          moreWatchDetailIndex++;
        }
      }
    } else {
      if (watchDetailIndex >= gameDetails!.length - 1) {
        stopWatching();
        return;
      }
      watchDetailIndex++;
      moreWatchDetailIndex = -1;
    }
    print(
        "next watchDetailIndex = $watchDetailIndex, moreWatchDetailIndex $moreWatchDetailIndex");

    readWatchDetails(
        detailIndex: watchDetailIndex,
        moreDetailIndex: moreWatchDetailIndex,
        prevDetailIndex: prevWatchDetailIndex,
        prevMoreDetailIndex: prevMoreWatchDetailIndex);
    print(
        "after watchDetailIndex = $watchDetailIndex, moreWatchDetailIndex $moreWatchDetailIndex");
  }

  void rewind() {
    controlsVisiblityTimer = 0;

    int prevWatchTime = watchTime;

    if ((watchTime - durationSkipLimit) < timeStart) {
      watchTime = timeStart;
      return;
    }

    readWatchDetails(time: watchTime, prevTime: prevWatchTime);
    watchTime -= durationSkipLimit;
  }

  void forward() {
    controlsVisiblityTimer = 0;
    if (loadingDetails) return;

    int prevWatchTime = watchTime;

    if (watchTime + durationSkipLimit > end) {
      watchTime = end;
      stopWatching();
      return;
    }

    readWatchDetails(time: watchTime, prevTime: prevWatchTime);
    watchTime += durationSkipLimit;
  }

  void seek(int watchTime) {
    controlsVisiblityTimer = 0;
    if (watchTime < timeStart || (timeEnd != null && watchTime > timeEnd!)) {
      return;
    }
    this.watchTime = watchTime;

    readWatchDetails(time: watchTime, prevTime: this.watchTime);
  }

  void togglePlayPause() {
    controlsVisiblityTimer = 0;
    watching = !watching;
    if (watching) {
      startTimer();
    } else {
      stopTimer(false);
    }
    setState(() {});
  }

  void toggleShowControls() {
    controlsVisiblityTimer = 0;
    showWatchControls = !showWatchControls;
    setState(() {});
  }

  void resetWatchDetails() {
    watchTime = timeStart;
    watchDetailIndex = 0;
    moreWatchDetailIndex = -1;
    moreWatchDetailParentIndex = -1;
    controlsVisiblityTimer = 0;
  }

  void stopWatching() {
    if (!isWatchMode) return;
    resetWatchDetails();
    isWatchMode = false;
    watching = false;
    showWatchControls = false;
    watchTime = 0;
    pause();
  }

  void watch() {
    if (!isWatchMode) {
      start(true, true);
      resetWatchDetails();

      isWatchMode = true;
      watching = true;
      showWatchControls = true;
    }
    startTimer();
    setState(() {});
  }

  void rewatch() {
    isWatchMode = false;
    watch();
  }

  void updateGameAction(String action, {String? game}) {
    widget.onGameActionPressed(GameAction(
        action: action,
        game: game ?? gameName,
        players: players,
        hasDetails: gameDetails?.isNotEmpty ?? false,
        args: widget.arguments ?? {}));
  }

  void pause([bool act = false]) async {
    if (act || gameId == "" || isWatch) {
      stopTimer();
      onPause();
      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        await pauseGame(gameId, matchId, players, recordId, duration);
        updateMyAction("pause");
      }
    }
  }

  void start([bool act = false, bool refresh = false]) async {
    if (act || gameId == "" || isWatch) {
      if (finishedRound && !refresh) {
        updateGameAction("continue");
        return;
      }
      if (!finishedRound) {
        timeStart = timeNow.toInt;
      }
      if (finishedRound || gameTime == 0) {
        reason = "";
        message = "Play";
        duration = 0;
        gameTime = maxGameTime ?? 0;
        playerTime = maxPlayerTime!;
        gatheredGameDetails.clear();
        isCheckoutMode = false;
        timerController.sink.add(gameTime);
        if (isChessOrDraught) {
          gameTime2 = maxGameTime ?? 0;
          timerController2!.sink.add(gameTime);
        }
        updateMatchRecord();
        checkFirstime();
        getCurrentPlayer();
        resetConcedeOrLeft();
        onStart();
        // finishedRound = false;
      } else {
        onResume();
      }

      startTimer();
      if (!mounted) return;

      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        if (paused && getMyPlayer(players)?.action != "pause") {
          pause();
        } else {
          await startOrRestart(true);
          updateMyAction("start");
        }
      }
    }
  }

  void restart([bool act = false]) async {
    if (act || gameId == "" || isWatch) {
      if (!finishedRound) {
        updateMatchRound(null);
      }
      // if (finishedRound) {
      updateGameAction("restart");
      return;
      // }
      // if (isWatch) {
      //   watchInterval = 0;
      //   watchDetailIndex = -1;
      //   finishedRound = true;
      //   // initScores();
      //   // start(act);
      // } else {
      //   finishedRound = true;
      //   //  if (match != null) {
      //   //   updateMatchRecord();
      //   // }

      //   //change(gameName, true);
      // }
      // //recordId++;
      // watchDetailIndex = -1;

      // initScores();
      // start(act);
    } else {
      if (gameId != "" && matchId != "") {
        startOrRestart(false);
        updateMyAction("restart");
      }
    }
  }

  void change(String game, [bool act = false]) async {
    if (act || gameId == "" || isWatch) {
      resetConcedeOrLeft();
      // if (gameId == "") {
      //   recordId++;
      // }
      if (!finishedRound) {
        updateMatchRound(null);
      }

      updateGameAction("change", game: game);
      return;

      // gotoGamePage(context, game, gameId, matchId,
      //     match: match,
      //     users: users,
      //     players: players,
      //     playersSize: users?.length ?? playersSize,
      //     recordGameDetails: recordGameDetails,
      //     // watchDetailIndex: watchDetailIndex,
      //     recordId: recordId,
      //     currentPlayerId: currentPlayerId);
    } else {
      await changeGame(game, gameId, matchId, players, recordId,
          maxGameTime != null ? maxGameTime! - gameTime : gameTime);
      updateMyChangedGame(game);
    }
  }

  void concede([String? playerId, bool act = false]) async {
    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    onConcede(index);

    if (act || gameId == "" || isWatch) {
      concedeOrLeftPlayers.add(ConcedeOrLeft(
          index: index, playerId: playerId, action: "concede", time: gameTime));
      if (index == currentPlayer) {
        changePlayer();
      }
      pauseIndex = currentPlayer;
      final activePlayersCount = getActivePlayersIndices().length;

      // if (activePlayersCount < 2) {
      //   updateWin(getNextPlayerIndex(index));
      // }
      if (activePlayersCount <= 1) {
        context.pop();
        return;
      } else if (activePlayersCount == 2) {
        updateWin(getNextPlayerIndex(index));
      }
      if (gameId.isEmpty) {
        showAllPlayersToast(
            "${getPlayerUsername(playerIndex: index)} conceded");
      } else {
        showToast("${getPlayerUsername(playerId: playerId)} conceded");
      }
      setState(() {});
    } else {
      if (gameId != "" && matchId != "") {
        //await concedeGame(gameId, matchId, players, recordId, duration);

        await setActionDetails("concede");

        updateMyAction("concede");
      }
    }
  }

  void leave([String? playerId, bool endGame = false, bool act = false]) async {
    if (endGame) {
      context.pop();
      return;
    }
    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    onLeave(index);
    if (act || gameId == "" || isWatch) {
      concedeOrLeftPlayers.add(ConcedeOrLeft(
          index: index, playerId: playerId, action: "leave", time: gameTime));
      if (index == currentPlayer) {
        changePlayer();
      }

      pauseIndex = currentPlayer;
      final activePlayersCount = getActivePlayersIndices().length;

      if (activePlayersCount <= 1) {
        context.pop();
        return;
      } else if (activePlayersCount == 2) {
        updateWin(getNextPlayerIndex(index));
      }

      if (gameId.isEmpty) {
        showAllPlayersToast("${getPlayerUsername(playerIndex: index)} left");
      } else {
        showToast("${getPlayerUsername(playerId: playerId)} left");
      }
      setState(() {});

      final availablePlayersCount = getAvailablePlayersIndices().length;
      if (availablePlayersCount <= 1) {
        if (!mounted) return;
        context.pop();
      }
    } else {
      if (gameId != "" && matchId != "") {
        leaveMatch(
            gameId,
            matchId,
            match,
            players,
            maxGameTime != null ? gameTime < maxGameTime! : gameTime > 0,
            recordId,
            maxGameTime != null ? maxGameTime! - gameTime : gameTime);

        setActionDetails("leave");

        if (!mounted) return;
        context.pop();
      }
    }
  }

  void toggleCall(String? callMode, [bool act = false]) async {
    // if (act || gameId == "") {
    // } else {}

    updateMyCallMode(callMode: callMode);
  }

  void toggleCamera() async {
    _switchCamera();
  }

  void toggleMute() async {
    _toggleMic();
  }

  // Future<void> selectAudioOutput(String deviceId) async {
  //   await navigator.mediaDevices
  //       .selectAudioOutput(AudioOutputOptions(deviceId: deviceId));
  // }

  // Future<void> selectAudioInput(String deviceId) =>
  //     NativeAudioManagement.selectAudioInput(deviceId);

  // Future<void> setSpeakerphoneOn(bool enable) =>
  //     NativeAudioManagement.setSpeakerphoneOn(enable);

  void resetUsers() {
    if (gameId != "" && users != null) {
      List<User?> users = this.users!.sortWithStringList(
          players.map((e) => e.id).toList(), (user) => user?.user_id ?? "");
      this.users = users;
    }
  }

  // void updateRecord(List<int> winners) {
  //   if (gameId.isNotEmpty && match != null) {
  //     if (isPuzzle && gatheredGameDetails != null) {
  //       setDetail(gatheredGameDetails!);
  //       gatheredGameDetails = null;
  //     }
  //     Match match = this.match!;
  //     Match prevMatch = match.copyWith();

  //     match.time_start ??= timeStart;
  //     final timeEnd = timeNow;

  //     if (match.recordsCount == null || recordId > match.recordsCount!) {
  //       match.recordsCount = recordId;
  //     }
  //     match.records ??= {};
  //     match.records!["$recordId"] ??= {};

  //     if (match.records!["$recordId"]["$roundId"] == null) {
  //       match.records!["$recordId"]["$roundId"] = MatchRound(
  //               id: roundId,
  //               game: gameName,
  //               time_start: timeStart,
  //               time_end: timeEnd,
  //               players: players.map((e) => e.id).toList(),
  //               scores: playersScores.toMap())
  //           .toMap()
  //           .removeNull();
  //     }

  //     final matchOutcome =
  //         getMatchOutcome(getMatchOverallScores(match), match.players!);

  //     match.outcome = matchOutcome.outcome;
  //     match.winners = matchOutcome.winners;
  //     match.others = matchOutcome.others;

  //     if (gameId.isNotEmpty && !isWatch && currentPlayerId == myId) {
  //       match.time_modified = timeEnd;
  //       updateMatch(gameId, matchId, match,
  //           prevMatch.toMap().getChangedProperties(match.toMap()));
  //     }
  //     // for (int i = 0; i < winners.length; i++) {
  //     //   final playerIndex = winners[i];
  //     //   int score = playersScores[playerIndex];
  //     //   if (match!.records?["$recordId"] != null && !isWatch) {
  //     //     record = MatchRecord.fromMap(match!.records!["$recordId"]!);

  //     //     record.scores["$playerIndex"] = score;
  //     //   }
  //     // }

  //     // if (winners.isNotEmpty && winners.first == myPlayer) {
  //     //   updateScore(gameId, matchId, match!, recordId);
  //     // }
  //     roundId++;
  //   }
  // }

  bool get isWatch {
    if (gameId.isEmpty) {
      return finishedRound;
    }
    if (finishedRound ||
        (players.indexWhere((player) => player.id == myId) == -1)) return true;

    final timeStart =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_start"];
    final timeEnd =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_end"];

    return timeStart != null && timeEnd != null;
  }

  void updateMatchRecord() {
    if (this.match == null || isWatch) return;

    Match match = this.match!;

    Match prevMatch = match.copyWith();

    final time = timeNow;
    match.time_start ??= time;

    // if (match.recordsCount == null || recordId > match.recordsCount!) {
    //   match.recordsCount = recordId + 1;
    // }
    if (match.records!["$recordId"] == null) {
      match.records!["$recordId"] = MatchRecord(
          id: recordId,
          game: gameName,
          time_start: time,
          players: players.map((e) => e.id).toList(),
          scores: playersScores.toMap(),
          rounds: {}).toMap().removeNull();
    }
    if (match.records!["$recordId"]["rounds"]["$roundId"] == null) {
      match.records!["$recordId"]["rounds"]["$roundId"] = MatchRound(
              id: recordId,
              game: gameName,
              time_start: time,
              scores: playersScores.toMap(),
              players: players.map((e) => e.id).toList())
          .toMap()
          .removeNull();
    }

    final matchOutcome =
        getMatchOutcome(getMatchOverallScores(match), match.players!);

    match.outcome = matchOutcome.outcome;
    match.winners = matchOutcome.winners;
    match.others = matchOutcome.others;

    if (gameId.isNotEmpty &&
        !isWatch &&
        ((winners?.isNotEmpty ?? false)
            ? myPlayer == 0
            : myPlayer == winners!.first)) {
      match.time_modified = time;
      updateMatch(gameId, matchId, match,
          prevMatch.toMap().getChangedProperties(match.toMap()));
    }
  }

  void updateMatchRound(List<int>? winners, [bool win = false]) {
    if (finishedRound) return;
    finishedRound = true;

    detailsSub?.cancel();
    detailsSub = null;
    playersSub?.cancel();
    playersSub = null;

    this.winners = winners;
    if (win && winners != null) {
      for (int i = 0; i < winners.length; i++) {
        final player = winners[i];
        playersScores[player]++;
      }
    }

    if (isPuzzle) {
      setGatheredDetails();
    }

    final time = timeNow;
    timeEnd = time.toInt;

    if (this.match == null) {
      setState(() {});

      return;
    }
    Match match = this.match!;

    Match prevMatch = match.copyWith();

    match.time_start ??= time;

    // if (match.recordsCount == null || recordId > match.recordsCount!) {
    //   match.recordsCount = recordId;
    // }
    if (match.records!["$recordId"] != null) {
      match.records!["$recordId"]["scores"] = playersScores.toMap();

      if (match.records!["$recordId"]["rounds"] == null) {
        match.records!["$recordId"]["rounds"] = {};
      }
      if (match.records!["$recordId"]["rounds"]["$roundId"] == null) {
        match.records!["$recordId"]["rounds"]["$roundId"] = MatchRound(
                id: recordId,
                game: gameName,
                time_start: timeStart.toString(),
                time_end: time,
                players: players.map((e) => e.id).toList(),
                winners: winners,
                scores: playersScores.toMap())
            .toMap()
            .removeNull();
      } else {
        match.records!["$recordId"]["rounds"]["$roundId"]["winners"] = winners;
        match.records!["$recordId"]["rounds"]["$roundId"]["time_end"] = time;
      }
      if (winners == null) {
        match.records!["$recordId"]["time_end"] = time;
      }

      final matchOutcome =
          getMatchOutcome(getMatchOverallScores(match), match.players!);

      match.outcome = matchOutcome.outcome;
      match.winners = matchOutcome.winners;
      match.others = matchOutcome.others;

      if (gameId.isNotEmpty &&
          !isWatch &&
          ((winners?.isNotEmpty ?? false)
              ? myPlayer == 0
              : myPlayer == winners!.first)) {
        match.time_modified = time;
        updateMatch(gameId, matchId, match,
            prevMatch.toMap().getChangedProperties(match.toMap()));
      }
    }
  }

  void _listenForSignalingMessages() async {
    if (signalSub != null) return;
    //await signalSub?.cancel();
    signalSub = streamChangeSignals(gameId, matchId).listen((signalsChanges) {
      for (int i = 0; i < signalsChanges.length; i++) {
        final signalChange = signalsChanges[i];
        final data = signalChange.value;
        final type = data["type"];
        final id = data["id"];
        //print("signalChange = $signalChange");

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
          }
        } else if (signalChange.removed) {
          _disposeForUser(id);
        }
      }
    });
  }

  void disposeForCall([bool disposeWithSignal = true]) async {
    if (disposeWithSignal) {
      signalSub?.cancel();
    }

    _localRenderer?.dispose();
    videoOverlayVisibility.remove(myId);
    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    for (var pc in _peerConnections.values) {
      pc.dispose();
    }
    _localStream?.dispose();

    _remoteRenderers.clear();
    _peerConnections.clear();
    videoOverlayVisibility.clear();
    signalSub = null;
    _localStream = null;
    _localRenderer = null;
  }

  void _disposeForUser(String peerId) async {
    _remoteRenderers[peerId]?.dispose();
    _peerConnections[peerId]?.dispose();
    _remoteRenderers.remove(peerId);
    _peerConnections.remove(peerId);
    videoOverlayVisibility.remove(peerId);

    if (_peerConnections.isEmpty) {
      signalSub?.cancel();
      _localRenderer?.dispose();
      videoOverlayVisibility.remove(myId);
      _localStream?.dispose();
      signalSub = null;
      _localStream = null;
      _localRenderer = null;
    }
  }

  Future initForCall() async {
    await _initializeLocalStream();
  }

  Future<void> _initializeLocalRenderer() async {
    if (_localRenderer != null) return;
    _localRenderer = RTCVideoRenderer();
    videoOverlayVisibility[myId] = "show";
    await _localRenderer?.initialize();
  }

  Future<void> _initializeLocalStream() async {
    isVideoOn = callMode == "video";

    if (_localStream != null &&
        ((_localRenderer != null && isVideoOn) ||
            (_localRenderer == null && !isVideoOn))) {
      return;
    }
    await _localStream?.dispose();
    //print("newisAudioOn = $isAudioOn");
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {
              'mandatory': {
                'minWidth': '640', // Adjust as needed
                'minHeight': '480', // Adjust as needed
                'minFrameRate': '15',
                'maxFrameRate': '30',
              },
              'facingMode': isFrontCameraSelected ? 'user' : 'environment',
              'optional': [],
            }
          //? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });
    if (isVideoOn) {
      await _initializeLocalRenderer();
    } else {
      if (_localRenderer != null) {
        _localRenderer!.dispose();
        _localRenderer = null;
        videoOverlayVisibility.remove(myId);
      }
    }
    _localRenderer?.srcObject = _localStream;
    setState(() {});
  }

  Future<void> _createPeerConnection(String peerId) async {
    await initForCall();
    if (_peerConnections[peerId] != null &&
        ((_remoteRenderers[peerId] != null && isVideoOn) ||
            (_remoteRenderers[peerId] == null && !isVideoOn))) return;

    await _peerConnections[peerId]?.dispose();

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

    pc.onTrack = (event) async {
      if (event.track.kind == 'video') {
        if (!_remoteRenderers.containsKey(peerId)) {
          var renderer = RTCVideoRenderer();
          _remoteRenderers[peerId] = renderer;
          videoOverlayVisibility[peerId] = "faint";
          await _remoteRenderers[peerId]?.initialize();
        }
        _remoteRenderers[peerId]?.srcObject = event.streams[0];
        setState(() {});
      } else {
        if (_remoteRenderers.containsKey(peerId)) {
          _remoteRenderers[peerId]?.dispose();
          _remoteRenderers.remove(peerId);
          videoOverlayVisibility.remove(peerId);
          setState(() {});
        }
      }
    };

    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });
    setState(() {});
  }

  String _setMediaBitrate(String sdp, {int? audioBitrate, int? videoBitrate}) {
    var lines = sdp.split('\n');
    var newSdp = <String>[];

    bool videoBitrateSet = false;
    bool audioBitrateSet = false;

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('m=video')) {
        newSdp.add(lines[i]);
        videoBitrateSet = true;
      } else if (lines[i].startsWith('m=audio')) {
        newSdp.add(lines[i]);
        audioBitrateSet = true;
      } else if (lines[i].startsWith('b=AS:') && lines[i].contains('video')) {
        // Skip existing video bitrate line to avoid duplication
        videoBitrateSet = false;
      } else if (lines[i].startsWith('b=AS:') && lines[i].contains('audio')) {
        // Skip existing audio bitrate line to avoid duplication
        audioBitrateSet = false;
      } else {
        newSdp.add(lines[i]);
      }
    }

    // Add or update bitrate lines
    if (videoBitrateSet) {
      newSdp.add('b=AS:${videoBitrate ?? 1000}'); // Add video bitrate line
    }
    if (audioBitrateSet) {
      newSdp.add('b=AS:${audioBitrate ?? 64}'); // Add audio bitrate line
    }

    return newSdp.join('\n');
  }

  Future _startCall() async {
    if (gameId == "") return;
    await startCall(gameId, callMode!);
    _listenForSignalingMessages();
  }

  _leaveCall() async {
    await endCall(gameId);
    await removeSignal(gameId, matchId, myId);
    disposeForCall();
    //context.pop();
  }

  _toggleMic() async {
    isAudioOn = !isAudioOn;

    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
    updateCallAudio(gameId, matchId, isAudioOn);
  }

  // _toggleCallMode() {
  //   isVideoOn = !isVideoOn;
  //   _localStream?.getVideoTracks().forEach((track) {
  //     track.enabled = isVideoOn;
  //   });
  //   setState(() {});
  // }

  _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    _localStream?.getVideoTracks().forEach((track) {
      // // ignore: deprecated_member_use
      // track.switchCamera();
      Helper.switchCamera(track);
    });
    setState(() {});
    updateCallCamera(gameId, matchId, isFrontCameraSelected);
  }

  toggleSpeaker() async {
    isOnSpeaker = !isOnSpeaker;
    await Helper.setSpeakerphoneOn(isOnSpeaker);
    setState(() {});
  }

  toggleVideoOverlayVisibility(String? userId) {
    if (userId == null) return;
    final visibility = videoOverlayVisibility[userId];
    switch (visibility) {
      case "show":
        videoOverlayVisibility[userId] = "faint";
        break;
      case "faint":
        videoOverlayVisibility[userId] = "hide";
        break;
      case "hide":
        videoOverlayVisibility[userId] = "show";
        break;
    }
    setState(() {});
  }

  double getOverlayOpacity(int index) {
    final concedeOrLeft = getConcedeOrLeft(index);
    double opacity = concedeOrLeft != null ? 0.3 : 1;

    final userId = getPlayerId(index);
    if (userId == null) return opacity;

    final visibility = videoOverlayVisibility[userId];
    switch (visibility) {
      case "show":
        return opacity;
      case "faint":
        return concedeOrLeft != null ? 0.3 : 0.5;
      case "hide":
        return 0;
    }
    return opacity;
  }

  Future sendIceCandidates(String peerId) async {
    await _createPeerConnection(peerId);
    final pc = _peerConnections[peerId]!;
    pc.onIceCandidate = (candidate) {
      addSignal(gameId, matchId, peerId,
          {'type': 'candidate', 'candidate': candidate.toMap()});
    };
  }

  Future sendOffer(String peerId) async {
    //_listenForSignalingMessages();
    bool justCreating = _peerConnections[peerId] == null;

    await _createPeerConnection(peerId);
    final pc = _peerConnections[peerId]!;

    var offer = await pc.createOffer();
    //RTCSessionDescription offer = await pc.createOffer();
    //offer.sdp = _setMediaBitrate(offer.sdp!, videoBitrate: 500); // 500 kbps

    await pc.setLocalDescription(offer);
    await addSignal(
        gameId, matchId, peerId, {'type': 'offer', 'sdp': offer.sdp});
    if (justCreating) {
      sendIceCandidates(peerId);
    }
  }

  Future sendAnswer(String peerId, String sdp) async {
    //_listenForSignalingMessages();
    bool justCreating = _peerConnections[peerId] == null;

    await _createPeerConnection(peerId);

    final pc = _peerConnections[peerId]!;

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    var answer = await pc.createAnswer();
    //RTCSessionDescription answer = await pc.createAnswer();
    //answer.sdp = _setMediaBitrate(answer.sdp!, videoBitrate: 500); // 500 kbps
    await pc.setLocalDescription(answer);

    await addSignal(
        gameId, matchId, peerId, {'type': 'answer', 'sdp': answer.sdp});

    if (justCreating) {
      sendIceCandidates(peerId);

      await sendOffer(peerId);
    }
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    await sendAnswer(peerId, sdp);
  }

  Future<void> _handleAnswer(String peerId, String sdp) async {
    await _createPeerConnection(peerId);
    final pc = _peerConnections[peerId]!;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> _handleCandidate(
      String peerId, Map<String, dynamic> candidate) async {
    await _createPeerConnection(peerId);
    final pc = _peerConnections[peerId]!;
    var rtcCandidate = RTCIceCandidate(candidate['candidate'],
        candidate['sdpMid'], candidate['sdpMLineIndex']);
    await pc.addCandidate(rtcCandidate);
  }

  Widget getPlayerBottomWidget(int index) {
    final concedeOrLeft = getConcedeOrLeft(index);
    final user = users != null && index < users!.length ? users![index] : null;
    final profilePhoto = user?.profile_photo;
    return IgnorePointer(
      ignoring: concedeOrLeft != null &&
          concedeOrLeft.action == "leave" &&
          !finishedRound,
      child: RotatedBox(
        quarterTurns: getStraightTurn(index),
        child: GestureDetector(
          onTap: () {
            if (finishedRound) {
              changePlayer(player: index);
            }
          },
          child: Row(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: Row(
                  // mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: profilePhoto != null
                          ? CachedNetworkImageProvider(profilePhoto)
                          : null,
                      backgroundColor: lightestWhite,
                      child: profilePhoto != null
                          ? null
                          : Text(
                              user?.username.firstChar ?? "P",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.blue),
                            ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        user?.username ?? "Player ${index + 1}",
                        style: TextStyle(
                            fontSize: 14,
                            color: currentPlayer == index ? Colors.blue : tint),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (playersCounts.isNotEmpty &&
                        index < playersCounts.length &&
                        playersCounts[index] != -1)
                      CountWidget(count: playersCounts[index])
                  ],
                ),
              ),
              if (gameId.isEmpty || index == myPlayer)
                IconButton(
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(2),
                  ),
                  onPressed: () {
                    pauseIndex = index;
                    if (isCheckoutMode) {
                      isCheckoutMode = false;
                    } else if (!paused) {
                      pause();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    EvaIcons.menu_outline,
                    color: tint,
                  ),
                )
              else
                const SizedBox(
                  width: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  int getPausedGameTurn() {
    if (gameId != "" || playersSize == 1) return 0;

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

  int getLayoutTurn() {
    if (playersSize == 1) return 2;
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
        : (gameId != "" &&
                (myPlayer == 0 || (myPlayer == 1 && playersSize > 2)))
            ? 2
            : 0;
  }

  int getOppositeLayoutTurn() {
    final layoutTurn = getLayoutTurn();
    return layoutTurn == 1
        ? 3
        : layoutTurn == 3
            ? 1
            : layoutTurn;
  }

  int getStraightTurn(int index) {
    if (gameId.isEmpty || index == myPlayer) return 0;
    if (playersSize == 2) return 2;

    if (isCard) {
      final partner = getCardPartnerPlayer();
      if (index == partner) return 2;
      return 0;
    } else {
      if (index == getPartnerPlayer()) return 0;
      return 2;
    }
  }

  int getVideoViewTurn(int index) {
    if (gameId.isEmpty || index == myPlayer) return 0;
    if (playersSize == 2) return 2;

    if (isCard) {
      final partner = getCardPartnerPlayer();
      if (index == partner) return 2;
      final prevPlayer = getPrevPlayerIndex(myPlayer);
      return index == prevPlayer ? 1 : 3;
    } else {
      if (index == getPartnerPlayer()) return 0;
      return 2;
    }
  }

  String getFirstHint() {
    String hint = "";
    if (gameName.endsWith("Quiz")) {
      return "Tap on any option that you think is the answer to the question\nSubmit if you are sure to be done\nSelected answer would be automatically submited on timeout";
    }
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

  bool getIsPlaying(int index) {
    return players.isNotEmpty &&
        players.indexWhere((element) => element.id == myId) != -1;
  }

  String? getPlayerId(int index) {
    return index < players.length ? players[index].id : null;
  }

  Player? getPlayer(int index) {
    return index < players.length ? players[index] : null;
  }

  Widget? buildVideoView(int index) {
    if (gameId.isEmpty || players.isEmpty) return null;
    final playerId = getPlayerId(index);
    if (playerId == null ||
        (playerId == myId && _localRenderer == null) ||
        (playerId != myId && _remoteRenderers[playerId] == null)) {
      return null;
    }
    return RotatedBox(
      quarterTurns: getVideoViewTurn(index),
      child: RTCVideoView(
        playerId == myId ? _localRenderer! : _remoteRenderers[playerId]!,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: playerId == myId && isFrontCameraSelected,
      ),
    );
  }

  void toggleLayoutPressed() {
    if (isCheckoutMode) {
      setState(() {
        isCheckoutMode = false;
      });
    }
    if (isWatchMode && !showWatchControls) {
      showWatchControls = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //print("details = $gameDetails");
    //print("${widget.arguments?["recordId"]}-${widget.arguments?["roundId"]}");
    //print("recordId = $recordId, roundId = $roundId");
    // print(
    //     "currentPlayer = $currentPlayer, detailPlayer = ${gameDetails == null || watchDetailIndex < 0 || watchDetailIndex > gameDetails!.length - 1 ? "" : gameDetails![watchDetailIndex]}");
    //print("timeStart = $timeStart, timeEnd = $timeEnd, watchTime = $watchTime");
    // print(
    //     "showWatchControls = $showWatchControls, isWatchMode = $isWatchMode, isCheckoutMode = $isCheckoutMode");

    // watchTime = timeStart;

    // timeEnd = timeNow.toInt;
    // finishedRound = true;

    // print(
    //     "currentPlayer = $currentPlayer, currentPlayerId = $currentPlayerId, myId = $myId");
    //print("details = $gameDetails");
    // print(
    //     "lastRecordId = $lastRecordId, lastRecordIdRoundId = $lastRecordIdRoundId");
    double padding = (context.screenHeight - context.screenWidth).abs() / 2;
    bool landScape = context.isLandscape;
    double minSize = context.minSize;

    return PopScope(
      canPop: false,
      onPopInvoked: (pop) async {
        if (isCheckoutMode) {
          setState(() {
            isCheckoutMode = false;
          });
        } else if (!paused) {
          pause();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          body: Stack(
            alignment: Alignment.center,
            children: [
              RotatedBox(
                quarterTurns: getLayoutTurn(),
                child: Stack(
                  children: [
                    if (isCard) ...[
                      ...List.generate(playersSize, (index) {
                        final videoView = buildVideoView(index);
                        final concedeOrLeft = getConcedeOrLeft(index);
                        return Positioned(
                          top: index == 0 ||
                                  ((index == 1 || index == 3) &&
                                      playersSize > 2)
                              ? 0
                              : null,
                          bottom: index != 0 ? 0 : null,
                          left: playersSize > 2 && index == 1 ? null : 0,
                          right: index < 3 ? 0 : null,
                          child: RotatedBox(
                            quarterTurns: getTurn(index),
                            child: Opacity(
                              opacity: getOverlayOpacity(index),
                              child: Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RotatedBox(
                                      quarterTurns: getStraightTurn(index),
                                      child: StreamBuilder<int>(
                                          stream: currentPlayer == index
                                              ? timerController.stream
                                              : null,
                                          builder: (context, snapshot) {
                                            return Text(
                                              concedeOrLeft != null
                                                  ? getConcedeOrLeftMessage(
                                                      concedeOrLeft)
                                                  : getMessage(index),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: darkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            );
                                          }),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        toggleVideoOverlayVisibility(
                                            getPlayerId(index));
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (videoView != null) videoView,
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
                                                                    playersSize >
                                                                        2) ||
                                                                (index == 1 &&
                                                                    playersSize ==
                                                                        2)))
                                                    ? 30
                                                    : 8),
                                            child: IgnorePointer(
                                                ignoring:
                                                    concedeOrLeft != null &&
                                                        !finishedRound,
                                                child: buildBottomOrLeftChild(
                                                    index)),
                                          ),
                                          if (concedeOrLeft == null &&
                                              index < playersToasts.length &&
                                              playersToasts[index] != "") ...[
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: RotatedBox(
                                                quarterTurns:
                                                    getStraightTurn(index),
                                                child: AppToast(
                                                  message: playersToasts[index],
                                                  onComplete: () {
                                                    playersToasts[index] = "";
                                                    setState(() {});
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      ...List.generate(playersSize, (index) {
                        final mindex = (playersSize / 2).ceil();
                        bool isEdgeTilt = gameId != "" &&
                            playersSize > 2 &&
                            (myPlayer == 1 || myPlayer == 3);
                        final value = isEdgeTilt ? !landScape : landScape;
                        final concedeOrLeft = getConcedeOrLeft(index);
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
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0, bottom: 24),
                                  child: Opacity(
                                    opacity: getOverlayOpacity(index),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RotatedBox(
                                          quarterTurns: getStraightTurn(index),
                                          child: SizedBox(
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
                                            ),
                                          ),
                                        ),
                                        RotatedBox(
                                          quarterTurns: getStraightTurn(index),
                                          child: GameTimer(
                                            timerStream: index == 1 &&
                                                    isChessOrDraught &&
                                                    timerController2 != null
                                                ? timerController2!.stream
                                                : timerController.stream,
                                            time: concedeOrLeft?.time,
                                          ),
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
                          left: index == 3 || (landScape && index == 0)
                              ? 0
                              : null,
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
                              child: Opacity(
                                  opacity: getOverlayOpacity(index),
                                  child: getPlayerBottomWidget(index)),
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      ...List.generate(
                        playersSize,
                        (index) {
                          final mindex = (playersSize / 2).ceil();
                          final videoView = buildVideoView(index);
                          final concedeOrLeft = getConcedeOrLeft(index);
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
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      toggleVideoOverlayVisibility(
                                          getPlayerId(index));
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (videoView != null) videoView,
                                        Opacity(
                                          opacity: getOverlayOpacity(index),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  RotatedBox(
                                                    quarterTurns:
                                                        getStraightTurn(index),
                                                    child: SizedBox(
                                                      height: 70,
                                                      child: Text(
                                                        '${playersScores[index]}',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 60,
                                                            color: lighterTint),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                  RotatedBox(
                                                    quarterTurns:
                                                        getStraightTurn(index),
                                                    child: GameTimer(
                                                      timerStream: index == 1 &&
                                                              isChessOrDraught &&
                                                              timerController2 !=
                                                                  null
                                                          ? timerController2!
                                                              .stream
                                                          : timerController
                                                              .stream,
                                                      time: concedeOrLeft?.time,
                                                    ),
                                                  ),
                                                  if ((currentPlayer == index &&
                                                          showMessage) ||
                                                      concedeOrLeft !=
                                                          null) ...[
                                                    const SizedBox(height: 4),
                                                    RotatedBox(
                                                      quarterTurns:
                                                          getStraightTurn(
                                                              index),
                                                      child: StreamBuilder<int>(
                                                          stream:
                                                              timerController
                                                                  .stream,
                                                          builder: (context,
                                                              snapshot) {
                                                            return Text(
                                                              concedeOrLeft !=
                                                                      null
                                                                  ? getConcedeOrLeftMessage(
                                                                      concedeOrLeft)
                                                                  : isChessOrDraught
                                                                      ? "Play"
                                                                      : "Play - ${playerTime.toDurationString(false)}",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color: tint),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          }),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Expanded(
                                                child: IgnorePointer(
                                                  ignoring:
                                                      concedeOrLeft != null &&
                                                          !finishedRound,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20),
                                                    child:
                                                        buildBottomOrLeftChild(
                                                            index),
                                                  ),
                                                ),
                                              ),
                                              getPlayerBottomWidget(index),
                                            ],
                                          ),
                                        ),
                                        if (playersToasts[index] != "") ...[
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: RotatedBox(
                                              quarterTurns:
                                                  getStraightTurn(index),
                                              child: AppToast(
                                                message: playersToasts[index],
                                                onComplete: () {
                                                  playersToasts[index] = "";
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ));
                        },
                      ),
                    ],
                    GestureDetector(
                        behavior: isWatch ? HitTestBehavior.opaque : null,
                        onTap: isWatch ? toggleLayoutPressed : null,
                        child: buildBody(context)),
                  ],
                ),
              ),
              if (!paused &&
                  isWatchMode &&
                  !isCheckoutMode &&
                  showWatchControls)
                WatchGameControlsView(
                  watchTimerController: watchTimerController,
                  showWatchControls: showWatchControls,
                  playersSize: playersSize,
                  watchTime: watchTime,
                  timeStart: timeStart,
                  timeEnd: end,
                  duration: duration,
                  onPrevious: previousDetail,
                  onNext: nextDetail,
                  onRewind: rewind,
                  onForward: forward,
                  onPlayPause: togglePlayPause,
                  onSeek: seek,
                  watching: watching,
                  loadingDetails: loadingDetails,
                  onPressed: toggleShowControls,
                ),
              if (loadingDetails)
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.5), strokeWidth: 2),
                ),
              if (paused && !isCheckoutMode && pauseIndex != -1)
                RotatedBox(
                  quarterTurns: getPausedGameTurn(),
                  child: PausedGameView(
                    context: context,
                    reason: reason,
                    readAboutGame: readAboutGame,
                    game: gameName,
                    match: match,
                    recordId: recordId,
                    roundId: roundId,
                    playersScores: playersScores,
                    users: users,
                    players: players,
                    playersSize: playersSize,
                    finishedRound: finishedRound,
                    startingRound: maxGameTime != null
                        ? gameTime == maxGameTime
                        : gameTime == 0,
                    hasPlayedForAMinute: maxGameTime != null
                        ? gameTime <= maxGameTime! - 60
                        : gameTime >= 60,
                    gameId: gameId,
                    isWatching: isWatchMode,
                    isWatch: isWatch,
                    isFirstPage: recordId == 0 && roundId == 0,
                    isLastPage: recordId == lastRecordId &&
                        roundId == lastRecordIdRoundId,
                    onWatch: watch,
                    onRewatch: rewatch,
                    onStart: start,
                    onRestart: restart,
                    onChange: change,
                    onLeave: (end) => leave(null, end),
                    onConcede: concede,
                    onPrevious: previous,
                    onNext: next,
                    onCheckOut: () {
                      setState(() {
                        isCheckoutMode = true;
                      });
                    },
                    onReadAboutGame: () {
                      if (readAboutGame) {
                        setState(() {
                          readAboutGame = false;
                        });
                      }
                    },
                    callMode: callMode,
                    onToggleCall: toggleCall,
                    isFrontCamera: isFrontCameraSelected,
                    onToggleCamera: toggleCamera,
                    isAudioOn: isAudioOn,
                    onToggleMute: toggleMute,
                    isSpeakerOn: isOnSpeaker,
                    onToggleSpeaker: toggleSpeaker,
                    quarterTurns: getPausedGameTurn(),
                    pauseIndex: pauseIndex,
                    concedeOrLeftPlayers: concedeOrLeftPlayers,
                    winners: winners,
                    duration: duration,
                    watchTime: watchTime,
                    timeStart: timeStart,
                    timeEnd: (timeEnd ?? timeStart + (duration * 1000)),
                  ),
                ),
              if (firstTime && !paused && !seenFirstHint) ...[
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: lighterBlack,
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        getFirstHint(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        seenFirstHint = true;
                      });
                    },
                  ),
                )
              ],
              // if (isCheckoutMode)
              //   Text(
              //     "Press back to Exit Checkout Mode",
              //     style: context.bodySmall,
              //   )
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
