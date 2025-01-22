// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gamesarena/features/game/views/watch_game_controls_view.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/utils/constants.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../shared/utils/call_utils.dart';
import '../../match/providers/gamelist_provider.dart';
import '../../records/models/match_round.dart';
import '../models/exempt_player.dart';
import '../models/game_action.dart';
import '../models/game_page_infos.dart';
import '../providers/game_page_infos_provider.dart';
import '../../match/providers/match_provider.dart';
import '../views/paused_game_view.dart';
import '../services.dart';
import '../utils.dart';
import '../../games/card/whot/widgets/whot_card.dart';
import '../../subscription/pages/subscription_page.dart';
import '../../subscription/services/services.dart';
import '../../user/services.dart';
import '../../../main.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/game_timer.dart';
import '../../../theme/colors.dart';

abstract class BaseGamePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? arguments;
  final CallUtils gameCallUtils;
  final void Function(GameAction gameAction) onGameActionPressed;
  const BaseGamePage(
    this.arguments,
    this.gameCallUtils,
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

  // int availablePlayersCount = 0;

  final Connectivity _connectivity = Connectivity();

  bool isVisible = true;
  bool isConnectedToInternet = true;
  bool alertShown = false;

  //watch

  int detailDelay = 2000;
  bool seeking = false;

  bool loadingDetails = false;
  bool awaitingDetails = false;

  bool showWatchControls = false;
  int gameDetailsLength = 0;

  int detailIndex = -1;
  int moreDetailIndex = -1;

  int? newDetailIndex;
  int? newMoreDetailIndex;

  double? newDuration;
  double endDuration = 0.0;

  int nextwatchPosition = 0;

  int controlsVisiblityTimer = 0;
  int maxControlsVisiblityTimer = 5;

  int watchDetailsLimit = 3;
  int durationSkipLimit = 10;

  bool watching = false;

  //match

  int playerWaitingTime = 0;
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
  GamePageInfos? pageInfos;

  //String timeStart = "";

  //Call

  String? callMode;
  bool calling = false;

  StreamSubscription? signalSub;
  StreamSubscription? connectivitySub;

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

  List<Map<String, dynamic>> gatheredGameDetails = [];

  List<Map<String, dynamic>> gameDetails = [];
  List<Map<String, dynamic>> unsentGameDetails = [];

  // Map<int, Map<int, List<Map<String, dynamic>>?>> recordGameDetails = {};

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
  late StreamController<double> watchTimerController;

  //Time
  Timer? timer;
  double duration = 0.0;
  int gameTime = 0;

  //Ads

  bool awaiting = false;

  InterstitialAd? _interstitialAd;

  bool paused = true, finishedRound = false;

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

  List<int> playersTimes = [];

  List<int> playersCounts = [];
  List<int> playersScores = [];
  List<int>? winners;
  List<ExemptPlayer> exemptPlayers = [];

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

  // StreamSubscription? callSetStateSub;

  @override
  void initState() {
    super.initState();
    maxPlayerTime ??= 30;

    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    onInitState();
    init();
    resetPlayerTime();
    // callSetStateSub = widget.gameCallUtils.setStateStream?.listen((callback) {
    //   setState(callback);
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    landScape = context.isLandscape;
    minSize = context.minSize;
    maxSize = context.maxSize;
    padding = context.remainingSize;
    cardHeight = (minSize - 120) / 3;
    cardWidth = cardHeight.percentValue(70);
  }

  @override
  void dispose() {
    // callSetStateSub?.cancel();

    connectivitySub?.cancel();
    pageController?.dispose();
    timerController.close();
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
      users = arguments["users"] ?? [];
      players = arguments["players"] ?? [];
      exemptPlayers = arguments["closedPlayers"] ?? [];
      playersSize = arguments["playersSize"] ?? 2;
      indices = arguments["indices"];
      recordId = arguments["recordId"] ?? 0;
      roundId = arguments["roundId"] ?? 0;

      // adsTime = arguments["adsTime"] ?? 0;
      pageIndex = arguments["pageIndex"] ?? 0;
      playersScores = arguments["playersScores"] ?? [];
      isTournament = arguments["isTournament"] ?? false;
    }
    isOnline = gameId.isEmpty;
    isCard = gameName.isCard;
    isChessOrDraught = gameName.isChessOrDraught;
    isPuzzle = gameName.isPuzzle;
    isQuiz = gameName.isQuiz;

    isMyTurn = currentPlayerId == myId;

    timerController = StreamController.broadcast();

    watchTimerController = StreamController.broadcast();

    matchEnded = match?.time_end != null;

    checkFirstime();
    //checkSubscription();
    initMessages();
    initPlayersCounts();
    initToasts();
    initPlayersTimes();
    readPlayers();
    readDetails();
    listenForInternetConnection();

    pauseIndex = gameId.isEmpty
        ? playersSize == 1
            ? 0
            : playersSize == 2
                ? 1
                : 2
        : myPlayer;

    gameTime = maxGameTime ?? 0;

    // if (isTournament) {
    //   pageController = PageController();
    // }
  }

  void getOfflineDetails() {
    if (gameId.isEmpty) {}
  }

  bool get isMyMove =>
      !awaiting && gameId.isNotEmpty && currentPlayerId == myId;

  void showPlayerMessage(int player, String message) {
    playersMessages[player] = message;
    setState(() {});
  }

  void showPlayersMessages(List<int> players, String message,
      {bool append = false, bool prepend = false}) {
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final prevMessage = playersMessages[player];
      playersMessages[player] = prepend
          ? "$message $prevMessage"
          : append
              ? "$prevMessage $message"
              : message;
    }
    setState(() {});
  }

  void showAllPlayersMessages(String message,
      {List<int>? exceptedPlayers, bool append = false, bool prepend = false}) {
    final players = getActivePlayersIndices();
    if (exceptedPlayers != null) {
      for (int i = 0; i < exceptedPlayers.length; i++) {
        final player = exceptedPlayers[i];
        players.remove(player);
      }
    }
    showPlayersMessages(players, message, append: append, prepend: prepend);
  }

  void resetPlayerTime([int? maxTime]) {
    stopPlayerTime = false;
    playersTimes[currentPlayer] = maxTime ?? maxPlayerTime ?? 30;
  }

  void stopTimer([bool pause = true]) {
    if (pause) paused = true;

    timer?.cancel();
    timer = null;
  }

  void startTimer() {
    paused = false;
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || awaiting || loadingDetails) return;

      if (isWatch & isWatchMode && duration <= endDuration) {
        readWatchDetails();
      }

      duration = (duration + 0.1).toStringAsFixed(1).toDouble;

      if (duration != 0 && (duration * 10) % 10 != 0) return;

      if (showWatchControls) {
        if (controlsVisiblityTimer >= maxControlsVisiblityTimer) {
          controlsVisiblityTimer = 0;
          showWatchControls = false;
          setState(() {});
        } else {
          controlsVisiblityTimer++;
        }
      }

      // if (isSubscribed != null) {
      //   if (isSubscribed!) {
      //     if (availableDuration > 0) {
      //       availableDuration--;
      //     } else {
      //       showToast(
      //           "Your subscription has expired. Please subscribe to continue without ads");
      //       gotoSubscription();
      //     }
      //   }
      //  if (availableDuration == 0) {
      if (adUtils.adTime >= adUtils.maxAdTime) {
        loadAd();
      } else {
        adUtils.adTime++;
      }
      // print("adTime = ${adUtils.adTime}");
      // }
      //}

      if (maxGameTime != null && gameTime <= 0) {
        timer.cancel();
        onTimeEnd();
      }
      if (maxGameTime != null) {
        gameTime--;
      } else {
        gameTime++;
      }
      timerController.sink.add(gameTime);

      if (!stopPlayerTime) {
        if (playerTime <= 0) {
          if (!isWatch && (gameId.isEmpty || currentPlayerId == myId)) {
            onPlayerTimeEnd();
          }
          if (isPuzzle) {
            setGatheredDetails();
            resetPlayerTime();
          } else if (isChessOrDraught) {
            updateWin(getNextPlayerIndex(currentPlayer));
          }
          if (!mounted) return;
          setState(() {});
        } else {
          playersTimes[currentPlayer] = playerTime - 1;
        }
      }
    });
    if (!mounted) return;
    setState(() {});
  }

  int get playerTime =>
      currentPlayer >= 0 && currentPlayer < playersTimes.length
          ? playersTimes[currentPlayer]
          : maxPlayerTime ?? 30;

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
    if (!isVisible) return false;
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.escape) {
        if (isCheckoutMode) {
          isCheckoutMode = false;
          setState(() {});
        }
        // !finishedRound
        if (!paused) {
          pause();
        }
      } else if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space) {
        if (isWatchMode) {
          togglePlayPause();
        } else {
          if (finishedRound) {
            watch();
          } else {
            if (paused) {
              start(false);
            } else {
              onSpaceBarPressed();
            }
          }
        }
      } else {
        if (paused) {
          if (key == LogicalKeyboardKey.arrowLeft) {
            previous();
          } else if (key == LogicalKeyboardKey.arrowRight) {
            next();
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
    }
    return false;
  }

  void getCurrentPlayer() {
    if (gameId != "") {
      final playerIds = players.map((e) => e.id).toList();
      if (playerIds.isEmpty) return;
      currentPlayerId = isPuzzle || isQuiz ? myId : playerIds.last;
      final currentPlayerIndex = playerIds.indexWhere((element) =>
          isPuzzle || isQuiz ? element == myId : element == currentPlayerId);
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

      if (!mounted) return;

      setState(() {});
      return;
    }

    //playerTime = maxPlayerTime!;
    //message = "Play";
    getNextPlayer();
    if (suspend) getNextPlayer();
    if (!isChessOrDraught) {
      playersTimes[currentPlayer] = maxPlayerTime!;
    }
    setState(() {});
  }

  void resetExemptPlayer() {
    if (exemptPlayers.isEmpty) return;
    List<int> newScores = getNewPlayersScores();

    for (int i = 0; i < exemptPlayers.length; i++) {
      final exemptPlayer = exemptPlayers[i];
      final playerId = exemptPlayer.playerId;
      final action = exemptPlayer.action;
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
    exemptPlayers.clear();

    setState(() {});
  }

  bool isPlayerActive(int player) {
    return getExemptPlayer(player) == null;
  }

  bool isPlayerAvailable(int player) {
    final exemptPlayer = getExemptPlayer(player);
    return exemptPlayer == null || exemptPlayer.action == "concede";
  }

  ExemptPlayer? getExemptPlayer(int player) {
    final index =
        exemptPlayers.indexWhere((element) => element.index == player);
    return index != -1 ? exemptPlayers[index] : null;
  }

  ExemptPlayer? getMyExemptPlayer() {
    final index =
        exemptPlayers.indexWhere((element) => element.playerId == myId);
    return index != -1 ? exemptPlayers[index] : null;
  }

  List<int>? getClosedPlayers() {
    List<int> players = exemptPlayers
        .where((player) => player.action == "close")
        .map((e) => e.index)
        .toList();
    return players.isEmpty ? null : players;
  }

  void addClosedPlayers(List<int> closedPlayers) {
    for (int i = 0; i < closedPlayers.length; i++) {
      final index = closedPlayers[i];

      final exemptPlayer = ExemptPlayer(
          index: index,
          playerId: getPlayerId(index),
          action: "close",
          time: gameTime);
      exemptPlayers.add(exemptPlayer);
    }
  }

  void addLeftPlayers(List<String> availablePlayers) {
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      if (availablePlayers.contains(player.id)) continue;

      final exemptPlayer = ExemptPlayer(
          index: getPlayerIndex(player.id),
          playerId: player.id,
          action: "leave",
          time: gameTime);
      exemptPlayers.add(exemptPlayer);
    }
  }

  List<int> getNewPlayersScores() {
    List<int> scores = [];
    int length = gameId.isNotEmpty ? players.length : playersSize;
    for (int i = 0; i < length; i++) {
      if (exemptPlayers.indexWhere(
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
      if (exemptPlayers
              .indexWhere((element) => element.playerId == player.id) !=
          -1) {
        continue;
      }
      activePlayers.add(player);
    }
    return activePlayers;
  }

  // List<Player> get activePlayers => getActivePlayers();
  // List<Player> get availablePlayers => getAvailablePlayers();
  List<int> get activePlayers => getActivePlayersIndices();
  List<int> get availablePlayers => getAvailablePlayersIndices();

  int get activePlayersCount => getActivePlayersIndices().length;
  int get availablePlayersCount => getAvailablePlayersIndices().length;

  List<Player> getAvailablePlayers() {
    List<Player> availablePlayers = [];
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      if (exemptPlayers.indexWhere((element) =>
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
      if (exemptPlayers.indexWhere((element) => element.index == i) != -1) {
        continue;
      }
      playersIndices.add(i);
    }
    return playersIndices;
  }

  List<int> getAvailablePlayersIndices() {
    List<int> playersIndices = [];
    int length = gameId.isNotEmpty ? players.length : playersSize;

    for (int i = 0; i < length; i++) {
      if (exemptPlayers.indexWhere(
              (element) => element.index == i && (element.action == "leave")) !=
          -1) {
        continue;
      }
      playersIndices.add(i);
    }
    return playersIndices;
  }

  List<String> getPlayersUsernames(List<int> players) {
    return players
        .map((player) => getPlayerUsername(playerIndex: player))
        .toList();
  }

  String getPlayerUsername({String? playerId, int playerIndex = 0}) {
    final index = users?.indexWhere((e) => playerId != null
            ? e?.user_id == playerId
            : players.isNotEmpty
                ? e?.user_id == players[playerIndex].id
                : false) ??
        -1;

    return index != -1
        ? users![index]?.user_id == myId
            ? "you"
            : users![index]!.username
        : "Player ${playerIndex + 1}";
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
    if (index == -1) return;
    if (gameId.isNotEmpty) {
      final playerIds = players.map((e) => e.id).toList();
      currentPlayerId = playerIds[index];
    }
    onPlayerChange(index);
    currentPlayer = index;
  }

  void getNextPlayer() {
    final index = isPuzzle || isQuiz ? currentPlayer : getNextPlayerIndex();
    if (index == -1) return;
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

  void updateMyCallMode(String? callMode) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1 || players[index].callMode == callMode) return;

    await updateCallMode(gameId, matchId, callMode);

    players[index] = players[index].copyWith(callMode: callMode);

    executeCallAction(players[index]);
    // widget.gameCallUtils.executeCallAction(players[index]);

    if (!mounted) return;
    setState(() {});
  }

  Future updateMyAction(String action) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1 || players[index].action == action) return;
    await updatePlayerActionAndShowToast(action);
    if (index < 0 || index > players.length - 1) return;
    players[index] = players[index].copyWith(action: action);
    if (action != "ad" && action.isNotEmpty) {
      showToast(action == "start" && !startingRound && !finishedRound
          ? "You resumed"
          : "You $action${action.endsWith("e") ? "d" : "ed"}");
    }

    executeAction();

    if (!mounted) return;
    setState(() {});
  }

  void updateMyChangedGame(String game) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1 || players[index].game == game) return;
    await updatePlayerActionAndShowToast("pause", game);
    players[index] = players[index].copyWith(game: game, action: "pause");
    showToast("You changed game to $game");
    executeGameChange();
    if (!mounted) return;
    setState(() {});
  }

  void executeGameChange() {
    String newgame = getChangedGame(getAvailablePlayers());
    if (newgame.isEmpty || gameName == newgame) return;
    change(newgame, false);
  }

  String executeAction() {
    // final availablePlayers = getAvailablePlayers();
    final activePlayers = getActivePlayers();
    if (activePlayers.length < 2) {
      if (exemptPlayers.isNotEmpty) {
        showToast(
            "You are the only player in this match. Please wait for others to continue");
      }

      return "pause";
    }

    String action = getAction(activePlayers);
    if (action == "pause") {
      if (!paused) {
        pause(false);
      }
    } else if (action == "start") {
      if (paused) {
        start(false);
      }
    } else if (action == "restart") {
      restart(false);
    } else if (action == "continue") {
      continueMatch(false);
    }
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
    final name = gameName.isQuiz ? "Quiz" : gameName;
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

  void listenForInternetConnection() {
    if (gameId.isEmpty) return;
    connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      isConnectedToInternet = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
      setState(() {});

      if (isConnectedToInternet && unsentGameDetails.isNotEmpty) {
        sendUnsentDetails();
      }
    });
  }

  Future readPlayers() async {
    if (match?.records?["$recordId"]?["rounds"]?["$roundId"] != null) {
      //final record = MatchRecord.fromMap(match!.records?["$recordId"]);
      MatchRound round = MatchRound.fromMap(
          match!.records?["$recordId"]["rounds"]["$roundId"]);

      if (players.isEmpty) {
        players = List.generate(
            round.players.length,
            (index) =>
                Player(id: round.players[index], time: timeNow, order: index));
      }
      if (round.closed_players != null) {
        addClosedPlayers(round.closed_players!);
      }

      playersScores = round.scores.toList().cast();
      winners = round.winners;
      finishedRound = round.time_end != null;

      gameDetailsLength = round.detailsLength;
      endDuration = round.duration;
    } else {
      if (playersScores.isEmpty) {
        initScores();
      }
      if (gameId.isNotEmpty && match != null) {
        if (players.isEmpty) {
          players = List.generate(
              match!.players!.length,
              (index) => Player(
                  id: match!.players![index], time: timeNow, order: index));
        }
      }
      // else {
      //   players = List.generate(playersSize,
      //       (index) => Player(id: "$index", time: timeNow, order: index));
      // }
    }
    // availablePlayersCount = gameId.isEmpty ? playersSize : players.length;

    if (gameId.isEmpty || match == null) return;
    players.sortList((player) => player.order, false);

    widget.gameCallUtils.setPlayers(players);

    if (users == null || users!.isEmpty) {
      users = await playersToUsers(players.map((e) => e.id).toList());
    }

    final index = players.indexWhere((element) => element.id == myId);
    myPlayer = index;

    // if (!finishedRound) {
    //   players[myPlayer] = players[myPlayer].copyWith(action: "pause");
    // }
    if (isLastPage && !finishedRound) {
      final availablePlayers = (match?.available_players ?? []);
      if (availablePlayers.isNotEmpty) {
        addLeftPlayers(match!.available_players!);
      }
    }

    setState(() {});

    if (match?.time_end != null) {
      return;
    }
    final lastTime = players
        .sortedList((player) => player.time_modified ?? "", false)
        .lastOrNull
        ?.time_modified;

    players.sortList((player) => player.order ?? 0, false);

    final playerIds = players.map((player) => player.id).toList();

    playersSub = getPlayersChange(gameId,
            matchId: matchId, lastTime: lastTime, players: playerIds)
        .listen((playersChanges) async {
      for (int i = 0; i < playersChanges.length; i++) {
        final playersChange = playersChanges[i];
        final player = playersChange.value;

        final playerIndex =
            players.indexWhere((element) => element.id == player.id);
        final userIndex =
            users!.indexWhere((element) => element?.user_id == player.id);
        final username = userIndex == -1
            ? ""
            : users![userIndex]?.user_id == myId
                ? "you"
                : users![userIndex]?.username ?? "";

        final myPlayer = getMyPlayer(players);

        if (playerIndex != -1) {
          final prevPlayer = players[playerIndex];
          if (player.game != null &&
              myPlayer?.game != null &&
              prevPlayer.game != player.game &&
              player.game != myPlayer?.game) {
            if (alertShown) {
              context.pop();
              alertShown = false;
            }
            alertShown = true;
            final result = await context.showComfirmationDialog(
                title: "$username changed to ${player.game}",
                message: "Do you also want to change game?");
            alertShown = false;
            if (result == true) {
              change(player.game!);
            }
          } else if ((player.action ?? "").isNotEmpty &&
              (myPlayer?.action ?? "").isNotEmpty &&
              prevPlayer.action != player.action &&
              player.action != myPlayer?.action) {
            final action = player.action ?? "";
            final playerId = player.id;
            final title =
                "$username $action${action.endsWith("e") ? "d" : "ed"}";

            // if(action == "start" && getEx)

            if (action == "start") {
              if ((match!.available_players == null ||
                      match!.available_players!.contains(playerId)) &&
                  (getExemptPlayer(playerIndex)?.action == "close")) {
                unclose(playerId, false);
              }
            }

            if (action == "ad") {
              loadAd();
            } else if (action == "concede") {
              if (startingRound && !finishedRound) concede(playerId, false);
            } else if (action == "leave") {
              leave(playerId, false);
            } else if (action == "close") {
              close(playerId, false);
            } else if (action == "unclose") {
              unclose(playerId, false);
            } else if (action == "pause") {
              showToast(title);
            } else {
              showToast(title);

              if (alertShown) {
                context.pop();
              }
              if (myPlayer?.action != "ad") {
                alertShown = true;
                final result = await context.showComfirmationDialog(
                    title: title, message: "Do you also want to $action game?");
                alertShown = false;

                if (result == true) {
                  if (player.action == "pause") {
                    if (!paused) {
                      pause();
                    }
                  } else if (player.action == "start") {
                    if (paused) {
                      start();
                    }
                  } else if (player.action == "restart") {
                    restart();
                  } else if (player.action == "continue") {
                    continueMatch();
                  }
                }
              }
            }
          } else if (player.callMode != null &&
              prevPlayer.callMode != player.callMode &&
              player.callMode != myPlayer?.callMode) {
            final callMode = player.callMode;
            final title =
                "$username ${callMode == null ? "ended ${prevPlayer.callMode} call" : "started $callMode call"}";

            showToast(title);

            if (callMode != null) {
              final result = await context.showComfirmationDialog(
                  title: title, message: "Do you accept?");
              if (result == true) {
                toggleCall(callMode);
              }
            }
          }
          // widget.gameCallUtils.executeCallAction(player, playersChange.removed);

          players[playerIndex] = player;
        } else {
          showToast("$username joined");
          // widget.gameCallUtils.executeCallAction(player, playersChange.removed);

          players.add(player);
        }

        if (!mounted) return;
        executeAction();
        executeGameChange();
        //executeCallAction(player, playersChange.removed);
        // widget.gameCallUtils.executeCallAction(player, playersChange.removed);

        setState(() {});
      }
    });
  }

  Future readWatchDetails() async {
    //trying to match the watch position

    bool isBack = false;
    if (newDuration != null || newDetailIndex != null) {
      if ((newDuration != null && newDuration! < duration) ||
          (newDetailIndex != null &&
              (newDetailIndex! < detailIndex ||
                  (newMoreDetailIndex != null &&
                      newDetailIndex == detailIndex &&
                      newMoreDetailIndex! < moreDetailIndex)))) {
        isBack = true;
        gameTime = maxGameTime ?? 0;

        detailIndex = 0;
        moreDetailIndex = -1;
        //start(true, true);
        resetAllDetails();
      }
    }

    if (newDetailIndex != null && newMoreDetailIndex != null) {
      int newDetailIndex = this.newDetailIndex!;
      int newMoreDetailIndex = this.newMoreDetailIndex!;

      seeking = true;
      if (detailIndex >= 0 && detailIndex <= newDetailIndex) {
        while (detailIndex <= newDetailIndex) {
          final gameDetail = gameDetails[detailIndex];

          final moreDetails = gameDetail["moreDetails"] as List<dynamic>?;

          if (detailIndex == newDetailIndex &&
              moreDetailIndex == newMoreDetailIndex) {
            if (!isBack) {
              if (moreDetailIndex != -1 &&
                  moreDetails != null &&
                  moreDetails.isNotEmpty) {
                updateGameDetails(moreDetails[moreDetailIndex]);
              } else {
                updateGameDetails(gameDetail);
              }

              getNextCurrent();
            }

            break;
          }

          if (moreDetails != null && moreDetails.isNotEmpty) {
            if (moreDetailIndex == -1) {
              updateGameDetails(gameDetail);

              moreDetailIndex = 0;
            } else {
              final moreGameDetail = moreDetails[moreDetailIndex];
              updateGameDetails(moreGameDetail);

              if (moreDetailIndex == moreDetails.length - 1) {
                detailIndex++;
                moreDetailIndex = -1;
              } else {
                moreDetailIndex++;
              }
            }
          } else {
            updateGameDetails(gameDetail);

            detailIndex++;
            moreDetailIndex = -1;
          }
        }
      }

      seeking = false;
    } else if (newDuration != null) {
      double newDuration = this.newDuration!;
      seeking = true;
      if (newDuration >= 0 && newDuration <= endDuration) {
        while (detailIndex < gameDetails.length) {
          final gameDetail = gameDetails[detailIndex];

          final gameDuration = (gameDetail["duration"] as double);
          if (gameDuration > newDuration) {
            break;
          }
          final moreDetails = gameDetail["moreDetails"] as List<dynamic>?;

          if (moreDetails != null && moreDetails.isNotEmpty) {
            if (moreDetailIndex == -1) {
              updateGameDetails(gameDetail);
              moreDetailIndex = 0;
            } else {
              final moreGameDetail = moreDetails[moreDetailIndex];
              final moreGameDuration = (moreGameDetail["duration"] as double);
              if (moreGameDuration > newDuration) {
                break;
              }
              updateGameDetails(moreGameDetail);

              if (moreDetailIndex == moreDetails.length - 1) {
                detailIndex++;
                moreDetailIndex = -1;
              } else {
                moreDetailIndex++;
              }
            }
          } else {
            updateGameDetails(gameDetail);
            detailIndex++;
            moreDetailIndex = -1;
          }
        }
      }

      seeking = false;
    } else {
      seeking = false;
      if (detailIndex >= 0 && detailIndex < gameDetails.length) {
        final gameDetail = gameDetails[detailIndex];
        final detailDuration = (gameDetail["duration"] as double);

        if (duration >= detailDuration) {
          final moreDetails = gameDetail["moreDetails"] as List<dynamic>?;

          if (moreDetails != null && moreDetails.isNotEmpty) {
            if (moreDetailIndex == -1) {
              updateGameDetails(gameDetail);

              moreDetailIndex = 0;
            } else {
              final moreGameDetail = moreDetails[moreDetailIndex];
              final moreGameDuration = (moreGameDetail["duration"] as double);

              if (duration >= moreGameDuration) {
                updateGameDetails(moreGameDetail);

                if (moreDetailIndex == moreDetails.length - 1) {
                  detailIndex++;
                  moreDetailIndex = -1;
                } else {
                  moreDetailIndex++;
                }
              }
            }
          } else {
            updateGameDetails(gameDetail);

            moreDetailIndex = -1;
            detailIndex++;
          }
        }
      }
    }

    if (detailIndex >= gameDetails.length - watchDetailsLimit &&
        gameId.isNotEmpty &&
        !loadingDetails &&
        gameDetails.length < gameDetailsLength) {
      final playerIds = players.map((player) => player.id).toList();

      var lastTime = gameDetails.lastOrNull?["time"];

      if (newDetailIndex != null) {
        seeking = true;
        if (!loadingDetails) {
          loadingDetails = true;
          setState(() {});
        }
        // final remaining = newDetailIndex - gameDetails.length - 1;
        final foundGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime, index: newDetailIndex, players: playerIds);
        gameDetails.addAll(foundGameDetails);
        seeking = false;

        if (foundGameDetails.isNotEmpty) readWatchDetails();
      } else if (newDuration != null) {
        seeking = true;
        if (!loadingDetails) {
          loadingDetails = true;
          setState(() {});
        }
        final foundGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime, duration: newDuration, players: playerIds);
        gameDetails.addAll(foundGameDetails);
        seeking = false;

        if (foundGameDetails.isNotEmpty) readWatchDetails();
      }

      if (detailIndex >= gameDetails.length - watchDetailsLimit &&
          gameDetails.length < gameDetailsLength) {
        if (!loadingDetails) {
          loadingDetails = true;
          setState(() {});
        }
        final lastTime = gameDetails.lastOrNull?["time"];

        final foundGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime, limit: watchDetailsLimit, players: playerIds);
        gameDetails.addAll(foundGameDetails);

        if (foundGameDetails.isNotEmpty) readWatchDetails();
      }
      if (loadingDetails) {
        loadingDetails = false;
        setState(() {});
      }
    } else {
      if (newDetailIndex != null) {
        newDetailIndex = null;
      }
      if (newMoreDetailIndex != null) {
        newMoreDetailIndex = null;
      }
      if (newDuration != null) {
        duration = newDuration!;
        newDuration = null;
      }
    }

    watchTimerController.sink.add(duration);

    if (finishedRound && duration >= endDuration) {
      stopWatching();
    } else {
      setState(() {});
    }
  }

  Future readDetails() async {
    if (match == null) return;
    if (detailsSub != null) {
      await detailsSub!.cancel();
      detailsSub = null;
    }

    final timeStart =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_start"];

    // final timeEnd =
    //     match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_end"];

    //var lastTime = gameDetails.lastOrNull?["time"];
    final playerIds = players.map((player) => player.id).toList();

    if (gameId.isNotEmpty) {
      if (timeStart != null) {
        loadingDetails = true;
        setState(() {});

        final foundGameDetails =
            await getGameDetails(gameId, matchId, recordId, roundId,
                // time: lastTime,
                limit: isWatch && finishedRound ? watchDetailsLimit * 2 : null,
                players: playerIds);

        loadingDetails = false;
        gameDetails.addAll(foundGameDetails);

        if (foundGameDetails.isEmpty) {
          if (isWatch) stopWatching();
        } else {
          if (!isWatch) {
            // availablePlayersCount =
            //     gameId.isEmpty ? playersSize : players.length;

            reason = "";
            message = "Play";
            duration = 0;
            gameTime = maxGameTime ?? 0;
            playersTimes[currentPlayer] = maxPlayerTime ?? 30;

            timerController.sink.add(gameTime);
            getCurrentPlayer();
            onStart();
            seeking = true;
            for (int i = 0; i < foundGameDetails.length; i++) {
              final gameDetail = foundGameDetails[i];
              updateGameDetails(gameDetail, readMoreDetails: true);
            }
            seeking = false;
            endDuration = gameDetails.lastOrNull?["duration"] ?? 0.0;
          }
        }
      }
      if (!mounted) {
        return;
      }

      setState(() {});

      if (finishedRound) {
        return;
      }

      var lastTime = gameDetails.lastOrNull?["time"];

      detailsSub = getGameDetailsChange(gameId, matchId, recordId, roundId,
              time: lastTime, players: playerIds)
          .listen((detailsChanges) {
        for (int i = 0; i < detailsChanges.length; i++) {
          final detailsChange = detailsChanges[i];
          final gameDetail = detailsChange.value;
          gameDetails.add(gameDetail);
          updateGameDetails(gameDetail, readMoreDetails: true);
        }
      });
    }
  }

  void updateGameDetails(Map<String, dynamic> gameDetail,
      {bool readMoreDetails = false}) {
    final playerId = gameDetail["id"];
    final duration = gameDetail["duration"];
    final playerTime = gameDetail["playerTime"] as int?;
    final playerIndex = getPlayerIndex(playerId);
    //currentPlayer = playerIndex;

    final action = gameDetail["action"];

    if (duration != null) {
      this.duration = (duration is int) ? duration.toDouble() : duration;
      gameTime = maxGameTime != null
          ? maxGameTime! - this.duration.toInt()
          : this.duration.toInt();
    }

    if (playerTime != null &&
        playerIndex > 0 &&
        playerIndex < playersTimes.length) {
      playersTimes[playerIndex] = playerTime;
    }

    if (action != null) {
      if (action == "concede") {
        concede(playerId, false);
      } else if (action == "leave") {
        leave(playerId, false);
      } else if (action == "close") {
        close(playerId, false);
      } else if (action == "unclose") {
        unclose(playerId, false);
      }
    } else {
      awaitingDetails = true;
      onDetailsChange(gameDetail);
      awaitingDetails = false;
    }
    if (readMoreDetails && gameDetail["moreDetails"] != null) {
      final moreDetails = gameDetail["moreDetails"] as List<dynamic>;
      for (int i = 0; i < moreDetails.length; i++) {
        final detail = moreDetails[i];
        updateGameDetails(detail);
      }
    }
  }

  void setActionDetails(String action) {
    if (finishedRound) return;

    final outputDetail = getFullDetail({"action": action}, index: 0, length: 1);
    gatheredGameDetails.add(outputDetail);

    setGatheredDetails();
  }

  Future<List<Map<String, dynamic>>> setDetails(
      List<Map<String, dynamic>> details) async {
    if (finishedRound) return [];
    List<Map<String, dynamic>> outputDetails = [];
    for (int i = 0; i < details.length; i++) {
      final detail = details[i];
      final outputDetail =
          getFullDetail(detail, index: i, length: details.length);
      outputDetails.add(outputDetail);
      gatheredGameDetails.add(outputDetail);
    }
    setGatheredDetails();
    return outputDetails;
  }

  Map<String, dynamic> getFullDetail(Map<String, dynamic> detail,
      {int index = 0, int length = 1}) {
    detail["time"] = timeNow;
    detail["duration"] = (duration - ((length - index - 1) * (1 / length)))
        .toStringAsFixed(1)
        .toDouble;
    detail["playerTime"] = playerTime;
    detail["id"] = gameId.isEmpty
        ? "${detail["action"] != null ? pauseIndex : currentPlayer}"
        : myId;
    return detail.removeNull();
  }

  Future<Map<String, dynamic>> setDetail(Map<String, dynamic> detail,
      {bool add = true}) async {
    if (finishedRound) return {};

    final outputDetail = getFullDetail(detail, index: 0, length: 1);
    gatheredGameDetails.add(outputDetail);

    if (add) {
      setGatheredDetails();
    }

    return detail;
  }

  Future setGatheredDetails() async {
    if (gatheredGameDetails.isEmpty || isWatch || finishedRound) return;
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

  Future addDetails(Map<String, dynamic> detail) async {
    if (awaiting || !mounted) return {};

    detail["game"] = gameName;
    detail["recordId"] = recordId;
    detail["roundId"] = roundId;
    detail["index"] = gameDetails.length;

    gameDetails.add(detail);

    if (gameId.isNotEmpty) {
      await sendUnsentDetails();
      return setGameDetails(gameId, matchId, detail).catchError((e) {
        unsentGameDetails.add(detail);
      });
      // awaiting = true;
      // await setGameDetails(gameId, matchId, detail);
      // awaiting = false;
    }
    return detail;
  }

  Future sendUnsentDetails() async {
    while (unsentGameDetails.isNotEmpty) {
      if (!isConnectedToInternet) return;
      try {
        await setGameDetails(gameId, matchId, unsentGameDetails.first);
        unsentGameDetails.removeAt(0);
      } catch (e) {
        return;
      }
    }
  }

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

  bool get itsFirstToPlay {
    return gameId.isEmpty || (myPlayer == playersSize - 1);
  }

  bool itsMyTurnForMessage(int player) =>
      (currentPlayer == player && showMessage) ||
      getExemptPlayer(player) != null;

  bool itsMyTurnToPlay(bool isClick, [int? player]) {
    if (isClick &&
        gameId.isNotEmpty &&
        !finishedRound &&
        (match?.available_players ?? [])
                .indexWhere((player) => player == myId) ==
            -1) {
      showToast("You are not a player in this game");
      return false;
    }
    if (isCheckoutMode) {
      showToast("You can't play in checkout mode. Back press to exit");

      return false;
    }
    if (isClick) toggleLayoutPressed();

    if (seeking) return true;

    if (awaiting || !mounted || (finishedRound && isClick)) {
      return false;
    }

    if (isClick && gameId.isNotEmpty && currentPlayerId != myId) {
      showPlayerToast(myPlayer,
          "Its ${getPlayerUsername(playerId: currentPlayerId)}'s turn");

      return false;
    }
    if (isClick && player != null && currentPlayer != player) {
      showPlayerToast(player,
          "Its ${getPlayerUsername(playerId: currentPlayerId, playerIndex: currentPlayer)}'s turn");

      return false;
    }
    return true;
  }

  void incrementCount(int player, [int count = 1]) {
    playersCounts[player] += count;
    if (!mounted) return;

    setState(() {});
  }

  void decrementCount(int player, [int count = 1]) {
    playersCounts[player] -= count;
    if (!mounted) return;

    setState(() {});
  }

  void updateCount(int player, int count) {
    playersCounts[player] = count;
    if (!mounted) return;
    setState(() {});
  }

  void setInitialCount(int count) {
    playersCounts = List.generate(playersSize, (index) => count);
  }

  void initPlayersCounts() {
    playersCounts = List.generate(playersSize, (index) => -1);
  }

  void initPlayersTimes() {
    playersTimes = List.generate(playersSize, (index) => maxPlayerTime ?? 30);
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

  void showPlayerToasts(List<String> messages) {
    for (int i = 0; i < activePlayers.length; i++) {
      final playerIndex = activePlayers[i];
      playersToasts[playerIndex] = messages[i];
    }
    if (!mounted) return;

    setState(() {});
  }

  void showPlayerToast(int playerIndex, String message) {
    if (!isPlayerActive(playerIndex)) return;
    playersToasts[playerIndex] = message;
    if (!mounted) return;

    setState(() {});
  }

  void showPlayersToast(List<int> indices, String message) {
    for (int i = 0; i < indices.length; i++) {
      final index = indices[i];
      if (!isPlayerActive(index)) continue;
      playersToasts[index] = message;
    }
    if (!mounted) return;

    setState(() {});
  }

  void showAllPlayersToast(String message) {
    for (int i = 0; i < playersSize; i++) {
      if (!isPlayerActive(i)) continue;
      playersToasts[i] = message;
    }
    if (!mounted) return;

    setState(() {});
  }

  String getExemptPlayerMessage(ExemptPlayer exemptPlayer) {
    return exemptPlayer.action == "concede"
        ? "Conceded"
        : exemptPlayer.action == "leave"
            ? "Left"
            : exemptPlayer.action == "close"
                ? "Closed"
                : "";
  }

  String getMessage(int index) {
    String message = playersMessages[index];

    return "${itsMyTurnForMessage(index) ? "${message.isEmpty ? this.message.isNotEmpty ? this.message : "Play" : message} - " : message.isEmpty ? "" : "$message - "}${playersTimes[index].toDurationString(false)}";
  }

  void updateWinForPlayerWithHighestCount() {
    final players = getHighestCountPlayer(playersCounts);
    if (players.length == 1) {
      updateWin(players.first,
          reason:
              "${getPlayerUsername(playerIndex: players.first)} won with ${playersCounts[players.first]} points");
    } else {
      if (players.isEmpty) return;
      if (players.length == playersSize) {
        updateDraw(
            reason: "It's a draw with ${playersCounts[players.first]} points");
      } else {
        updateTie(players,
            reason:
                "${players.map((player) => getPlayerUsername(playerIndex: player)).join(" and ")} tied with ${playersCounts[players.first]} points");
      }
    }
  }

  void updateTie(List<int> players, {String? reason}) {
    if (this.reason.isEmpty) {
      this.reason = reason ?? "";
    }
    if (players.length == 1) {
      return updateWin(players.first, reason: reason);
    }
    if (players.length == playersSize) {
      return updateDraw(reason: reason);
    }

    updateMatchRound(players);

    toastWinners(players, reason: reason);
  }

  void updateWin(int player, {String? reason}) {
    if (this.reason.isEmpty) {
      this.reason = reason ?? "";
    }
    updateMatchRound([player]);

    toastWinner(player, reason: reason);
  }

  void updateDraw({String? reason}) {
    if (this.reason.isEmpty) {
      this.reason = reason ?? "";
    }
    updateMatchRound([]);

    toastDraw(reason: reason);
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
    String message = "${getPlayerUsername(playerIndex: player)} won";
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
      final usernames =
          players.map((e) => getPlayerUsername(playerIndex: e)).toList();
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

  void previous() {
    if (isFirstPage) return;
    updateGameAction("previous");
  }

  void next() {
    if (isLastPage) return;
    updateGameAction("next");
  }

  List<int> getPreviousDetail([int? detailIndex, int? moreDetailIndex]) {
    detailIndex ??= this.detailIndex;
    moreDetailIndex ??= this.moreDetailIndex;

    List<int> values = [detailIndex, moreDetailIndex];

    if (detailIndex < 0 || detailIndex > gameDetails.length - 1) {
      return [];
    }

    final moreDetails =
        gameDetails[detailIndex]["moreDetails"] as List<dynamic>?;
    if (moreDetails != null && moreDetails.isNotEmpty) {
      if (moreDetailIndex == -1) {
        if (detailIndex <= 0) {
          return [];
        }
        values[0] = detailIndex - 1;

        final prevMoreDetails =
            gameDetails[detailIndex - 1]["moreDetails"] as List<dynamic>?;
        if (prevMoreDetails != null && prevMoreDetails.isNotEmpty) {
          values[1] = prevMoreDetails.length - 1;
        } else {
          values[1] = -1;
        }
      } else if (moreDetailIndex == 0) {
        values[1] = -1;
        values[0] = detailIndex;
      } else {
        values[1] = moreDetailIndex - 1;
        values[0] = detailIndex;
      }
    } else {
      if (detailIndex <= 0) {
        return [];
      }

      final prevMoreDetails =
          gameDetails[detailIndex - 1]["moreDetails"] as List<dynamic>?;
      if (prevMoreDetails != null && prevMoreDetails.isNotEmpty) {
        values[1] = prevMoreDetails.length - 1;
      } else {
        values[1] = -1;
      }
      values[0] = detailIndex - 1;
    }
    return values;
  }

  List<int> getNextDetail([int? detailIndex, int? moreDetailIndex]) {
    detailIndex ??= this.detailIndex;
    moreDetailIndex ??= this.moreDetailIndex;
    List<int> values = [detailIndex, moreDetailIndex];

    if (detailIndex < 0 || detailIndex > gameDetails.length - 1) {
      return [];
    }
    final moreDetails =
        gameDetails[detailIndex]["moreDetails"] as List<dynamic>?;

    if (moreDetails != null && moreDetails.isNotEmpty) {
      if (moreDetailIndex == -1) {
        values[0] = detailIndex;
        values[1] = 0;
      } else if (moreDetailIndex == moreDetails.length - 1) {
        if (detailIndex >= gameDetails.length - 1) {
          return [];
        }
        values[0] = detailIndex + 1;
        values[1] = -1;
      } else {
        values[0] = detailIndex;
        values[1] = moreDetailIndex + 1;
      }
    } else {
      if (detailIndex >= gameDetails.length - 1) {
        return [];
      }
      values[0] = detailIndex + 1;
      values[1] = -1;
    }

    return values;
  }

  void getPreviousCurrent() {
    final values = getPreviousDetail();
    if (values.isEmpty) {
      return;
    }
    detailIndex = values[0];
    moreDetailIndex = values[1];
    readWatchDetails();
  }

  void getNextCurrent() {
    final values = getNextDetail();
    if (values.isEmpty) {
      return;
    }
    detailIndex = values[0];
    moreDetailIndex = values[1];
    readWatchDetails();
  }

  void nextDetail() {
    controlsVisiblityTimer = 0;
    final values = getNextDetail();
    if (values.isEmpty) {
      stopWatching();
      return;
    }

    newDetailIndex = values[0];
    newMoreDetailIndex = values[1];

    readWatchDetails();
  }

  void previousDetail() {
    controlsVisiblityTimer = 0;
    final values = getPreviousDetail();
    if (values.isEmpty) {
      return;
    }

    newDetailIndex = values[0];
    newMoreDetailIndex = values[1];

    readWatchDetails();
  }

  void rewind() {
    controlsVisiblityTimer = 0;

    if ((duration - durationSkipLimit) < 0) {
      newDuration = 0;
      return;
    }

    newDuration = duration - durationSkipLimit;
    readWatchDetails();
  }

  void forward() {
    controlsVisiblityTimer = 0;
    if (loadingDetails) return;

    if (duration + durationSkipLimit > endDuration) {
      newDuration = endDuration;
      stopWatching();
      return;
    }
    newDuration = duration + durationSkipLimit;
    readWatchDetails();
  }

  void seek(double duration) {
    controlsVisiblityTimer = 0;
    if (duration < 0 || duration > endDuration) {
      return;
    }
    newDuration = duration;
    readWatchDetails();
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

  void pauseWatching() {
    controlsVisiblityTimer = 0;

    watching = false;
    stopTimer(false);
    setState(() {});
  }

  void toggleShowControls() {
    controlsVisiblityTimer = 0;
    showWatchControls = !showWatchControls;
    setState(() {});
  }

  void resetWatchDetails() {
    detailIndex = 0;
    moreDetailIndex = -1;

    newDuration = null;
    newDetailIndex = null;
    newMoreDetailIndex = null;

    controlsVisiblityTimer = 0;
  }

  void stopWatching([bool reset = true]) {
    if (!isWatchMode || gameDetailsLength != gameDetails.length || !mounted) {
      return;
    }
    if (reset) {
      resetWatchDetails();
    }

    isWatchMode = false;
    watching = false;
    showWatchControls = false;
    pause(false);
  }

  void watch() {
    if (!isWatchMode) {
      gameTime = maxGameTime ?? 0;
      //start(false, true);
      resetAllDetails();
      resetWatchDetails();

      isWatchMode = true;
    }
    watching = true;
    showWatchControls = true;
    startTimer();
    setState(() {});
  }

  void rewatch() {
    isWatchMode = false;
    watch();
  }

  void updateGameAction(String action, {String? game}) {
    widget.onGameActionPressed(
      GameAction(
          action: action,
          game: game ?? gameName,
          players: players,
          exemptPlayers: exemptPlayers,
          hasStarted: !startingRound,
          args: widget.arguments ?? {}),
    );
  }

  Future<dynamic> updatePlayerActionAndShowToast(
    String action, [
    String? game,
  ]) async {
    final myPlaying = players.firstWhere((element) => element.id == myId);
    final myAction = myPlaying.action;
    final myGame = myPlaying.game;

    if (myAction == action && myGame == game) return;
    await updatePlayerAction(gameId, matchId, action, game);

    if (this.users == null || this.users!.isEmpty) return;
    final users = this.users!;

    final otherPlayers = players
        .where((element) =>
            element.id != myId &&
            (action != myAction
                ? element.action != myAction
                : element.game != myGame))
        .toList();

    if (otherPlayers.isNotEmpty) {
      List<User> waitingUsers = [];
      for (int i = 0; i < otherPlayers.length; i++) {
        final players = otherPlayers[i];
        final user = users.isEmpty
            ? null
            : users.firstWhere(
                (element) => element != null && element.user_id == players.id);
        if (user != null) {
          waitingUsers.add(user);
        }
      }
      if ((action.isEmpty || action == "ad") && game == null) {
        return;
      }
      showToast(
          "Waiting for ${waitingUsers.toStringWithCommaandAnd((user) => user.username)} to also ${action != myAction ? action : "change to $game"}");
    }
  }

  void resetAllDetails() {
    // availablePlayersCount = gameId.isEmpty ? playersSize : players.length;

    reason = "";
    message = "Play";
    duration = 0;
    gameTime = maxGameTime ?? 0;
    playersTimes[currentPlayer] = maxPlayerTime ?? 30;
    gatheredGameDetails.clear();
    exemptPlayers.clear();

    isCheckoutMode = false;
    timerController.sink.add(gameTime);

    getCurrentPlayer();

    //trying to check for the index that has the init of the details if its the last

    final initIndex =
        gameDetails.indexWhere((detail) => detail["action"] == null);

    if ((startingRound || initIndex == gameDetails.length - 1) &&
        !finishedRound &&
        (gameId.isEmpty ||
            (myPlayer == playersSize - 1 &&
                match?.records?["$recordId"]?["rounds"]?["$roundId"] ==
                    null))) {
      onInit();
    }
    onStart();
  }

  void showCheckout() {
    setState(() {
      isCheckoutMode = true;
    });
  }

  void readAboutTheGame() {
    if (readAboutGame) {
      setState(() {
        readAboutGame = false;
      });
    }
  }

  bool get startingRound =>
      maxGameTime != null ? gameTime == maxGameTime : gameTime == 0;

  void loadAd() {
    adUtils.loadAd(onShow: updateAd, onHide: start, onFail: start);
    adUtils.adTime = 0;
  }

  void updateAd([bool isClick = true]) {
    if (isClick && gameId.isNotEmpty) {
      updateMyAction("ad");
      return;
    }
  }

  void pause([bool isClick = true]) async {
    if (!mounted) return;
    if (isClick && gameId.isNotEmpty) {
      updateMyAction("pause");
      return;
    }
    stopTimer();
    onPause();
    setState(() {});
  }

  void start([bool isClick = true]) async {
    if (isClick &&
        gameId.isNotEmpty &&
        match != null &&
        !finishedRound &&
        (match!.available_players == null ||
            match!.available_players!.contains(myId)) &&
        !isWatch &&
        (getMyExemptPlayer()?.action == "close")) {
      unclose(myId, true);
      return;
    }
    final myPlayer = getMyPlayer(players);
    if (isClick && gameId.isNotEmpty) {
      if (paused && myPlayer?.action == "start") {
        pause();
      } else {
        updateMyAction("start");
      }
      return;
    }

    if (startingRound) {
      resetAllDetails();
      updateMatchRecord();
    } else {
      onResume();
    }
    if (isAndroidAndIos || kIsWeb) {
      analytics.logEvent(
        name: 'match',
        parameters: {
          "game": gameName,
          "type": gameId.isEmpty ? "offline" : "online",
          "datetime": DateTime.now().datetime,
        },
      );
    }

    startTimer();
  }

  void continueMatch([bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      updateMyAction("continue");
      return;
    }
    if (!finishedRound) {
      updateMatchRound(null, false);
    }
    updateGameAction("continue");
    stopListening();
  }

  void restart([bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      updateMyAction("restart");
      return;
    }
    if (!finishedRound) {
      updateMatchRound(null, false);
    }
    updateGameAction("restart");
    stopListening();
  }

  void change(String game, [bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      updateMyChangedGame(game);
      return;
    }
    if (!finishedRound) {
      updateMatchRound(null, false);
    }

    updateGameAction("change", game: game);
    stopListening();
  }

  void close([String? playerId, bool isClick = true]) async {
    if (isClick && (finishedRound || gameId.isEmpty)) {
      context.pop();
      return;
    }
    if (isClick && gameId.isNotEmpty) {
      if (isPuzzle) {
        setGatheredDetails();
      }
      if (startingRound || finishedRound) {
        try {
          await updateMyAction("close");
        } catch (e) {}
      } else {
        setActionDetails("close");
      }
      updateMyAction("");

      if (!mounted) return;
      context.pop();
      return;
    }
    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    //onClose(index);

    if (gameId.isEmpty && !isWatch) setActionDetails("close");

    final prevIndex =
        exemptPlayers.indexWhere((player) => player.index == index);

    if (prevIndex != -1) {
      exemptPlayers[prevIndex] =
          exemptPlayers[prevIndex].copyWith(action: "close");
    } else {
      exemptPlayers.add(ExemptPlayer(
          index: index, playerId: playerId, action: "close", time: gameTime));
    }

    final activePlayersCount = getActivePlayersIndices().length;
    if (activePlayersCount > 1) {
      if (index == currentPlayer) {
        changePlayer();
      }
      pauseIndex = currentPlayer;
    }

    if (gameId.isEmpty) {
      showAllPlayersToast("${getPlayerUsername(playerIndex: index)} closed");
    } else {
      showToast("${getPlayerUsername(playerId: playerId)} closed");
    }
    setState(() {});
  }

  void unclose([String? playerId, bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      if (!startingRound && !finishedRound) {
        setActionDetails("unclose");
      }
      updateMyAction("start");
      unclose(myId, false);
      return;
    }

    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    //onUnClose(index);

    if (gameId.isEmpty && !isWatch) setActionDetails("unclose");

    final prevIndex = exemptPlayers.indexWhere(
        (player) => player.index == index && player.action == "close");

    if (prevIndex != -1) {
      exemptPlayers.removeAt(prevIndex);
    }

    final activePlayersCount = getActivePlayersIndices().length;
    if (activePlayersCount > 1) {
      if (index == currentPlayer) {
        changePlayer();
      }
      pauseIndex = currentPlayer;
    }

    if (gameId.isEmpty) {
      showAllPlayersToast(
          "${getPlayerUsername(playerIndex: index)} resumed game");
    } else {
      showToast("${getPlayerUsername(playerId: playerId)} resumed game");
    }
    setState(() {});
  }

  void concede([String? playerId, bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      if (isPuzzle) {
        setGatheredDetails();
      }
      setActionDetails("concede");

      concede(myId, false);

      return;
    }
    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    onConcede(index);

    if (gameId.isEmpty && !isWatch) setActionDetails("concede");

    final prevIndex =
        exemptPlayers.indexWhere((player) => player.index == index);

    if (prevIndex != -1) {
      exemptPlayers[prevIndex] =
          exemptPlayers[prevIndex].copyWith(action: "concede");
    } else {
      exemptPlayers.add(ExemptPlayer(
          index: index, playerId: playerId, action: "concede", time: gameTime));
    }

    final activePlayersCount = getActivePlayersIndices().length;

    if (activePlayersCount > 1) {
      if (index == currentPlayer) {
        changePlayer();
      }
      pauseIndex = currentPlayer;
    }

    if (activePlayersCount == 1) {
      updateWin(getNextPlayerIndex(index),
          reason:
              "${getPlayerUsername(playerIndex: index, playerId: playerId)} conceded");
    } else if (activePlayersCount < 1) {
      if (!finishedRound) {
        updateMatchRound(null);
      }
    }
    if (gameId.isEmpty) {
      showAllPlayersToast("${getPlayerUsername(playerIndex: index)} conceded");
    } else {
      showToast("${getPlayerUsername(playerId: playerId)} conceded");
    }
    setState(() {});
  }

  void leave([String? playerId, bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      if (isPuzzle) {
        setGatheredDetails();
      }

      if (startingRound || finishedRound) {
        try {
          await updateMyAction("leave");
          updateMyAction("");
        } catch (e) {}
      } else {
        setActionDetails("leave");
      }

      leave(myId, false);

      if (!mounted) return;
      context.pop();
      return;
    }

    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    // if (exemptPlayers.indexWhere((element) => element.index == index) != -1) {
    //   return;
    // }

    onLeave(index);
    if (gameId.isEmpty && !isWatch) setActionDetails("leave");

    final prevIndex =
        exemptPlayers.indexWhere((player) => player.index == index);

    if (prevIndex != -1) {
      exemptPlayers[prevIndex] =
          exemptPlayers[prevIndex].copyWith(action: "leave");
    } else {
      exemptPlayers.add(ExemptPlayer(
          index: index, playerId: playerId, action: "leave", time: gameTime));
    }

    // availablePlayersCount = getAvailablePlayersIndices().length;

    // final activePlayersCount = getActivePlayersIndices().length;

    if (activePlayersCount > 1) {
      if (index == currentPlayer) {
        changePlayer();
      }
      pauseIndex = currentPlayer;
    }

    if (availablePlayersCount < 2) {
      match?.available_players = [];
    } else {
      match?.available_players?.remove(playerId);
    }

    if (startingRound || finishedRound) {
      if (activePlayersCount < 2) {
        if (match != null) {
          uploadMatch(match!);
        }
        updateGameAction("close");
      }
    } else {
      if (activePlayersCount == 1) {
        updateWin(getNextPlayerIndex(index),
            reason:
                "${getPlayerUsername(playerIndex: index, playerId: playerId)} left");
      } else if (activePlayersCount < 1) {
        if (!finishedRound) {
          updateMatchRound(null);
        }
      }
    }

    if (gameId.isEmpty) {
      showAllPlayersToast("${getPlayerUsername(playerIndex: index)} left");
    } else {
      showToast("${getPlayerUsername(playerId: playerId)} left");
    }
    setState(() {});
  }

  void toggleMenu(int index) {
    if (isCheckoutMode) {
      isCheckoutMode = false;
    } else if (isWatchMode) {
      stopWatching(false);
    }
    pauseIndex = index;
    setState(() {});
  }

  void toggleCall(String? callMode, [bool isClick = true]) async {
    if (!mounted) return;
    if (isClick && gameId.isNotEmpty) {
      updateMyCallMode(callMode);
      return;
    }

    setState(() {});
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

  bool get isWatch {
    if (gameId.isEmpty) {
      return finishedRound;
    }
    if (finishedRound ||
        (match?.available_players != null &&
            match!.available_players!.indexWhere((player) => player == myId) ==
                -1)) {
      return true;
    }
    final myExemptPlayer = getMyExemptPlayer();
    if (myExemptPlayer != null &&
        (myExemptPlayer.action == "leave" ||
            myExemptPlayer.action == "concede")) {
      return true;
    }

    final timeStart =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_start"];
    final timeEnd =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_end"];

    return timeStart != null && timeEnd != null;
  }

  void saveMatch(Match match) {
    // final gameListBox = Hive.box<String>("gamelists");
    // final prevGameListJson = gameListBox.get(gameId);
    // if (prevGameListJson != null) {
    //   final prevGameList = GameList.fromJson(prevGameListJson);
    //   prevGameList.match = match;
    //   prevGameList.time_modified = match.time_modified;
    //   prevGameList.user_id = myId;
    //   ref.read(gamelistProvider.notifier).updateGameList(prevGameList);
    // }
    ref.read(matchProvider.notifier).updateMatch(match);
  }

  void updateMatchRecord() {
    if (finishedRound) return;
    final time = timeNow;

    if (this.match == null || this.match!.players == null) {
      setState(() {});

      return;
    }
    Match match = this.match!;
    if (match.records?["$recordId"]?["rounds"]?["$roundId"] != null) return;

    // Match prevMatch = match.copyWith();
    bool started = match.time_start == null;

    match.time_start ??= time;
    if (!match.games!.contains(gameName)) {
      match.games!.add(gameName);
    }

    match.available_players ??= [...match.players!];

    match.records ??= {};

    if (match.records?["$recordId"] == null) {
      match.records!["$recordId"] = MatchRecord(
          id: recordId,
          game: gameName,
          time_start: time,
          players: players.map((e) => e.id).toList(),
          scores: playersScores.toMap(),
          rounds: {}).toMap().removeNull();
    }
    if (match.records?["$recordId"]?["rounds"]?["$roundId"] == null) {
      match.records!["$recordId"]["rounds"]["$roundId"] = MatchRound(
              id: recordId,
              game: gameName,
              time_start: time,
              scores: playersScores.toMap(),
              players: players.map((e) => e.id).toList(),
              closed_players: getClosedPlayers(),
              detailsLength: 0,
              duration: 0)
          .toMap()
          .removeNull();

      final matchOutcome =
          getMatchOutcome(getMatchOverallScores(match), [...match.players!]);

      match.outcome = matchOutcome.outcome;
      match.winners = matchOutcome.winners;
      match.others = matchOutcome.others;
      uploadMatch(match, time);
      // if (started) {
      //   analytics.logEvent(
      //     name: 'online_match_started',
      //     parameters: match.toMap().removeNull().cast(),
      //   );
      // }
    }
  }

  void uploadMatch(Match match, [String? time]) {
    time ??= timeNow;
    bool ended = false;
    if ((match.available_players?.length ?? 0) < 2) {
      match.time_end = time;
      ended = true;
    }
    final availablePlayers = getAvailablePlayersIndices();

    if (gameId.isNotEmpty &&
        ((winners ?? []).isNotEmpty
            ? myPlayer == winners!.first
            : availablePlayers.isNotEmpty
                ? myPlayer == availablePlayers.first
                : currentPlayerId == myId)) {
      match.time_modified = time;
      match.user_id = myId;

      updateMatch(match);
      saveMatch(match);
      // if (ended) {
      //   analytics.logEvent(
      //     name: 'match_ended',
      //     parameters: match.toMap().removeNull().cast(),
      //   );
      // }
    }
  }

  void stopListening() {
    detailsSub?.cancel();
    detailsSub = null;
    playersSub?.cancel();
    playersSub = null;
    // callSetStateSub?.cancel();
    // callSetStateSub = null;
  }

  void updateMatchRound(List<int>? winners, [bool isOutcome = true]) {
    // if (!isOutcome && finishedRound) return;
    if (finishedRound) return;

    endDuration = duration;
    gameDetailsLength = gameDetails.length;
    finishedRound = true;

    pause();

    this.winners = winners;
    if (winners != null) {
      for (int i = 0; i < winners.length; i++) {
        final player = winners[i];
        playersScores[player]++;
      }
    }
    widget.arguments?["playersScores"] = playersScores;

    if (isPuzzle) {
      setGatheredDetails();
    }
    final time = timeNow;

    if (this.match == null || this.match!.players == null) {
      setState(() {});
      return;
    }
    Match match = this.match!;

    // Match prevMatch = match.copyWith();

    match.time_start ??= time;

    match.records ??= {};

    if (match.records!["$recordId"] != null) {
      match.records!["$recordId"]["scores"] = playersScores.toMap();

      if (match.records!["$recordId"]["rounds"] == null) {
        match.records!["$recordId"]["rounds"] = {};
      }
      if (match.records!["$recordId"]["rounds"]["$roundId"] != null) {
        match.records!["$recordId"]["rounds"]["$roundId"]["scores"] =
            playersScores.toMap();
        match.records!["$recordId"]["rounds"]["$roundId"]["winners"] = winners;
        match.records!["$recordId"]["rounds"]["$roundId"]["time_end"] = time;
        match.records!["$recordId"]["rounds"]["$roundId"]["detailsLength"] =
            gameDetailsLength;
        match.records!["$recordId"]["rounds"]["$roundId"]["duration"] =
            endDuration;
      }
      match.records!["$recordId"]["time_end"] = time;

      final matchOutcome =
          getMatchOutcome(getMatchOverallScores(match), [...match.players!]);

      match.outcome = matchOutcome.outcome;
      match.winners = matchOutcome.winners;
      match.others = matchOutcome.others;

      uploadMatch(match, time);
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
    final exemptPlayer = getExemptPlayer(index);
    double opacity = exemptPlayer != null ? 0.3 : 1;

    final userId = getPlayerId(index);
    if (userId == null) return opacity;

    final visibility = videoOverlayVisibility[userId];
    switch (visibility) {
      case "show":
        return opacity;
      case "faint":
        return exemptPlayer != null ? 0.3 : 0.5;
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

  int getLayoutTurn([bool isOptionMenu = false]) {
    if (!isOptionMenu && playersSize == 1) return 2;
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
    if (gameName.isQuiz) {
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

  void toggleLayoutPressed() {
    // if (isCheckoutMode) {
    //   setState(() {
    //     isCheckoutMode = false;
    //   });
    // }
    if (isWatchMode && !showWatchControls) {
      showWatchControls = true;
      setState(() {});
    }
  }

  void updateGamePageInfos() {
    pageInfos = ref.watch(gamePageInfosProvider);
  }

  bool get isLastPage =>
      recordId == pageInfos?.lastRecordId &&
      roundId == pageInfos?.lastRecordIdRoundId;
  bool get isFirstPage => recordId == 0 && roundId == 0;

  Widget? buildVideoView(int index) {
    if (gameId.isEmpty || players.isEmpty) return null;
    final playerId = getPlayerId(index);
    if (playerId == null) return null;
    // if (playerId == null ||
    //     (playerId == myId && _localRenderer == null) ||
    //     (playerId != myId && _remoteRenderers[playerId] == null)) {
    //   return null;
    // }
    final videoRenderer = playerId == myId
        ? widget.gameCallUtils.getMyRenderer()
        : widget.gameCallUtils.getPeerRenderer(playerId);
    // playerId == myId ? _localRenderer! : _remoteRenderers[playerId]!,
//isFrontCameraSelected
    return RotatedBox(
      quarterTurns: getVideoViewTurn(index),
      child: videoRenderer != null
          ? RTCVideoView(
              videoRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: playerId == myId &&
                  widget.gameCallUtils.isFrontCameraSelected,
            )
          : Container(),
    );
  }

  Widget getPlayerBottomWidget(int index) {
    final exemptPlayer = getExemptPlayer(index);
    final user = users != null && index < users!.length ? users![index] : null;
    return IgnorePointer(
      ignoring: exemptPlayer != null &&
          exemptPlayer.action == "leave" &&
          !finishedRound,
      child: RotatedBox(
        quarterTurns: getStraightTurn(index),
        child: GestureDetector(
          onTap: () {
            if (finishedRound && isCheckoutMode && (isQuiz || isPuzzle)) {
              changePlayer(player: index);
            }
          },
          child: Container(
            height: 30,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilePhoto(
                  profilePhoto: user?.profile_photo,
                  name: getPlayerUsername(playerIndex: index),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    getPlayerUsername(playerIndex: index),
                    style: TextStyle(
                        fontSize: 12,
                        color: currentPlayer == index ? Colors.blue : tint),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (playersCounts.isNotEmpty &&
                    index < playersCounts.length &&
                    playersCounts[index] != -1) ...[
                  const SizedBox(width: 4),
                  CountWidget(count: playersCounts[index]),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getMenuWidget(int index) {
    if (paused && pauseIndex == index && !isCheckoutMode) return Container();
    if (gameId.isNotEmpty && index != myPlayer && !isCheckoutMode) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        toggleMenu(index);
        if (!paused) {
          pause();
        }
      },
      child: Container(
        height: 20,
        width: 20,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: primaryColor, borderRadius: BorderRadius.circular(5)),
        child: Icon(EvaIcons.menu_outline, color: tint, size: 15),
      ),
    );
    // return IconButton(
    //   style: IconButton.styleFrom(
    //     padding: const EdgeInsets.all(2),
    //   ),
    //   onPressed: () {
    //     toggleMenu(index);
    //     if (!paused) {
    //       pause();
    //     }
    //   },
    //   icon: Icon(EvaIcons.menu_outline, color: tint),
    // );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // print("hasVideo = ${widget.gameCallUtils.getMyRenderer()}");
    updateGamePageInfos();
    // print("match = $match");
    // print("gameDetails = $gameDetails");
    // print("players = $players");
    // print("exemptPlayers = $exemptPlayers");

    final currentMatch = ref.watch(matchProvider);

    if (match?.match_id != null &&
        currentMatch?.match_id != null &&
        match!.match_id == currentMatch!.match_id &&
        match!.time_modified != currentMatch.time_modified) {
      match = currentMatch;
      // setState(() {});
      // print("updatedMatch = $match");
    }
    // print("currentMatch = $currentMatch");

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
        } else if (isWatchMode) {
          stopWatching(false);
        } else if (!paused) {
          pause();
        }
      },
      child: VisibilityDetector(
        key: Key(
            "${widget.arguments?["recordId"]}-${widget.arguments?["roundId"]}"),
        onVisibilityChanged: (visibility) {
          isVisible = visibility.visibleFraction > 0.5;
          if (isVisible) {
            _focusNode.requestFocus();
          } else {
            if (isWatchMode) {
              if (watching) {
                stopWatching();
              }
            } else {
              if (!paused) {
                pause();
              }
            }
          }
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Scaffold(
            body: Stack(
              //alignment: Alignment.center,
              children: [
                RotatedBox(
                  quarterTurns: getLayoutTurn(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isCard) ...[
                        ...List.generate(playersSize, (index) {
                          final videoView = buildVideoView(index);
                          final exemptPlayer = getExemptPlayer(index);
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
                                                exemptPlayer != null
                                                    ? getExemptPlayerMessage(
                                                        exemptPlayer)
                                                    : getMessage(index),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color:
                                                      itsMyTurnForMessage(index)
                                                          ? primaryColor
                                                          : tint,
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
                                                              playersSize >
                                                                  2) ||
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
                                                      exemptPlayer != null &&
                                                          !finishedRound,
                                                  child: buildBottomOrLeftChild(
                                                      index)),
                                            ),
                                            if (exemptPlayer == null &&
                                                index < playersToasts.length &&
                                                playersToasts[index] != "") ...[
                                              Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: RotatedBox(
                                                  quarterTurns:
                                                      getStraightTurn(index),
                                                  child: AppToast(
                                                    message:
                                                        playersToasts[index],
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
                          final exemptPlayer = getExemptPlayer(index);
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
                                            quarterTurns:
                                                getStraightTurn(index),
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
                                            quarterTurns:
                                                getStraightTurn(index),
                                            child: GameTimer(
                                              timerStream:
                                                  timerController.stream,
                                              time: exemptPlayer?.time,
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
                                    (!landScape &&
                                        index == 1 &&
                                        playersSize > 2)
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
                                                (index == 1 &&
                                                    playersSize == 2)))
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
                            final exemptPlayer = getExemptPlayer(index);
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    RotatedBox(
                                                      quarterTurns:
                                                          getStraightTurn(
                                                              index),
                                                      child: SizedBox(
                                                        height: 70,
                                                        child: Text(
                                                          '${playersScores[index]}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 60,
                                                              color:
                                                                  lighterTint),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    RotatedBox(
                                                      quarterTurns:
                                                          getStraightTurn(
                                                              index),
                                                      child: GameTimer(
                                                        timerStream:
                                                            timerController
                                                                .stream,
                                                        time:
                                                            exemptPlayer?.time,
                                                      ),
                                                    ),
                                                    // if ((currentPlayer ==
                                                    //             index &&
                                                    //         showMessage) ||
                                                    //     exemptPlayer !=
                                                    //         null) ...[
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
                                                              exemptPlayer !=
                                                                      null
                                                                  ? getExemptPlayerMessage(
                                                                      exemptPlayer)
                                                                  : getMessage(
                                                                      index),
                                                              // : "${itsMyTurnForMessage(index) ? "${message.isNotEmpty ? message : "Play"} - " : ""}${playersTimes[index].toDurationString(false)}",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color: itsMyTurnForMessage(
                                                                          index)
                                                                      ? primaryColor
                                                                      : tint),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            );
                                                          }),
                                                    ),
                                                    //],
                                                  ],
                                                ),
                                                Expanded(
                                                  child: IgnorePointer(
                                                    ignoring:
                                                        exemptPlayer != null &&
                                                            !finishedRound,
                                                    child: Container(
                                                      alignment: Alignment
                                                          .bottomCenter,
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
                          behavior: isWatch && !isCheckoutMode
                              ? HitTestBehavior.opaque
                              : null,
                          onTap: isWatch && !isCheckoutMode
                              ? toggleLayoutPressed
                              : null,
                          child: buildBody(context)),
                    ],
                  ),
                ),
                // if (loadingDetails)
                //   Center(
                //     child: SizedBox(
                //       width: 60,
                //       height: 60,
                //       child: CircularProgressIndicator(
                //           color: Colors.white.withOpacity(0.5), strokeWidth: 2),
                //     ),
                //   ),
                if (!paused &&
                    isWatchMode &&
                    !isCheckoutMode &&
                    showWatchControls)
                  WatchGameControlsView(
                    watchTimerController: watchTimerController,
                    showWatchControls: showWatchControls,
                    users: users,
                    players: players,
                    playersSize: playersSize,
                    finishedRound: finishedRound,
                    duration: duration,
                    endDuration: endDuration,
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

                if (paused &&
                    !isCheckoutMode &&
                    pauseIndex != -1 &&
                    !loadingDetails)
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
                      isFirstPage: isFirstPage,
                      isLastPage: isLastPage,
                      availablePlayersCount: availablePlayersCount,
                      onWatch: watch,
                      onRewatch: rewatch,
                      onStart: start,
                      onContinue: continueMatch,
                      onRestart: restart,
                      onChange: change,
                      onLeave: leave,
                      onClose: close,
                      onConcede: concede,
                      onPrevious: previous,
                      onNext: next,
                      onCheckOut: showCheckout,
                      onReadAboutGame: readAboutTheGame,
                      callMode: widget.gameCallUtils.callMode,
                      onToggleCall: widget.gameCallUtils.toggleCall,
                      isFrontCamera: widget.gameCallUtils.isFrontCameraSelected,
                      onToggleCamera: widget.gameCallUtils.toggleCamera,
                      isAudioOn: widget.gameCallUtils.isAudioOn,
                      onToggleMute: widget.gameCallUtils.toggleMic,
                      isSpeakerOn: widget.gameCallUtils.isOnSpeaker,
                      onToggleSpeaker: widget.gameCallUtils.toggleSpeaker,
                      // callMode: callMode,
                      // onToggleCall: toggleCall,
                      // isFrontCamera: isFrontCameraSelected,
                      // onToggleCamera: toggleCamera,
                      // isAudioOn: isAudioOn,
                      // onToggleMute: toggleMute,
                      // isSpeakerOn: isOnSpeaker,
                      // onToggleSpeaker: toggleSpeaker,
                      quarterTurns: getPausedGameTurn(),
                      pauseIndex: pauseIndex,
                      exemptPlayers: exemptPlayers,
                      winners: winners,
                      duration: duration,
                      endDuration: endDuration,
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
                  )
                ],
                if (gameId.isNotEmpty && !isConnectedToInternet)
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          "No Internet Connection",
                          style:
                              context.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                // if (isCheckoutMode)
                //   Text(
                //     "Press back to Exit Checkout Mode",
                //     style: context.bodySmall,
                //   )
                RotatedBox(
                    quarterTurns: getLayoutTurn(true),
                    child: Stack(
                      children: List.generate(playersSize, (index) {
                        if (isCard) {
                          return Positioned(
                            top: index == 0 || (index == 1 && playersSize > 2)
                                ? 0
                                : null,
                            bottom: (index == 1 && playersSize == 2) ||
                                    index == 2 ||
                                    (index == 3)
                                ? 0
                                : null,
                            left: index == 3 || (index == 0) ? 0 : null,
                            right: (index == 1 && playersSize > 2) ||
                                    (((index == 1 && playersSize == 2) ||
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
                                child: getMenuWidget(index)),
                          );
                        } else {
                          final mindex = (playersSize / 2).ceil();
                          return Positioned(
                              top: playersSize > 1 && index < mindex ? 0 : null,
                              bottom: playersSize == 1 || index >= mindex
                                  ? 0
                                  : null,
                              left:
                                  playersSize > 1 && (index == 0 || index == 3)
                                      ? 0
                                      : null,
                              right:
                                  playersSize == 1 || index == 1 || index == 2
                                      ? 0
                                      : null,
                              child: getMenuWidget(index));
                        }
                      }),
                    )),
                if (loadingDetails)
                  Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.5), strokeWidth: 2),
                    ),
                  ),
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
