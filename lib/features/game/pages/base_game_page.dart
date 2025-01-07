// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gamesarena/features/game/views/watch_game_controls_view.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/utils/constants.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../records/models/match_round.dart';
import '../models/concede_or_left.dart';
import '../models/game_action.dart';
import '../models/game_page_infos.dart';
import '../providers/game_action_provider.dart';
import '../providers/game_page_infos_provider.dart';
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

  int availablePlayersCount = 0;

  final Connectivity _connectivity = Connectivity();

  bool isVisible = true;
  bool isConnectedToInternet = true;

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

  List<int> playersLeft = [];
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
  int adsCount = 0;
  int adsTime = 0;
  bool adLoaded = false;
  bool awaiting = false;

  InterstitialAd? _interstitialAd;

  bool paused = true, startedRound = false, finishedRound = false;

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

    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    onInitState();
    init();
    resetPlayerTime();
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
  }

  @override
  void dispose() {
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
      users = arguments["users"];
      players = arguments["players"] ?? [];
      playersSize = arguments["playersSize"] ?? 2;
      indices = arguments["indices"];
      recordId = arguments["recordId"] ?? 0;
      roundId = arguments["roundId"] ?? 0;

      adsTime = arguments["adsTime"] ?? 0;
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
    checkSubscription();
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

  void showPlayersMessages(List<int> players, String message) {
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      playersMessages[player] = message;
    }
    setState(() {});
  }

  void showPlayersMessagesExcept(List<int> exceptedPlayers, String message) {
    final players = getActivePlayersIndices()
        .where((player) => !exceptedPlayers.contains(player))
        .toList();
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      playersMessages[player] = message;
    }
    setState(() {});
  }

  void showActivePlayersMessages(String message, [int? exceptedPlayer]) {
    final players = getActivePlayersIndices();
    if (exceptedPlayer != null) {
      players.remove(exceptedPlayer);
    }
    showPlayersMessages(players, message);
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
          if (gameId.isEmpty || currentPlayerId == myId) onPlayerTimeEnd();
          if (isPuzzle) {
            setGatheredDetails();
            resetPlayerTime();
          } else if (isChessOrDraught) {
            updateWin(getNextPlayerIndex(currentPlayer));
          }
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
      if ((key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.escape) &&
          !paused) {
        if (!finishedRound) {
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

  void updateMyAction(String action) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1 || players[index].action == action) return;
    await updatePlayerActionAndShowToast(gameId, action);

    players[index] = players[index].copyWith(action: action);
    showToast(action.isEmpty
        ? "You left"
        : "You $action${action.endsWith("e") ? "d" : "ed"}");
    executeGameAction();

    if (!mounted) return;
    setState(() {});
  }

  void updateMyChangedGame(String game) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1 || players[index].game == game) return;
    await updatePlayerActionAndShowToast(gameId, "pause", game);
    players[index] = players[index].copyWith(game: game, action: "pause");
    showToast("You changed game to $game");
    executeGameChange();
    if (!mounted) return;
    setState(() {});
  }

  void updateMyCallMode({String? callMode}) async {
    final index = players.indexWhere((element) => element.id == myId);
    if (index == -1 || players[index].callMode == callMode) return;
    // await updatePlayerActionAndShowToast(gameId, "pause", game);
    await executeCallAction(players[index]);

    players[index] = players[index].copyWith(callMode: callMode);

    if (!mounted) return;
    setState(() {});
  }

  void executeGameChange() {
    String newgame = getChangedGame(getAvailablePlayers());
    if (newgame.isEmpty || gameName == newgame) return;
    change(newgame, false);
  }

  String executeGameAction() {
    String action = getAction(getAvailablePlayers());
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

  void listenForInternetConnection() {
    if (gameId.isEmpty) return;
    connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      isConnectedToInternet = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi);
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
      } else {
        players = List.generate(playersSize,
            (index) => Player(id: "$index", time: timeNow, order: index));
      }
    }
    availablePlayersCount = gameId.isEmpty ? playersSize : players.length;

    if (gameId.isEmpty || match == null) return;
    players.sortList((player) => player.order, false);

    if (users == null || users!.isEmpty) {
      users = await playersToUsers(players.map((e) => e.id).toList());
    }

    final index = players.indexWhere((element) => element.id == myId);
    myPlayer = index;

    setState(() {});
    if (finishedRound) {
      return;
    }
    final lastTime = players
        .sortedList((player) => player.time_modified ?? "", false)
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
        final username = userIndex == -1
            ? ""
            : users![userIndex]?.user_id == myId
                ? "you"
                : users![userIndex]?.username ?? "";

        print("playersChange = $playersChange");

        if (playersChange.removed || value.matchId != matchId) {
          leave(value.id, false);
          print("leaving");

          value.game = null;
          value.matchId = "";
        }

        print("value = $value");

        if (playerIndex != -1) {
          final actionMessage = value.game != null && value.game != gameName
              ? "changed to ${value.game}"
              : players[playerIndex].action != value.action &&
                      (value.action ?? "").isNotEmpty
                  ? value.action ?? ""
                  : "";
          if (actionMessage.isNotEmpty) {
            final title =
                "$username ${value.game != gameName ? actionMessage : "$actionMessage${actionMessage.endsWith("e") ? "d" : "ed"}"}";
            if (value.game != null && value.game != gameName
                ? value.game != getMyPlayer(players)?.game
                : value.action != "pause" &&
                    value.action != "concede" &&
                    value.action != "leave" &&
                    value.action != "" &&
                    value.action != getMyPlayer(players)?.action) {
              final result = await context.showComfirmationDialog(
                  title: title,
                  message:
                      "Do you also want to ${value.game != gameName ? "change" : value.action!} game?");
              if (result == true) {
                if (value.game != null && value.game != gameName) {
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
                    restart();
                  } else if (value.action == "continue") {
                    continueMatch();
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
      }
    });
  }

  // int get end => (timeEnd ?? timeStart + (duration * 1000));

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
    if (detailsSub != null) {
      await detailsSub!.cancel();
      detailsSub = null;
    }

    final timeStart =
        match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_start"];

    // final timeEnd =
    //     match?.records?["$recordId"]?["rounds"]?["$roundId"]?["time_end"];

    var lastTime = gameDetails.lastOrNull?["time"];
    final playerIds = players.map((player) => player.id).toList();

    if (gameId.isNotEmpty) {
      if (timeStart != null) {
        loadingDetails = true;
        setState(() {});

        final foundGameDetails = await getGameDetails(
            gameId, matchId, recordId, roundId,
            time: lastTime,
            limit: isWatch && finishedRound ? watchDetailsLimit * 2 : null,
            players: playerIds);

        loadingDetails = false;
        gameDetails.addAll(foundGameDetails);

        if (foundGameDetails.isEmpty) {
          if (isWatch) stopWatching();
        } else {
          if (!isWatch) {
            availablePlayersCount =
                gameId.isEmpty ? playersSize : players.length;

            reason = "";
            message = "Play";
            duration = 0;
            gameTime = maxGameTime ?? 0;
            playersTimes[currentPlayer] = maxPlayerTime ?? 30;

            timerController.sink.add(gameTime);
            getCurrentPlayer();
            onStart();
            for (int i = 0; i < foundGameDetails.length; i++) {
              final gameDetail = foundGameDetails[i];
              updateGameDetails(gameDetail, readMoreDetails: true);
            }
            endDuration = gameDetails.lastOrNull?["duration"] ?? 0.0;
          }
        }
      }

      setState(() {});

      if (finishedRound) {
        return;
      }

      lastTime = gameDetails.lastOrNull?["time"];

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

  Future updateGameDetails(Map<String, dynamic> gameDetail,
      {bool readMoreDetails = false}) async {
    final playerId = gameDetail["id"];
    final duration = gameDetail["duration"];
    final playerTime = gameDetail["playerTime"] as int?;
    final playerIndex = getPlayerIndex(playerId);
    //currentPlayer = playerIndex;

    final action = gameDetail["action"];

    if (duration != null) {
      this.duration = (duration is int) ? duration.toDouble() : duration;
    }

    if (playerTime != null) {
      playersTimes[playerIndex] = playerTime;
    }

    if (action != null) {
      if (action == "concede") {
        concede(playerId, false);
      } else if (action == "leave") {
        leave(playerId, false);
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
        await updateGameDetails(detail);
      }
    }
  }

  Future setActionDetails(String action) async {
    if (gameDetails.isEmpty) return;
    await setGatheredDetails();
    setDetail({"action": action});
  }

  Future<List<Map<String, dynamic>>> setDetails(
      List<Map<String, dynamic>> details) async {
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
    detail["id"] = gameId.isEmpty ? "$currentPlayer" : myId;
    return detail.removeNull();
  }

  Future<Map<String, dynamic>> setDetail(Map<String, dynamic> detail,
      {bool add = true}) async {
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
      getConcedeOrLeft(player) != null;

  bool itsMyTurnToPlay(bool isClick, [int? player]) {
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

  void loadAd() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    if (kIsWeb || !isAndroidAndIos || privateKey == null) {
      return;
    }
    privateKey ??= await getPrivateKey();
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

  String getConcedeOrLeftMessage(ConcedeOrLeft concedeOrLeft) {
    return concedeOrLeft.action == "concede" ? "Conceded" : "Left";
  }

  String getMessage(int index) {
    String message = playersMessages[index];

    return "${itsMyTurnForMessage(index) ? "${message.isEmpty ? this.message.isNotEmpty ? this.message : "Play" : message} - " : message.isEmpty ? "" : "$message - "}${playersTimes[index].toDurationString(false)}";
  }

  // String getPlayerName(int player) {
  //   return users == null || users!.isEmpty || player >= users!.length
  //       ? "Player ${player + 1}"
  //       : users![player]?.username ?? "";
  // }

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

  // Future startOrRestart(bool start) async {
  //   if (gameId != "" && matchId != "") {
  //     await updateAction(context, players, users!, gameId, matchId,
  //         start ? "start" : "restart", gameName);
  //   }
  // }

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

  void stopWatching() {
    if (!isWatchMode || gameDetailsLength != gameDetails.length) return;

    resetWatchDetails();
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
          playersLeft: playersLeft,
          hasDetails: gameDetails.isNotEmpty,
          args: widget.arguments ?? {}),
    );
  }

  Future<dynamic> updatePlayerActionAndShowToast(
    String gameId,
    String action, [
    String? game,
  ]) async {
    final myPlaying = players.firstWhere((element) => element.id == myId);
    final myAction = myPlaying.action;
    final myGame = myPlaying.game;

    if (myAction == action && myGame == game) return;
    await updatePlayerAction(gameId, action, game);

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
      if (action.isEmpty && game == null) return;
      showToast(
          "Waiting for ${waitingUsers.toStringWithCommaandAnd((user) => user.username)} to also ${action != myAction ? action : "change to $game"}");
    }
  }

  void resetAllDetails() {
    availablePlayersCount = gameId.isEmpty ? playersSize : players.length;

    reason = "";
    message = "Play";
    duration = 0;
    gameTime = maxGameTime ?? 0;
    playersTimes[currentPlayer] = maxPlayerTime ?? 30;
    gatheredGameDetails.clear();
    concedeOrLeftPlayers.clear();

    isCheckoutMode = false;
    timerController.sink.add(gameTime);

    getCurrentPlayer();

    if (startingRound &&
        !finishedRound &&
        (gameId.isEmpty ||
            (myPlayer == playersSize - 1 &&
                match?.records?["$recordId"]?["rounds"]?["$roundId"] ==
                    null))) {
      onInit();
    }
    onStart();
  }

  void checkout() {
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

  void pause([bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      updateMyAction("pause");
      return;
    }
    stopTimer();
    onPause();
    setState(() {});
  }

  bool get startingRound =>
      maxGameTime != null ? gameTime == maxGameTime : gameTime == 0;

  void start([bool isClick = true]) async {
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
      updateMatchRecord();
      resetAllDetails();
    } else {
      onResume();
    }

    startTimer();
  }

  void continueMatch([bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      updateMyAction("continue");
      return;
    }
    if (!finishedRound) {
      updateMatchRound(null);
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
      updateMatchRound(null);
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
      updateMatchRound(null);
    }

    updateGameAction("change", game: game);
    stopListening();
  }

  void concede([String? playerId, bool isClick = true]) async {
    if (isClick && gameId.isNotEmpty) {
      if (loadingDetails) {
        showToast("Can't concede now, still loading details");
        return;
      }
      await setActionDetails("concede");

      concede(myId, false);

      return;
    }
    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    onConcede(index);

    if (gameId.isEmpty && !isWatch) setActionDetails("concede");

    concedeOrLeftPlayers.add(ConcedeOrLeft(
        index: index, playerId: playerId, action: "concede", time: gameTime));
    if (index == currentPlayer) {
      changePlayer();
    }
    pauseIndex = currentPlayer;
    final activePlayersCount = getActivePlayersIndices().length;

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
      if (loadingDetails) {
        showToast("Can't leave now, still loading details");
        return;
      }
      setActionDetails("leave");
      updateMyAction("");
      //leaveMatch(gameId, matchId, match, players);

      leave(myId, false);

      return;
    }

    final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
    if (concedeOrLeftPlayers.indexWhere((element) => element.index == index) !=
        -1) {
      return;
    }

    onLeave(index);
    if (gameId.isEmpty && !isWatch) setActionDetails("leave");

    concedeOrLeftPlayers.add(ConcedeOrLeft(
        index: index, playerId: playerId, action: "leave", time: gameTime));
    if (!playersLeft.contains(pauseIndex)) playersLeft.add(pauseIndex);
    if (index == currentPlayer) {
      changePlayer();
    }

    pauseIndex = currentPlayer;
    availablePlayersCount = getAvailablePlayersIndices().length;

    final activePlayersCount = getActivePlayersIndices().length;

    if (activePlayersCount == 1) {
      updateWin(getNextPlayerIndex(index),
          reason:
              "${getPlayerUsername(playerIndex: index, playerId: playerId)} left");
    } else if (activePlayersCount < 1) {
      if (!finishedRound) {
        updateMatchRound(null);
      }
    }

    if (gameId.isEmpty) {
      showAllPlayersToast("${getPlayerUsername(playerIndex: index)} left");
    } else {
      showToast("${getPlayerUsername(playerId: playerId)} left");
    }
    setState(() {});

    // if (availablePlayersCount < 2) {
    //   if (!mounted) return;
    //   context.pop();
    // }
  }

  void close() {
    if (!finishedRound) {
      pause();
    }

    context.pop();
  }

  void toggleMenu(int index) {
    pauseIndex = index;
    setState(() {});
  }

  void toggleCall(String? callMode, [bool isClick = true]) async {
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
    if (finishedRound) return;
    final time = timeNow;

    if (this.match == null) {
      setState(() {});

      return;
    }
    Match match = this.match!;
    if (match.records?["$recordId"]?["rounds"]?["$roundId"] != null) return;

    // Match prevMatch = match.copyWith();

    match.time_start ??= time;
    if (!match.games!.contains(gameName)) {
      match.games!.add(gameName);
    }

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
              detailsLength: 0,
              duration: 0)
          .toMap()
          .removeNull();

      final matchOutcome =
          getMatchOutcome(getMatchOverallScores(match), match.players!);

      match.outcome = matchOutcome.outcome;
      match.winners = matchOutcome.winners;
      match.others = matchOutcome.others;

      if (gameId.isNotEmpty &&
          // !isWatch &&
          (winners != null && winners!.isNotEmpty
              ? myPlayer == winners!.first
              : myPlayer == 0)) {
        match.time_modified = time;
        // updateMatch(match, prevMatch.toMap().getChangedProperties(match.toMap()));
        match.user_id = myId;
        updateMatch(match, match.toMap());
      }
    }
  }

  void stopListening() {
    detailsSub?.cancel();
    detailsSub = null;
    playersSub?.cancel();
    playersSub = null;
  }

  void updateMatchRound(List<int>? winners) {
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

    if (this.match == null) {
      setState(() {});
      return;
    }
    Match match = this.match!;

    // Match prevMatch = match.copyWith();

    match.time_start ??= time;

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
          getMatchOutcome(getMatchOverallScores(match), match.players!);

      match.outcome = matchOutcome.outcome;
      match.winners = matchOutcome.winners;
      match.others = matchOutcome.others;

      if (availablePlayersCount <= 1) {
        match.time_end = time;
      }

      match.time_modified = time;

      if (gameId.isNotEmpty &&
          // !isWatch &&
          (winners != null && winners.isNotEmpty
              ? myPlayer == winners.first
              : myPlayer == 0)) {
        match.user_id = myId;
        updateMatch(match, match.toMap());
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

  Widget getPlayerBottomWidget(int index) {
    final concedeOrLeft = getConcedeOrLeft(index);
    final user = users != null && index < users!.length ? users![index] : null;
    return IgnorePointer(
      ignoring: concedeOrLeft != null &&
          concedeOrLeft.action == "leave" &&
          !finishedRound,
      child: RotatedBox(
        quarterTurns: getStraightTurn(index),
        child: GestureDetector(
          onTap: () {
            if (finishedRound && isCheckoutMode) {
              changePlayer(player: index);
            }
          },
          child: Container(
            //height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
            child: Row(
              // mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }

  Widget getMenuWidget(int index) {
    if (paused && pauseIndex == index) return Container();
    if (gameId.isNotEmpty && index != myPlayer) return Container();

    return IconButton(
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(2),
      ),
      onPressed: () {
        toggleMenu(index);
        if (!paused) {
          pause();
        }
      },
      icon: Icon(EvaIcons.menu_outline, color: tint),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    updateGamePageInfos();

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
                                                      concedeOrLeft != null &&
                                                          !finishedRound,
                                                  child: buildBottomOrLeftChild(
                                                      index)),
                                            ),
                                            if (concedeOrLeft == null &&
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
                                                        // timerStream: index ==
                                                        //             1 &&
                                                        //         isChessOrDraught &&
                                                        //         timerController2 !=
                                                        //             null
                                                        //     ? timerController2!
                                                        //         .stream
                                                        //     : timerController
                                                        //         .stream,
                                                        time:
                                                            concedeOrLeft?.time,
                                                      ),
                                                    ),
                                                    // if ((currentPlayer ==
                                                    //             index &&
                                                    //         showMessage) ||
                                                    //     concedeOrLeft !=
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
                                                              concedeOrLeft !=
                                                                      null
                                                                  ? getConcedeOrLeftMessage(
                                                                      concedeOrLeft)
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
                                                        concedeOrLeft != null &&
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
                          behavior: isWatch ? HitTestBehavior.opaque : null,
                          onTap: isWatch ? toggleLayoutPressed : null,
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
                      onCheckOut: checkout,
                      onReadAboutGame: readAboutTheGame,
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
                    quarterTurns: getLayoutTurn(),
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
