// import 'dart:async';
// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
// import 'package:gamesarena/core/firebase/extensions/firestore_extensions.dart';
// import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
// import 'package:gamesarena/shared/services.dart';
// import 'package:gamesarena/shared/utils/constants.dart';
// import 'package:gamesarena/shared/extensions/extensions.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:icons_plus/icons_plus.dart';

// import '../../features/game/models/concede_or_left.dart';
// import '../../features/game/services.dart';
// import '../../features/game/utils.dart';
// import '../../features/games/card/whot/widgets/whot_card.dart';
// import '../../features/subscription/pages/subscription_page.dart';
// import '../../features/subscription/services/services.dart';
// import '../../features/user/services.dart';
// import '../../shared/dialogs/comfirmation_dialog.dart';
// import '../../shared/widgets/app_toast.dart';
// import '../../shared/widgets/game_timer.dart';
// import '../../main.dart';
// import '../../shared/models/models.dart';
// import '../../theme/colors.dart';
// import '../../shared/utils/utils.dart';
// import '../../features/game/pages/paused_game_page.dart';

// abstract class BaseGamePage extends StatefulWidget {
//   const BaseGamePage({
//     super.key,
//   });

//   @override
//   State<BaseGamePage> createState();
//   //State<BaseGamePage> createState() => _BaseGamePageState();
// }

// abstract class BaseGamePageState<T extends BaseGamePage> extends State<T>
//     with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
//   void onInitState();
//   void onDispose();
//   void onInit();
//   void onStart();
//   void onResume();
//   void onPause();
//   void onConcede(int index);
//   void onLeave(int index);
//   void onPlayerTimeEnd();
//   void onTimeEnd();
//   void onKeyEvent(KeyEvent event);
//   void onSpaceBarPressed();
//   Future onDetailsChange(Map<String, dynamic>? map);
//   void onPlayerChange(int player);
//   Widget buildBody(BuildContext context);
//   Widget buildBottomOrLeftChild(int index);

//   abstract int? maxPlayerTime;
//   abstract int? maxGameTime;

//   int playerTime = 0;
//   String gameName = "";
//   int pauseIndex = 0;
//   bool stopPlayerTime = false;

//   String matchId = "";
//   String gameId = "";
//   Match? match;
//   List<User?>? users;
//   int playersSize = 2;
//   String? indices;
//   int recordId = 0;

//   //Call
//   String? callMode;
//   bool calling = false;

//   StreamSubscription? signalSub;
//   bool isAudioOn = true,
//       isVideoOn = true,
//       isFrontCameraSelected = true,
//       isOnSpeaker = false;
//   RTCVideoRenderer? _localRenderer;
//   final Map<String, RTCVideoRenderer> _remoteRenderers = {};
//   final Map<String, RTCPeerConnection> _peerConnections = {};
//   final Map<String, String> videoOverlayVisibility = {};
//   //final Map<String, List<RTCIceCandidate>> _rtcIceCandidates = {};
//   MediaStream? _localStream;

//   //Player
//   bool isWatch = false;
//   bool finishedWatching = false;
//   bool awaitingReadDetails = false;

//   int watchInterval = 0;
//   int maxWatchInterval = 3;

//   Map<String, dynamic>? gatheredGameDetails;
//   List<Map<String, dynamic>>? gameDetails;
//   Map<int, List<Map<String, dynamic>>?> recordGameDetails = {};
//   int gameDetailIndex = -1;
//   StreamSubscription? playersSub;
//   StreamSubscription? detailsSub;
//   List<Player> players = [];

//   bool firstTime = false, seenFirstHint = false, readAboutGame = false;
//   bool changingGame = false;
//   bool isCheckoutMode = false;
//   String reason = "";
//   late StreamController<int> timerController;
//   StreamController<int>? timerController2;

//   //Time
//   Timer? timer;
//   int duration = 0, gameTime = 0, gameTime2 = 0;

//   //Ads
//   int adsCount = 0;
//   int adsTime = 0;
//   bool adLoaded = false;
//   bool awaiting = false;

//   InterstitialAd? _interstitialAd;

//   bool paused = true,
//       finishedRound = false,
//       checkout = false,
//       pausePlayerTime = false;

//   String currentPlayerId = "";
//   int currentPlayer = 0;
//   int myPlayer = 0;

//   //Sizing
//   double padding = 0;
//   double minSize = 0, maxSize = 0;
//   bool landScape = false;

//   //Card
//   double cardWidth = 0, cardHeight = 0;

//   String message = "", hintMessage = "";

//   List<int> playersCounts = [];
//   List<int> playersScores = [];
//   // List<int> players = [];
//   List<ExemptPlayer> exemptPlayers = [];

//   List<String> playersToasts = [];
//   List<String> playersMessages = [];

//   bool gottenDependencies = false;
//   bool isCard = false;
//   bool showMessage = true;
//   bool isChessOrDraught = false;
//   bool isPuzzle = false;
//   bool isQuiz = false;

//   //bool notNeedPlayertime = false;
//   bool isMyTurn = false;
//   bool detailsSent = false;

//   final FocusNode _focusNode = FocusNode();
//   int availableDuration = 0;
//   bool? isSubscribed;

//   @override
//   void initState() {
//     super.initState();
//     maxPlayerTime ??= 30;
//     resetPlayerTime();

//     WidgetsBinding.instance.addObserver(this);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
//     onInitState();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     landScape = context.isLandscape;
//     minSize = context.minSize;
//     maxSize = context.maxSize;
//     padding = context.remainingSize;
//     cardHeight = (minSize - 80) / 3;
//     cardWidth = cardHeight.percentValue(65);
//     // padding = (context.screenHeight - context.screenWidth).abs() / 2;
//     if (!gottenDependencies) {
//       if (context.args != null) {
//         gameName = context.args["gameName"] ?? "";
//         matchId = context.args["matchId"] ?? "";
//         gameId = context.args["gameId"] ?? "";
//         match = context.args["match"];

//         users = context.args["users"];
//         players = context.args["players"] ?? [];
//         playersSize = context.args["playersSize"] ?? 2;
//         indices = context.args["indices"];
//         recordId = context.args["recordId"] ?? 1;
//         recordGameDetails = context.args["recordGameDetails"] ?? {};
//         isWatch = context.args["isWatch"] ?? false;
//         adsTime = context.args["adsTime"] ?? 0;
//       }
//       gottenDependencies = true;
//       init();
//     }
//   }

//   @override
//   void dispose() {
//     timerController.close();
//     timerController2?.close();

//     WidgetsBinding.instance.removeObserver(this);
//     if (!changingGame) {
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//           overlays: SystemUiOverlay.values);
//     }
//     detailsSub?.cancel();
//     playersSub?.cancel();
//     disposeForCall();

//     stopTimer();
//     _interstitialAd?.dispose();
//     _interstitialAd = null;
//     onDispose();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.inactive) {
//       if (!paused ||
//           (gameId.isNotEmpty && getMyPlayer(players)?.action != "pause")) {
//         pause();
//       }
//     }
//   }

//   bool get isMyMove =>
//       !awaiting && gameId.isNotEmpty && currentPlayerId == myId;

//   void resetPlayerTime() {
//     stopPlayerTime = false;
//     playerTime = maxPlayerTime!;
//   }

//   void stopTimer() {
//     paused = true;
//     timer?.cancel();
//     timer = null;
//   }

//   void startTimer() {
//     pausePlayerTime = false;
//     paused = false;
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted || awaiting) return;

//       if (isWatch && !finishedWatching && !awaitingReadDetails) {
//         if (watchInterval >= maxWatchInterval) {
//           readDetails();
//           watchInterval = 0;
//         } else {
//           watchInterval++;
//         }
//       }
//       if (isSubscribed != null) {
//         if (isSubscribed!) {
//           if (availableDuration > 0) {
//             availableDuration--;
//           } else {
//             showToast(
//                 "Your subscription has expired. Please subscribe to continue without ads");
//             gotoSubscription();
//           }
//         }
//         if (availableDuration == 0) {
//           if (adsTime >= maxAdsTime) {
//             loadAd();
//             adsTime = 0;
//           } else {
//             adsTime++;
//           }
//         }
//       }

//       duration++;

//       if (currentPlayer == 1 && isChessOrDraught) {
//         if (maxGameTime != null && gameTime2 <= 0) {
//           timer.cancel();
//           onTimeEnd();
//           updateWin(0);
//         }

//         gameTime2--;
//         timerController2?.sink.add(gameTime2);
//       } else {
//         if (maxGameTime != null && gameTime <= 0) {
//           timer.cancel();
//           onTimeEnd();
//           if (isChessOrDraught) {
//             updateWin(1);
//           }
//         }
//         if (maxGameTime != null) {
//           gameTime--;
//         } else {
//           gameTime++;
//         }
//         timerController.sink.add(gameTime);
//       }
//       if (!isChessOrDraught && !stopPlayerTime) {
//         if (playerTime <= 0) {
//           playerTime = maxPlayerTime!;
//           onPlayerTimeEnd();
//           //changePlayer();
//           setState(() {});
//           if (isPuzzle && gatheredGameDetails != null) {
//             setDetail(gatheredGameDetails!);
//             gatheredGameDetails = null;
//           }
//         } else {
//           playerTime--;
//         }
//       }
//     });
//   }

//   void checkSubscription() async {
//     final duration = await getAvailableDuration();
//     isSubscribed = duration.isSubscription;
//     availableDuration = duration.duration;
//   }

//   void gotoSubscription() {
//     context.pushTo(const SubscriptionPage());
//   }

//   bool _onKey(KeyEvent event) {
//     final key = event.logicalKey;
//     if (event is KeyDownEvent) {
//       if ((key == LogicalKeyboardKey.backspace ||
//               key == LogicalKeyboardKey.escape) &&
//           !paused) {
//         pause();
//       } else if (key == LogicalKeyboardKey.enter && paused) {
//         start();
//       } else if (key == LogicalKeyboardKey.space && !paused) {
//         onSpaceBarPressed();
//       } else {
//         onKeyEvent(event);
//       }
//     }
//     return false;
//   }

//   void getCurrentPlayer() {
//     if (gameId != "") {
//       final playerIds = users!.map((e) => e!.user_id).toList();
//       currentPlayerId = isPuzzle || isQuiz ? myId : playerIds.last;
//       final currentPlayerIndex =
//           playerIds.indexWhere((element) => element == currentPlayerId);
//       currentPlayer = currentPlayerIndex;
//     } else {
//       currentPlayer = playersSize - 1;
//     }
//     // print("getCurrentPlayer = $currentPlayer");
//   }

//   int getPlayerIndex(String playerId) {
//     if (gameId != "") {
//       final playerIds = users!.map((e) => e!.user_id).toList();
//       final currentPlayerIndex =
//           playerIds.indexWhere((element) => element == playerId);
//       return currentPlayerIndex;
//     } else {
//       return -1;
//     }
//   }

//   void changePlayer({int? player, bool suspend = false}) {
//     if (player != null) {
//       onPlayerChange(player);

//       currentPlayer = player;
//       final playerId = getPlayerId(currentPlayer);
//       if (playerId != null) {
//         currentPlayerId = playerId;
//       }

//       setState(() {});
//       return;
//     }
//     playerTime = maxPlayerTime!;
//     //message = "Play";
//     getNextPlayer();
//     if (suspend) getNextPlayer();
//     setState(() {});
//   }

//   void resetExemptPlayer() {
//     // if (gameId.isNotEmpty) {
//     //   exemptPlayers.removeWhere((element) =>
//     //       element.action == "leave" &&
//     //       players
//     //               .firstWhereNullable((player) => player.id == element.playerId)
//     //               ?.matchId ==
//     //           matchId);
//     // }

//     // exemptPlayers.removeWhere((element) => element.action == "concede");
//     // setState(() {});

//     if (exemptPlayers.isEmpty) return;
//     List<int> newScores = getNewPlayersScores();

//     for (int i = 0; i < exemptPlayers.length; i++) {
//       final exemptPlayer = exemptPlayers[i];
//       final playerId = exemptPlayer.playerId;
//       final action = exemptPlayer.action;
//       if (action == "concede") continue;
//       users?.removeWhere((element) => element?.user_id == playerId);
//       players.removeWhere((element) => element.id == playerId);

//       playersSize -= 1;
//     }

//     playersScores = newScores;
//     initPlayersCounts();
//     initToasts();
//     initMessages();
//     if (users != null) {
//       final index = users!
//           .indexWhere((element) => element != null && element.user_id == myId);
//       myPlayer = index;
//     }
//     exemptPlayers.clear();

//     setState(() {});
//   }

//   bool isPlayerActive(int player) {
//     return getExemptPlayer(player) == null;
//   }

//   bool isPlayerAvailable(int player) {
//     final exemptPlayer = getExemptPlayer(player);
//     return exemptPlayer == null || exemptPlayer.action == "concede";
//   }

//   ExemptPlayer? getExemptPlayer(int player) {
//     final index =
//         exemptPlayers.indexWhere((element) => element.index == player);
//     return index != -1 ? exemptPlayers[index] : null;
//   }

//   List<int> getNewPlayersScores() {
//     List<int> scores = [];
//     int length = gameId.isNotEmpty ? players.length : playersSize;
//     for (int i = 0; i < length; i++) {
//       if (exemptPlayers.indexWhere(
//               (element) => element.index == i && element.action == "leave") !=
//           -1) {
//         continue;
//       }
//       scores.add(playersScores[i]);
//     }
//     return scores;
//   }

//   List<Player> getActivePlayers() {
//     List<Player> activePlayers = [];
//     for (int i = 0; i < players.length; i++) {
//       final player = players[i];
//       if (exemptPlayers
//               .indexWhere((element) => element.playerId == player.id) !=
//           -1) {
//         continue;
//       }
//       activePlayers.add(player);
//     }
//     return activePlayers;
//   }

//   List<Player> getAvailablePlayers() {
//     List<Player> availablePlayers = [];
//     for (int i = 0; i < players.length; i++) {
//       final player = players[i];
//       if (exemptPlayers.indexWhere((element) =>
//               element.playerId == player.id && element.action == "leave") !=
//           -1) {
//         continue;
//       }
//       availablePlayers.add(player);
//     }
//     return availablePlayers;
//   }

//   List<int> getActivePlayersIndices() {
//     List<int> players = [];
//     int length = gameId.isNotEmpty ? players.length : playersSize;

//     for (int i = 0; i < length; i++) {
//       if (exemptPlayers.indexWhere((element) => element.index == i) !=
//           -1) {
//         continue;
//       }
//       players.add(i);
//     }
//     return players;
//   }

//   List<int> getAvailablePlayersIndices() {
//     List<int> players = [];
//     int length = gameId.isNotEmpty ? players.length : playersSize;

//     for (int i = 0; i < length; i++) {
//       if (exemptPlayers.indexWhere(
//               (element) => element.index == i && element.action == "leave") !=
//           -1) {
//         continue;
//       }
//       players.add(i);
//     }
//     return players;
//   }

//   List<String> getPlayersUsernames(List<int> players) {
//     return players
//         .map((player) => getPlayerUsername(playerIndex: player))
//         .toList();
//   }

//   String getPlayerUsername({String? playerId, int playerIndex = 0}) {
//     final index = users?.indexWhere((e) => e?.user_id == playerId) ?? -1;
//     return index != -1 ? users![index]!.username : "Player ${playerIndex + 1}";
//   }

//   int getPrevPlayerIndex([int? playerIndex]) {
//     final indices = getActivePlayersIndices();
//     if (indices.isEmpty) return -1;
//     if (indices.length == 1) return indices.first;
//     int index = (playerIndex ?? currentPlayer);
//     int length = gameId.isNotEmpty ? players.length : playersSize;
//     if (index < 0 || index > length - 1) return -1;
//     index = prevIndex(length, index);
//     while (indices.indexWhere((element) => element == index) == -1) {
//       index = prevIndex(length, index);
//     }

//     return index;
//   }

//   int getNextPlayerIndex([int? playerIndex]) {
//     final indices = getActivePlayersIndices();

//     if (indices.isEmpty) return -1;
//     if (indices.length == 1) return indices.first;
//     int index = (playerIndex ?? currentPlayer);

//     int length = gameId.isNotEmpty ? players.length : playersSize;
//     if (index < 0 || index > length - 1) return -1;
//     index = nextIndex(length, index);
//     while (indices.indexWhere((element) => element == index) == -1) {
//       index = nextIndex(length, index);
//     }
//     return index;
//   }

//   void getPrevPlayer() {
//     final index = getPrevPlayerIndex();
//     if (gameId.isNotEmpty) {
//       final playerIds = users!.map((e) => e!.user_id).toList();
//       currentPlayerId = playerIds[index];
//     }
//     onPlayerChange(index);
//     currentPlayer = index;
//   }

//   void getNextPlayer() {
//     final index = isPuzzle || isQuiz ? currentPlayer : getNextPlayerIndex();
//     if (gameId.isNotEmpty) {
//       final playerIds = users!.map((e) => e!.user_id).toList();
//       currentPlayerId = playerIds[index];
//     }
//     onPlayerChange(index);

//     currentPlayer = index;
//   }

//   int getPartnerPlayer() {
//     if (playersSize == 2) return -1;
//     return myPlayer == 0
//         ? 1
//         : myPlayer == 1
//             ? 0
//             : myPlayer == 2
//                 ? 3
//                 : 2;
//   }

//   int getCardPartnerPlayer() {
//     if (playersSize == 2) return -1;
//     return myPlayer == 0
//         ? 2
//         : myPlayer == 2
//             ? 0
//             : myPlayer == 1 && playersSize > 2
//                 ? 3
//                 : 1;
//   }

//   // void getFirstPlayer() {
//   //   if (gameId != "") {
//   //     final playerIds = users!.map((e) => e!.user_id).toList();
//   //     currentPlayerId = playerIds.last;
//   //     final currentPlayerIndex =
//   //         playerIds.indexWhere((element) => element == currentPlayerId);
//   //     currentPlayer = currentPlayerIndex;
//   //   } else {
//   //     currentPlayer = playersSize - 1;
//   //   }
//   // }

//   void updateMyAction(String action) {
//     final index = players.indexWhere((element) => element.id == myId);
//     if (index == -1) return;
//     players[index] = players[index].copyWith(action: action);
//     showToast("You $action${action.endsWith("e") ? "d" : "ed"}");

//     final outputAction = executeGameAction();
//     if (((maxGameTime != null && gameTime == maxGameTime) ||
//             (maxGameTime == null && gameTime == 0) ||
//             finishedRound) &&
//         (outputAction == "start" || outputAction == "restart")) {
//       getCurrentPlayer();
//       onInit();
//     }
//     if (!mounted) return;
//     setState(() {});
//   }

//   void updateMyChangedGame(String game) {
//     final index = players.indexWhere((element) => element.id == myId);
//     if (index == -1) return;
//     players[index] = players[index].copyWith(game: game, action: "pause");
//     showToast("You changed game to $game");
//     executeGameChange();
//     setState(() {});
//   }

//   void updateMyCallMode({String? callMode}) async {
//     final index = players.indexWhere((element) => element.id == myId);
//     if (index == -1) return;
//     final player = players[index];
//     player.callMode = callMode;
//     await executeCallAction(players[index]);
//     setState(() {});
//   }

//   void executeGameChange() {
//     String newgame = getChangedGame(getAvailablePlayers());
//     if (newgame.isEmpty || gameName == newgame) return;
//     recordId++;

//     change(newgame, true);
//   }

//   String executeGameAction() {
//     String action = getAction(getAvailablePlayers());
//     if (action == "pause") {
//       if (!paused) {
//         pause(true);
//       }
//     } else if (action == "start") {
//       if (paused) {
//         start(true);
//       }
//     } else if (action == "restart") {
//       recordId++;
//       restart(true);
//     }
//     //  else if (action == "concede") {
//     //   concede(true);
//     // }
//     return action;
//   }

//   Future executeCallAction(Player player, [bool isRemoved = false]) async {
//     final myCallMode = getMyCallMode(players);

//     if (isRemoved && callMode != null) {
//       if (player.id == myId) {
//         await _leaveCall();
//         callMode = null;
//         calling = false;
//       } else {
//         _disposeForUser(player.id);
//         if (players
//             .where((element) =>
//                 element.id != myId && element.callMode == myCallMode)
//             .isEmpty) {
//           calling = false;
//         }
//       }
//       return;
//     }
//     if (myCallMode == null) {
//       if (callMode != null) {
//         await _leaveCall();
//         callMode = null;
//         calling = false;
//       }
//     } else {
//       if (player.id == myId && player.callMode != null) {
//         if (callMode != null && callMode != player.callMode) {
//           callMode = player.callMode;
//           await updateCallMode(gameId, matchId, callMode);
//         } else {
//           if (callMode == null) {
//             callMode = player.callMode;
//             await _startCall();
//             final callers = players
//                 .where((element) =>
//                     element.id != myId && element.callMode == player.callMode)
//                 .toList();

//             calling = callers.isNotEmpty;
//           }
//           //  else {
//           //   _toggleCallMode();
//           // }
//         }
//       } else {
//         if (player.callMode == myCallMode) {
//           //_disposeForUser(player.id);
//           sendOffer(player.id);
//           calling = true;
//         } else {
//           if (callMode != null) {
//             if (player.callMode == null) {
//               _disposeForUser(player.id);
//               if (players
//                   .where((element) =>
//                       element.id != myId && element.callMode == myCallMode)
//                   .isEmpty) {
//                 calling = false;
//               }
//             }
//             // else {
//             //   callMode = player.callMode;
//             // }
//           }
//         }
//       }
//     }
//   }

//   void checkFirstime() async {
//     final name = allQuizGames.contains(gameName) ? "Quiz" : gameName;
//     int playTimes = sharedPref.getInt(name) ?? 0;
//     if (playTimes < maxHintTime) {
//       readAboutGame = playTimes == 0;
//       playTimes++;
//       sharedPref.setInt(name, playTimes);
//       firstTime = true;
//     } else {
//       firstTime = false;
//     }
//     if (!mounted) return;
//     setState(() {});
//   }

//   void init() {
//     isCard = gameName == "Whot";
//     isChessOrDraught = gameName == chessGame || gameName == draughtGame;
//     isPuzzle = allPuzzleGames.contains(gameName);
//     isQuiz = gameName.endsWith("Quiz");

//     isMyTurn = currentPlayerId == myId;

//     timerController = StreamController.broadcast();
//     if (isChessOrDraught) {
//       timerController2 = StreamController.broadcast();
//     }
//     checkFirstime();
//     checkSubscription();
//     initScores();
//     initPlayers();
//     initMessages();
//     initPlayersCounts();
//     initToasts();
//     getCurrentPlayer();
//     if (gameId.isEmpty) onInit();
//     onStart();
//     readPlayers();
//     readDetails();
//     pauseIndex = gameId.isEmpty
//         ? playersSize == 1
//             ? 0
//             : playersSize == 2
//                 ? 1
//                 : 2
//         : myPlayer;
//     if (maxGameTime != null) {
//       gameTime = maxGameTime!;
//       gameTime2 = maxGameTime!;
//     } else {
//       gameTime = 0;
//       gameTime2 = 0;
//     }
//   }

//   Future readPlayers() async {
//     if (gameId.isEmpty) return;
//     // var users = this.users;
//     // if (playersSub != null) return;
//     //getFirstPlayer();
//     bool hasEnded = false;
//     if (match != null && match!.time_end != null) {
//       if (!isWatch &&
//           match!.recordsCount != null &&
//           recordId < match!.recordsCount!) {
//         recordId = match!.recordsCount!;
//       }
//       hasEnded = true;
//       final playersIds = match!.players!;
//       players = playersIds.map((e) => Player(id: e, time: timeNow)).toList();
//     }

//     if (users == null || users!.length != players.length) {
//       users = await playersToUsers(players.map((e) => e.id).toList());
//     }

//     final index = users!
//         .indexWhere((element) => element != null && element.user_id == myId);
//     myPlayer = index;

//     setState(() {});
//     if (hasEnded) {
//       return;
//     }
//     final lastTime = players
//         .sortedList((player) => player.time_modified, false)
//         .lastOrNull
//         ?.time_modified;

//     playersSub = getPlayersChange(gameId, matchId: matchId, lastTime: lastTime)
//         .listen((playersChanges) async {
//       for (int i = 0; i < playersChanges.length; i++) {
//         final playersChange = playersChanges[i];
//         final value = playersChange.value;
//         final playerIndex =
//             players.indexWhere((element) => element.id == value.id);
//         final userIndex =
//             users!.indexWhere((element) => element?.user_id == value.id);
//         final username =
//             userIndex == -1 ? "" : users![userIndex]?.username ?? "";

//         if (playerIndex != -1) {
//           if (playersChange.removed) {
//             value.game = null;
//             value.matchId = null;
//           }
//           final actionMessage = value.game != null && value.game != gameName
//               ? "changed to ${value.game}"
//               : players[playerIndex].action != value.action &&
//                       (value.action ?? "").isNotEmpty
//                   ? value.action ?? ""
//                   : "";
//           if (actionMessage.isNotEmpty) {
//             final title =
//                 "$username ${value.game != gameName ? actionMessage : "$actionMessage${actionMessage.endsWith("e") ? "d" : "ed"}"}";
//             if (value.game != gameName
//                 ? value.game != getMyPlayer(players)?.game
//                 : value.action != "pause" &&
//                     value.action != "concede" &&
//                     value.action != "leave" &&
//                     value.action != getMyPlayer(players)?.action) {
//               final result = await context.showComfirmationDialog(
//                   title: title,
//                   message:
//                       "Do you also want to ${value.game != gameName ? "change" : value.action!} game?");
//               if (result == true) {
//                 if (value.game != gameName) {
//                   change(value.game!);
//                 } else {
//                   if (value.action == "pause") {
//                     if (!paused) {
//                       pause();
//                     }
//                   } else if (value.action == "start") {
//                     if (paused) {
//                       start();
//                     }
//                   } else if (value.action == "restart") {
//                     recordId++;
//                     restart();
//                   }
//                 }
//               }
//             } else {
//               showToast(title);
//             }
//           }
//           if (players[playerIndex].callMode != value.callMode) {
//             if (value.callMode != null) {
//               final title = "$username started ${value.callMode} call";
//               if (value.callMode != getMyPlayer(players)?.callMode) {
//                 if (!mounted) return;
//                 final result = await context.showComfirmationDialog(
//                     title: title, message: "Do you accept?");
//                 if (result == true) {
//                   await updateCallMode(gameId, matchId, callMode);
//                   updateMyCallMode(callMode: value.callMode!);
//                 }
//               } else {
//                 showToast(title);
//               }
//             } else {
//               final title = "$username ended call";
//               showToast(title);
//             }
//           }

//           players[playerIndex] = value;
//         } else {
//           showToast("$username joined");
//           players.add(value);
//         }

//         if (!mounted) return;
//         executeGameAction();
//         executeGameChange();
//         executeCallAction(value, playersChange.removed);

//         setState(() {});

//         // if (players.isEmpty ||
//         //     players.indexWhere((element) => element.id == myId) == -1) {
//         //   context.pop();
//         //   return;
//         // } else if (players.length == 1 && players.first.id == myId) {
//         //   leave();
//         //   //context.pop();
//         // }
//       }
//     });
//   }

//   Future readDetails() async {
//     //match ??= await getMatch(gameId, matchId);
//     if (gameId.isEmpty) return;
//     if (detailsSub != null) {
//       await detailsSub!.cancel();
//       detailsSub = null;
//     }
//     awaitingReadDetails = true;
//     if (recordGameDetails.containsKey(recordId)) {
//       gameDetails = recordGameDetails[recordId];
//     } else {
//       gameDetailIndex = -1;
//       //gameDetails = isWatch ? null : [];
//       gameDetails = null;
//       recordGameDetails[recordId] = gameDetails;
//     }

//     bool hasEnded = match?.time_end != null;

//     var lastTime =
//         gameDetailIndex == -1 ? null : gameDetails![gameDetailIndex]["time"];
//     if (gameDetails == null || (isWatch && !finishedWatching)) {
//       final newGameDetails = await getGameDetails(gameId, matchId, recordId,
//           time: lastTime, isWatch: isWatch, hasEnded: hasEnded);
//       //print("newGameDetails= $newGameDetails, recordId = $recordId");
//       gameDetails ??= [];

//       if (newGameDetails.isNotEmpty) {
//         gameDetails!.addAll(newGameDetails);
//         if (isWatch && !hasEnded) {
//           finishedWatching = true;
//         }
//       } else {
//         if (isWatch) {
//           finishedWatching = true;
//         }
//       }
//     }
//     //print("gameDetails = $gameDetails");

//     for (int i = gameDetailIndex + 1; i < gameDetails!.length; i++) {
//       final gameDetail = gameDetails![i];
//       updateGameDetails(gameDetail);
//       gameDetailIndex++;
//     }
//     awaitingReadDetails = false;

//     if (hasEnded ||
//         (match?.recordsCount != null && recordId < match!.recordsCount!) ||
//         (isWatch && !finishedWatching)) {
//       return;
//     }

//     lastTime =
//         gameDetailIndex == -1 ? null : gameDetails![gameDetailIndex]["time"];
//     //print("getGameDetailsChange");

//     detailsSub = getGameDetailsChange(gameId, matchId, recordId, lastTime)
//         .listen((detailsChanges) {
//       for (int i = 0; i < detailsChanges.length; i++) {
//         final detailsChange = detailsChanges[i];
//         final gameDetail = detailsChange.value;
//         updateGameDetails(gameDetail);
//       }
//     });
//   }

//   void updateGameDetails(Map<String, dynamic> gameDetail) {
//     final playerId = gameDetail["id"];
//     final duration = gameDetail["duration"] as int?;
//     final playerTime = gameDetail["playerTime"] as int?;
//     //final matchRecordId = gameDetail["recordId"];
//     // final time = gameDetail["time"];
//     final action = gameDetail["action"];

//     //&& isWatch
//     if (duration != null) {
//       if (isChessOrDraught && getPlayerIndex(playerId) == 1) {
//         if ((gameTime2 - duration).abs() > 3) {
//           gameTime2 = duration;
//         }
//       } else {
//         if ((gameTime - duration).abs() > 3) {
//           gameTime = duration;
//         }
//       }
//     }
//     if (playerTime != null) {
//       if ((this.playerTime - playerTime).abs() > 3) {
//         this.playerTime = playerTime;
//       }
//     }

//     if (action != null) {
//       if (action == "concede") {
//         concede(playerId, true);
//       } else if (action == "leave") {
//         leave(playerId, true);
//       }
//     } else {
//       onDetailsChange(gameDetail);
//     }
//     if (gameDetail["moreDetails"] != null) {
//       final moreDetails = gameDetail["moreDetails"] as List<dynamic>;
//       for (int i = 0; i < moreDetails.length; i++) {
//         final detail = moreDetails[i];
//         detail["id"] = playerId;
//         updateGameDetails(detail);
//       }
//     }
//   }

//   Future setActionDetails(String gameId, String matchId, String action) async {
//     if (isPuzzle && gatheredGameDetails != null) {
//       await setDetail(gatheredGameDetails!);
//       gatheredGameDetails = null;
//     }
//     return setDetail({"action": action});
//   }

//   Future<Map<String, dynamic>> setDetail(
//       String gameId, String matchId, Map<String, dynamic> map) async {
//     if (map.isEmpty) return {};

//     map["time"] = timeNow;
//     map["duration"] =
//         currentPlayer == 1 && isChessOrDraught ? gameTime2 : gameTime;
//     if (!isChessOrDraught) {
//       map["playerTime"] = playerTime;
//     }

//     if (isPuzzle && playerTime < maxPlayerTime!) {
//       if (gatheredGameDetails == null) {
//         gatheredGameDetails = map;
//       } else {
//         if (gatheredGameDetails!["moreDetails"] == null) {
//           gatheredGameDetails!["moreDetails"] = [map];
//         } else {
//           gatheredGameDetails!["moreDetails"].add(map);
//         }
//       }
//       return {};
//     }
//     if (awaiting || gameId.isEmpty || !mounted) return {};
//     map["id"] = myId;
//     map["game"] = gameName;
//     map["recordId"] = recordId;

//     awaiting = true;
//     await setGameDetails(gameId, matchId, map);
//     gameDetails!.add(map);
//     awaiting = false;
//     return map;
//   }

//   bool itsMyTurnToPlay(bool isClick, [int? player]) {
//     if (isCheckoutMode) {
//       setState(() {
//         isCheckoutMode = false;
//       });
//     }

//     if (awaiting || !mounted || finishedRound) return false;
//     if (isClick && gameId.isNotEmpty && currentPlayerId != myId) {
//       showPlayerToast(myPlayer, "Its ${getUsername(currentPlayerId)}'s turn");
//       return false;
//     }
//     if (player != null && currentPlayer != player) {
//       showPlayerToast(player,
//           "Its ${getPlayerUsername(playerId: currentPlayerId, playerIndex: currentPlayer)}'s turn");
//       return false;
//     }
//     return true;
//   }

//   void loadAd() async {
//     await _interstitialAd?.dispose();
//     _interstitialAd = null;
//     if (kIsWeb || !isAndroidAndIos || privateKey == null) {
//       return;
//     }

//     final mobileAdUnit = privateKey!.mobileAdUnit;
//     InterstitialAd.load(
//         adUnitId: mobileAdUnit,
//         request: const AdRequest(),
//         adLoadCallback: InterstitialAdLoadCallback(
//           // Called when an ad is successfully received.
//           onAdLoaded: (ad) {
//             ad.fullScreenContentCallback = FullScreenContentCallback(
//                 // Called when the ad showed the full screen content.
//                 onAdShowedFullScreenContent: (ad) {
//                   adsCount++;
//                   if (adsCount % 3 == 0 && isSubscribed == false) {
//                     gotoSubscription();
//                   }
//                   stopTimer();
//                 },
//                 // Called when an impression occurs on the ad.
//                 onAdImpression: (ad) {},
//                 // Called when the ad failed to show full screen content.
//                 onAdFailedToShowFullScreenContent: (ad, err) {
//                   // Dispose the ad here to free resources.
//                   ad.dispose();
//                   // startTimer();
//                 },
//                 // Called when the ad dismissed full screen content.
//                 onAdDismissedFullScreenContent: (ad) {
//                   // Dispose the ad here to free resources.
//                   ad.dispose();
//                   // startTimer();
//                 },
//                 // Called when a click is recorded for an ad.
//                 onAdClicked: (ad) {});

//             // Keep a reference to the ad so you can show it later.
//             _interstitialAd = ad;
//             _interstitialAd!.show();
//           },
//           // Called when an ad request failed.
//           onAdFailedToLoad: (LoadAdError error) {
//             // startTimer();
//           },
//         ));
//   }

//   void incrementCount(int player, [int count = 1]) {
//     playersCounts[player] += count;
//     setState(() {});
//   }

//   void decrementCount(int player, [int count = 1]) {
//     playersCounts[player] -= count;
//     setState(() {});
//   }

//   void updateCount(int player, int count) {
//     playersCounts[player] = count;
//     setState(() {});
//   }

//   void setInitialCount(int count) {
//     playersCounts = List.generate(playersSize, (index) => count);
//   }

//   List<int> getLowestCountPlayer() {
//     Map<int, List<int>> map = {};
//     int lowestCount = playersCounts[0];
//     map[lowestCount] = [0];
//     for (var i = 1; i < playersCounts.length; i++) {
//       final count = playersCounts[i];
//       if (count < lowestCount) {
//         lowestCount = count;
//       }
//       if (map[count] != null) {
//         map[count]!.add(i);
//       } else {
//         map[count] = [i];
//       }
//     }
//     return map[lowestCount]!;
//   }

//   List<int> getHighestCountPlayer() {
//     Map<int, List<int>> map = {};
//     int highestCount = playersCounts[0];
//     map[highestCount] = [0];
//     for (var i = 1; i < playersCounts.length; i++) {
//       final count = playersCounts[i];
//       if (count > highestCount) {
//         highestCount = count;
//       }
//       if (map[count] != null) {
//         map[count]!.add(i);
//       } else {
//         map[count] = [i];
//       }
//     }
//     return map[highestCount]!;
//   }

//   void initPlayersCounts() {
//     playersCounts = List.generate(playersSize, (index) => -1);
//   }

//   void initPlayers() {
//     //players = List.generate(playersSize, (index) => index);
//   }

//   void initScores() {
//     playersScores = List.generate(playersSize, (index) => 0);
//   }

//   void initToasts() {
//     playersToasts = List.generate(playersSize, (index) => "");
//   }

//   void initMessages() {
//     playersMessages = List.generate(playersSize, (index) => "");
//   }

//   void showPlayerToast(int playerIndex, String message) {
//     if (!isPlayerActive(playerIndex)) return;
//     playersToasts[playerIndex] = message;

//     setState(() {});
//   }

//   void showPlayersToast(List<int> indices, String message) {
//     for (int i = 0; i < indices.length; i++) {
//       final index = indices[i];
//       if (!isPlayerActive(index)) continue;
//       playersToasts[index] = message;
//     }
//     setState(() {});
//   }

//   void showAllPlayersToast(String message) {
//     for (int i = 0; i < playersSize; i++) {
//       if (!isPlayerActive(i)) continue;
//       playersToasts[i] = message;
//     }
//     setState(() {});
//   }

//   String getExemptPlayerMessage(ExemptPlayer exemptPlayer) {
//     return exemptPlayer.action == "concede" ? "Conceded" : "Left";
//   }

//   String getMessage(int index) {
//     String message = playersMessages[index];
//     String fullMessage = "";

//     fullMessage = message.isNotEmpty
//         ? message
//         : currentPlayer == index
//             ? "Play"
//             : "";
//     if (currentPlayer == index) {
//       return "$fullMessage - ${playerTime.toDurationString(false)}";
//     } else {
//       return fullMessage;
//     }
//   }

//   String getPlayerName(int player) {
//     return users == null || users!.isEmpty || player >= users!.length
//         ? "Player $player"
//         : users![player]?.username ?? "";
//   }

//   void updateWinForPlayerWithHighestCount() {
//     final players = getHighestCountPlayer();
//     if (players.length == 1) {
//       updateWin(players.first,
//           reason:
//               "${getPlayerName(players.first)} won with ${playersCounts[players.first]} points");
//     } else {
//       if (players.isEmpty) return;
//       if (players.length == playersSize) {
//         updateDraw(
//             reason: "It's a draw with ${playersCounts[players.first]} points");
//       } else {
//         updateTie(players,
//             reason:
//                 "${players.map((player) => getPlayerName(player)).join(" and ")} tied with ${playersCounts[players.first]} points");
//       }
//     }
//   }

//   void updateTie(List<int> players, {String? reason}) {
//     if (players.length == 1) {
//       return updateWin(players.first, reason: reason);
//     }
//     if (players.length == playersSize) {
//       return updateDraw(reason: reason);
//     }
//     reason ??= this.reason;
//     finishedRound = true;
//     updateRecord(players);
//     toastWinners(players, reason: reason);
//     pause();
//   }

//   void updateWin(int player, {String? reason}) {
//     reason ??= this.reason;

//     finishedRound = true;
//     playersScores[player]++;
//     updateRecord([player]);
//     toastWinner(player, reason: reason);
//     pause();
//   }

//   void updateDraw({String? reason}) {
//     reason ??= this.reason;
//     finishedRound = true;
//     //updateRecord();
//     toastDraw(reason: reason);
//     pause();
//   }

//   void toastDraw({String? reason}) {
//     String message = "It's a draw";
//     if (reason != null) {
//       message += " with $reason";
//     }
//     for (int i = 0; i < playersSize; i++) {
//       showPlayerToast(i, message);
//     }
//     // if (isCard) {

//     // } else {
//     //   showPlayerToast(0, message);
//     //   showPlayerToast(1, message);
//     // }
//   }

//   void toastWinner(int player, {String? reason}) {
//     String message =
//         "${users != null ? users![player]?.username ?? "" : "Player $player"} won";
//     if (reason != null) {
//       message += " with $reason";
//     }
//     for (int i = 0; i < playersSize; i++) {
//       showPlayerToast(i, message);
//     }
//     // if (isCard) {

//     // } else {
//     //   showPlayerToast(0, message);
//     //   showPlayerToast(1, message);
//     // }
//   }

//   void toastWinners(List<int> players, {String? reason}) {
//     String message = "";
//     String name = "";
//     if (users != null) {
//       final usernames = players.map((e) => users![e]!.username).toList();
//       name = usernames.toStringWithCommaandAnd((username) => username);
//     } else {
//       name = players.toStringWithCommaandAnd(
//           (players) => "${players + 1}", "Player ");
//     }
//     if (players.length == 1) {
//       playersScores[players.first]++;
//       message = "$name won";
//     } else {
//       message = "It's a tie between $name";
//     }
//     if (reason != null) {
//       message += " with $reason";
//     }

//     for (int i = 0; i < playersSize; i++) {
//       showPlayerToast(i, message);
//     }
//   }

//   List<int> convertToGrid(int pos, int gridSize) {
//     return [pos % gridSize, pos ~/ gridSize];
//   }

//   int convertToPosition(List<int> grids, int gridSize) {
//     return grids[0] + (grids[1] * gridSize);
//   }

//   String getUsername(String userId) => users == null || users!.isEmpty
//       ? ""
//       : users
//               ?.firstWhere(
//                   (element) => element != null && element.user_id == userId)
//               ?.username ??
//           "";

//   Future startOrRestart(bool start) async {
//     if (gameId != "" && matchId != "") {
//       await updateAction(
//           context,
//           players,
//           users!,
//           gameId,
//           matchId,
//           myId,
//           start ? "start" : "restart",
//           gameName,
//           maxGameTime != null ? gameTime < maxGameTime! : gameTime > 0,
//           recordId,
//           gameTime);
//       // if (!start) {
//       //   setActionGameDetails(
//       //       gameId, matchId, "restart", gameName, duration, recordId);
//       // }
//     }
//   }

//   void rewind() {
//     if (gameDetailIndex <= 0) {
//       return;
//     }
//     gameDetailIndex--;
//     readDetails();
//   }

//   void forward() {
//     if (gameDetails != null && gameDetailIndex >= gameDetails!.length - 1) {
//       return;
//     }
//     gameDetailIndex++;
//     readDetails();
//   }

//   void executeWatchAction() {
//     gameDetailIndex = -1;
//     watchInterval = 0;
//     final value = match!.records![recordId.toString()];
//     if (value != null) {
//       final record = MatchRecord.fromMap(value);
//       if (record.game != gameName) {
//         change(record.game, true);
//       } else {
//         restart(true);
//       }
//     }
//   }

//   void previous() {
//     if (recordId < 2) {
//       return;
//     }

//     recordId--;
//     executeWatchAction();
//   }

//   void next() {
//     if (match?.recordsCount != null && recordId > match!.recordsCount!) {
//       return;
//     }
//     recordId++;
//     executeWatchAction();
//   }

//   void pause([bool act = false]) async {
//     if (act || gameId == "" || isWatch) {
//       stopTimer();
//       onPause();
//       setState(() {});
//     } else {
//       if (gameId != "" && matchId != "") {
//         await pauseGame(gameId, matchId, players, recordId, duration);
//         updateMyAction("pause");
//       }
//     }
//   }

//   void start([bool act = false]) async {
//     if (act || gameId == "" || isWatch) {
//       if (finishedRound || gameTime == 0) {
//         reason = "";
//         message = "Play";
//         gameTime = maxGameTime ?? 0;
//         playerTime = maxPlayerTime!;
//         gatheredGameDetails = null;
//         isCheckoutMode = false;
//         timerController.sink.add(gameTime);
//         if (isChessOrDraught) {
//           gameTime2 = maxGameTime ?? 0;
//           timerController2!.sink.add(gameTime);
//         }

//         checkFirstime();
//         getCurrentPlayer();
//         resetExemptPlayer();
//         //if (gameId.isEmpty) onInit();
//         onStart();
//         finishedRound = false;
//       } else {
//         onResume();
//       }

//       startTimer();
//       if (!mounted) return;

//       setState(() {});
//     } else {
//       if (gameId != "" && matchId != "") {
//         if (paused && getMyPlayer(players)?.action != "pause") {
//           pause();
//         } else {
//           await startOrRestart(true);
//           updateMyAction("start");
//         }
//       }
//     }
//   }

//   void restart([bool act = false]) async {
//     if (act || gameId == "" || isWatch) {
//       if (isWatch) {
//         watchInterval = 0;
//         gameDetailIndex = -1;
//         finishedRound = true;
//         // initScores();
//         // start(act);
//       } else {
//         finishedRound = true;
//         if (match != null) {
//           updateMatchRecord(
//               match!, recordId, gameName, players, isWatch, currentPlayerId);
//         }

//         //change(gameName, true);
//       }
//       recordId++;
//       gameDetailIndex = -1;

//       initScores();
//       start(act);
//     } else {
//       if (gameId != "" && matchId != "") {
//         startOrRestart(false);
//         updateMyAction("restart");
//       }
//     }
//   }

//   void change(String game, [bool act = false]) async {
//     if (act || gameId == "" || isWatch) {
//       resetExemptPlayer();
//       if (gameId == "") {
//         recordId++;
//       }

//       gotoGamePage(context, game, gameId, matchId,
//           match: match,
//           users: users,
//           players: players,
//           playersSize: users?.length ?? playersSize,
//           recordGameDetails: recordGameDetails,
//           // gameDetailIndex: gameDetailIndex,
//           recordId: recordId,
//           currentPlayerId: currentPlayerId);
//     } else {
//       await changeGame(game, gameId, matchId, players, recordId,
//           maxGameTime != null ? maxGameTime! - gameTime : gameTime);
//       updateMyChangedGame(game);
//     }
//   }

//   void concede([String? playerId, bool act = false]) async {
//     final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
//     onConcede(index);

//     if (act || gameId == "" || isWatch) {
//       exemptPlayers.add(ExemptPlayer(
//           index: index, playerId: playerId, action: "concede", time: gameTime));
//       if (index == currentPlayer) {
//         changePlayer();
//       }
//       pauseIndex = currentPlayer;
//       final activePlayersCount = getActivePlayersIndices().length;

//       // if (activePlayersCount < 2) {
//       //   updateWin(getNextPlayerIndex(index));
//       // }
//       if (activePlayersCount <= 1) {
//         context.pop();
//         return;
//       } else if (activePlayersCount == 2) {
//         updateWin(getNextPlayerIndex(index));
//       }
//       if (gameId.isEmpty) {
//         showAllPlayersToast(
//             "${getPlayerUsername(playerIndex: index)} conceded");
//       } else {
//         showToast("${getPlayerUsername(playerId: playerId)} conceded");
//       }
//       setState(() {});
//     } else {
//       if (gameId != "" && matchId != "") {
//         //await concedeGame(gameId, matchId, players, recordId, duration);

//         await setActionDetails(gameId, matchId, "concede");

//         updateMyAction("concede");
//       }
//     }
//   }

//   void leave([String? playerId, bool endGame = false, bool act = false]) async {
//     if (endGame) {
//       context.pop();
//       return;
//     }
//     final index = playerId != null ? getPlayerIndex(playerId) : pauseIndex;
//     onLeave(index);
//     if (act || gameId == "" || isWatch) {
//       exemptPlayers.add(ExemptPlayer(
//           index: index, playerId: playerId, action: "leave", time: gameTime));
//       if (index == currentPlayer) {
//         changePlayer();
//       }

//       pauseIndex = currentPlayer;
//       final activePlayersCount = getActivePlayersIndices().length;

//       if (activePlayersCount <= 1) {
//         context.pop();
//         return;
//       } else if (activePlayersCount == 2) {
//         updateWin(getNextPlayerIndex(index));
//       }

//       if (gameId.isEmpty) {
//         showAllPlayersToast("${getPlayerUsername(playerIndex: index)} left");
//       } else {
//         showToast("${getPlayerUsername(playerId: playerId)} left");
//       }
//       setState(() {});

//       final availablePlayersCount = getAvailablePlayersIndices().length;
//       if (availablePlayersCount <= 1) {
//         if (!mounted) return;
//         context.pop();
//       }
//     } else {
//       if (gameId != "" && matchId != "") {
//         leaveMatch(
//             gameId,
//             matchId,
//             match,
//             players,
//             maxGameTime != null ? gameTime < maxGameTime! : gameTime > 0,
//             recordId,
//             maxGameTime != null ? maxGameTime! - gameTime : gameTime);

//         setActionDetails(gameId, matchId, "leave");

//         if (!mounted) return;
//         context.pop();
//       }
//     }
//   }

//   void toggleCall(String? callMode, [bool act = false]) async {
//     // if (act || gameId == "") {
//     // } else {}

//     updateMyCallMode(callMode: callMode);
//   }

//   void toggleCamera() async {
//     _switchCamera();
//   }

//   void toggleMute() async {
//     _toggleMic();
//   }

//   // Future<void> selectAudioOutput(String deviceId) async {
//   //   await navigator.mediaDevices
//   //       .selectAudioOutput(AudioOutputOptions(deviceId: deviceId));
//   // }

//   // Future<void> selectAudioInput(String deviceId) =>
//   //     NativeAudioManagement.selectAudioInput(deviceId);

//   // Future<void> setSpeakerphoneOn(bool enable) =>
//   //     NativeAudioManagement.setSpeakerphoneOn(enable);

//   void resetUsers() {
//     if (gameId != "" && users != null) {
//       List<User?> users = this.users!.sortWithStringList(
//           players.map((e) => e.id).toList(), (user) => user?.user_id ?? "");
//       this.users = users;
//     }
//   }

//   void updateRecord(List<int> players) {
//     if (gameId.isNotEmpty) {
//       if (isPuzzle && gatheredGameDetails != null) {
//         setDetail(gatheredGameDetails!);
//         gatheredGameDetails = null;
//       }
//       for (int i = 0; i < players.length; i++) {
//         final player = players[i];
//         int score = playersScores[player];
//         if (match != null && match!.records?["$recordId"] != null && !isWatch) {
//           final record = MatchRecord.fromMap(match!.records!["$recordId"]!);
//           record.scores["$player"] = score;
//           //newMap["player${player + 1}Score"] = score;

//           final matchOutcome =
//               getMatchOutcome(getMatchOverallScores(match!), match!.players!);

//           match!.outcome = matchOutcome.outcome;
//           match!.winners = matchOutcome.winners;
//           match!.others = matchOutcome.others;

//           if (i == 0 && player == myPlayer) {
//             updateScore(gameId, matchId, match!, recordId, player, score);
//           }
//         }
//       }

//       //updateMatchRecord(gameId, matchId, myPlayer, recordId, score);
//     }
//   }

//   void _listenForSignalingMessages() async {
//     if (signalSub != null) return;
//     //await signalSub?.cancel();
//     signalSub = streamChangeSignals(gameId, matchId).listen((signalsChanges) {
//       for (int i = 0; i < signalsChanges.length; i++) {
//         final signalChange = signalsChanges[i];
//         final data = signalChange.value;
//         final type = data["type"];
//         final id = data["id"];
//         //print("signalChange = $signalChange");

//         if (signalChange.added || signalChange.modified) {
//           switch (type) {
//             case 'offer':
//               _handleOffer(id, data['sdp']);
//               break;
//             case 'answer':
//               _handleAnswer(id, data['sdp']);
//               break;
//             case 'candidate':
//               _handleCandidate(id, data['candidate']);
//               break;
//           }
//         } else if (signalChange.removed) {
//           _disposeForUser(id);
//         }
//       }
//     });
//   }

//   void disposeForCall([bool disposeWithSignal = true]) async {
//     if (disposeWithSignal) {
//       signalSub?.cancel();
//     }

//     _localRenderer?.dispose();
//     videoOverlayVisibility.remove(myId);
//     for (var renderer in _remoteRenderers.values) {
//       renderer.dispose();
//     }
//     for (var pc in _peerConnections.values) {
//       pc.dispose();
//     }
//     _localStream?.dispose();

//     _remoteRenderers.clear();
//     _peerConnections.clear();
//     videoOverlayVisibility.clear();
//     signalSub = null;
//     _localStream = null;
//     _localRenderer = null;
//   }

//   void _disposeForUser(String peerId) async {
//     _remoteRenderers[peerId]?.dispose();
//     _peerConnections[peerId]?.dispose();
//     _remoteRenderers.remove(peerId);
//     _peerConnections.remove(peerId);
//     videoOverlayVisibility.remove(peerId);

//     if (_peerConnections.isEmpty) {
//       signalSub?.cancel();
//       _localRenderer?.dispose();
//       videoOverlayVisibility.remove(myId);
//       _localStream?.dispose();
//       signalSub = null;
//       _localStream = null;
//       _localRenderer = null;
//     }
//   }

//   Future initForCall() async {
//     await _initializeLocalStream();
//   }

//   Future<void> _initializeLocalRenderer() async {
//     if (_localRenderer != null) return;
//     _localRenderer = RTCVideoRenderer();
//     videoOverlayVisibility[myId] = "show";
//     await _localRenderer?.initialize();
//   }

//   Future<void> _initializeLocalStream() async {
//     isVideoOn = callMode == "video";

//     if (_localStream != null &&
//         ((_localRenderer != null && isVideoOn) ||
//             (_localRenderer == null && !isVideoOn))) {
//       return;
//     }
//     await _localStream?.dispose();
//     //print("newisAudioOn = $isAudioOn");
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       'audio': isAudioOn,
//       'video': isVideoOn
//           ? {
//               'mandatory': {
//                 'minWidth': '640', // Adjust as needed
//                 'minHeight': '480', // Adjust as needed
//                 'minFrameRate': '15',
//                 'maxFrameRate': '30',
//               },
//               'facingMode': isFrontCameraSelected ? 'user' : 'environment',
//               'optional': [],
//             }
//           //? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
//           : false,
//     });
//     if (isVideoOn) {
//       await _initializeLocalRenderer();
//     } else {
//       if (_localRenderer != null) {
//         _localRenderer!.dispose();
//         _localRenderer = null;
//         videoOverlayVisibility.remove(myId);
//       }
//     }
//     _localRenderer?.srcObject = _localStream;
//     setState(() {});
//   }

//   Future<void> _createPeerConnection(String peerId) async {
//     await initForCall();
//     if (_peerConnections[peerId] != null &&
//         ((_remoteRenderers[peerId] != null && isVideoOn) ||
//             (_remoteRenderers[peerId] == null && !isVideoOn))) return;

//     await _peerConnections[peerId]?.dispose();

//     var pc = await createPeerConnection({
//       'iceServers': [
//         {
//           'urls': [
//             'stun:stun1.l.google.com:19302',
//             'stun:stun2.l.google.com:19302'
//           ]
//         }
//       ]
//     });
//     _peerConnections[peerId] = pc;

//     pc.onTrack = (event) async {
//       if (event.track.kind == 'video') {
//         if (!_remoteRenderers.containsKey(peerId)) {
//           var renderer = RTCVideoRenderer();
//           _remoteRenderers[peerId] = renderer;
//           videoOverlayVisibility[peerId] = "faint";
//           await _remoteRenderers[peerId]?.initialize();
//         }
//         _remoteRenderers[peerId]?.srcObject = event.streams[0];
//         setState(() {});
//       } else {
//         if (_remoteRenderers.containsKey(peerId)) {
//           _remoteRenderers[peerId]?.dispose();
//           _remoteRenderers.remove(peerId);
//           videoOverlayVisibility.remove(peerId);
//           setState(() {});
//         }
//       }
//     };

//     _localStream?.getTracks().forEach((track) {
//       pc.addTrack(track, _localStream!);
//     });
//     setState(() {});
//   }

//   String _setMediaBitrate(String sdp, {int? audioBitrate, int? videoBitrate}) {
//     var lines = sdp.split('\n');
//     var newSdp = <String>[];

//     bool videoBitrateSet = false;
//     bool audioBitrateSet = false;

//     for (var i = 0; i < lines.length; i++) {
//       if (lines[i].startsWith('m=video')) {
//         newSdp.add(lines[i]);
//         videoBitrateSet = true;
//       } else if (lines[i].startsWith('m=audio')) {
//         newSdp.add(lines[i]);
//         audioBitrateSet = true;
//       } else if (lines[i].startsWith('b=AS:') && lines[i].contains('video')) {
//         // Skip existing video bitrate line to avoid duplication
//         videoBitrateSet = false;
//       } else if (lines[i].startsWith('b=AS:') && lines[i].contains('audio')) {
//         // Skip existing audio bitrate line to avoid duplication
//         audioBitrateSet = false;
//       } else {
//         newSdp.add(lines[i]);
//       }
//     }

//     // Add or update bitrate lines
//     if (videoBitrateSet) {
//       newSdp.add('b=AS:${videoBitrate ?? 1000}'); // Add video bitrate line
//     }
//     if (audioBitrateSet) {
//       newSdp.add('b=AS:${audioBitrate ?? 64}'); // Add audio bitrate line
//     }

//     return newSdp.join('\n');
//   }

//   Future _startCall() async {
//     if (gameId == "") return;
//     await startCall(gameId, callMode!);
//     _listenForSignalingMessages();
//   }

//   _leaveCall() async {
//     await endCall(gameId);
//     await removeSignal(gameId, matchId, myId);
//     disposeForCall();
//     //context.pop();
//   }

//   _toggleMic() async {
//     isAudioOn = !isAudioOn;

//     _localStream?.getAudioTracks().forEach((track) {
//       track.enabled = isAudioOn;
//     });
//     setState(() {});
//     updateCallAudio(gameId, matchId, isAudioOn);
//   }

//   // _toggleCallMode() {
//   //   isVideoOn = !isVideoOn;
//   //   _localStream?.getVideoTracks().forEach((track) {
//   //     track.enabled = isVideoOn;
//   //   });
//   //   setState(() {});
//   // }

//   _switchCamera() {
//     isFrontCameraSelected = !isFrontCameraSelected;
//     _localStream?.getVideoTracks().forEach((track) {
//       // // ignore: deprecated_member_use
//       // track.switchCamera();
//       Helper.switchCamera(track);
//     });
//     setState(() {});
//     updateCallCamera(gameId, matchId, isFrontCameraSelected);
//   }

//   toggleSpeaker() async {
//     isOnSpeaker = !isOnSpeaker;
//     await Helper.setSpeakerphoneOn(isOnSpeaker);
//     setState(() {});
//   }

//   toggleVideoOverlayVisibility(String? userId) {
//     if (userId == null) return;
//     final visibility = videoOverlayVisibility[userId];
//     switch (visibility) {
//       case "show":
//         videoOverlayVisibility[userId] = "faint";
//         break;
//       case "faint":
//         videoOverlayVisibility[userId] = "hide";
//         break;
//       case "hide":
//         videoOverlayVisibility[userId] = "show";
//         break;
//     }
//     setState(() {});
//   }

//   double getOverlayOpacity(int index) {
//     final exemptPlayer = getExemptPlayer(index);
//     double opacity = exemptPlayer != null ? 0.3 : 1;

//     final userId = getPlayerId(index);
//     if (userId == null) return opacity;

//     final visibility = videoOverlayVisibility[userId];
//     switch (visibility) {
//       case "show":
//         return opacity;
//       case "faint":
//         return exemptPlayer != null ? 0.3 : 0.5;
//       case "hide":
//         return 0;
//     }
//     return opacity;
//   }

//   Future sendIceCandidates(String peerId) async {
//     await _createPeerConnection(peerId);
//     final pc = _peerConnections[peerId]!;
//     pc.onIceCandidate = (candidate) {
//       addSignal(gameId, matchId, peerId,
//           {'type': 'candidate', 'candidate': candidate.toMap()});
//     };
//   }

//   Future sendOffer(String peerId) async {
//     //_listenForSignalingMessages();
//     bool justCreating = _peerConnections[peerId] == null;

//     await _createPeerConnection(peerId);
//     final pc = _peerConnections[peerId]!;

//     var offer = await pc.createOffer();
//     //RTCSessionDescription offer = await pc.createOffer();
//     //offer.sdp = _setMediaBitrate(offer.sdp!, videoBitrate: 500); // 500 kbps

//     await pc.setLocalDescription(offer);
//     await addSignal(
//         gameId, matchId, peerId, {'type': 'offer', 'sdp': offer.sdp});
//     if (justCreating) {
//       sendIceCandidates(peerId);
//     }
//   }

//   Future sendAnswer(String peerId, String sdp) async {
//     //_listenForSignalingMessages();
//     bool justCreating = _peerConnections[peerId] == null;

//     await _createPeerConnection(peerId);

//     final pc = _peerConnections[peerId]!;

//     await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

//     var answer = await pc.createAnswer();
//     //RTCSessionDescription answer = await pc.createAnswer();
//     //answer.sdp = _setMediaBitrate(answer.sdp!, videoBitrate: 500); // 500 kbps
//     await pc.setLocalDescription(answer);

//     await addSignal(
//         gameId, matchId, peerId, {'type': 'answer', 'sdp': answer.sdp});

//     if (justCreating) {
//       sendIceCandidates(peerId);

//       await sendOffer(peerId);
//     }
//   }

//   Future<void> _handleOffer(String peerId, String sdp) async {
//     await sendAnswer(peerId, sdp);
//   }

//   Future<void> _handleAnswer(String peerId, String sdp) async {
//     await _createPeerConnection(peerId);
//     final pc = _peerConnections[peerId]!;
//     await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
//   }

//   Future<void> _handleCandidate(
//       String peerId, Map<String, dynamic> candidate) async {
//     await _createPeerConnection(peerId);
//     final pc = _peerConnections[peerId]!;
//     var rtcCandidate = RTCIceCandidate(candidate['candidate'],
//         candidate['sdpMid'], candidate['sdpMLineIndex']);
//     await pc.addCandidate(rtcCandidate);
//   }

//   Widget getPlayerBottomWidget(int index) {
//     final exemptPlayer = getExemptPlayer(index);
//     final user = users != null && index < users!.length ? users![index] : null;
//     final profilePhoto = user?.profile_photo;
//     return IgnorePointer(
//       ignoring: exemptPlayer != null &&
//           exemptPlayer.action == "leave" &&
//           !finishedRound,
//       child: RotatedBox(
//         quarterTurns: getStraightTurn(index),
//         child: GestureDetector(
//           onTap: () {
//             if (finishedRound) {
//               changePlayer(player: index);
//             }
//           },
//           child: Row(
//             //mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const SizedBox(
//                 width: 20,
//               ),
//               Expanded(
//                 child: Row(
//                   // mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 10,
//                       backgroundImage: profilePhoto != null
//                           ? CachedNetworkImageProvider(profilePhoto)
//                           : null,
//                       backgroundColor: lightestWhite,
//                       child: profilePhoto != null
//                           ? null
//                           : Text(
//                               user?.username.firstChar ?? "P",
//                               style: const TextStyle(
//                                   fontSize: 10, color: Colors.blue),
//                             ),
//                     ),
//                     const SizedBox(width: 4),
//                     Flexible(
//                       child: Text(
//                         user?.username ?? "Player ${index + 1}",
//                         style: TextStyle(
//                             fontSize: 14,
//                             color: currentPlayer == index ? Colors.blue : tint),
//                         textAlign: TextAlign.center,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     if (playersCounts.isNotEmpty &&
//                         index < playersCounts.length &&
//                         playersCounts[index] != -1)
//                       CountWidget(count: playersCounts[index])
//                   ],
//                 ),
//               ),
//               if (gameId.isEmpty || index == myPlayer)
//                 IconButton(
//                   style: IconButton.styleFrom(
//                     padding: const EdgeInsets.all(2),
//                   ),
//                   onPressed: () {
//                     pauseIndex = index;
//                     if (isCheckoutMode) {
//                       isCheckoutMode = false;
//                     } else if (!paused) {
//                       pause();
//                     }
//                     setState(() {});
//                   },
//                   icon: Icon(
//                     EvaIcons.menu_outline,
//                     color: tint,
//                   ),
//                 )
//               else
//                 const SizedBox(
//                   width: 20,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   int getPausedGameTurn() {
//     if (gameId != "" || playersSize == 1) return 0;

//     return isCard
//         ? pauseIndex == 0
//             ? 2
//             : pauseIndex == 1 && playersSize > 2
//                 ? 3
//                 : pauseIndex == 3
//                     ? 1
//                     : 0
//         : pauseIndex == 0 || (pauseIndex == 1 && playersSize > 2)
//             ? 2
//             : 0;
//   }

//   int getTurn(int index) {
//     int turn = 0;
//     if (index == 0) {
//       turn = 2;
//     } else if (index == 1 && playersSize > 2) {
//       turn = 3;
//     } else if (index == 3) {
//       turn = 1;
//     }
//     return turn;
//   }

//   int getLayoutTurn() {
//     if (playersSize == 1) return 2;
//     return isCard
//         ? (gameId != ""
//             ? myPlayer == 0
//                 ? 2
//                 : myPlayer == 1 && playersSize > 2
//                     ? 1
//                     : myPlayer == 3
//                         ? 3
//                         : 0
//             : 0)
//         : (gameId != "" &&
//                 (myPlayer == 0 || (myPlayer == 1 && playersSize > 2)))
//             ? 2
//             : 0;
//   }

//   int getOppositeLayoutTurn() {
//     final layoutTurn = getLayoutTurn();
//     return layoutTurn == 1
//         ? 3
//         : layoutTurn == 3
//             ? 1
//             : layoutTurn;
//   }

//   int getStraightTurn(int index) {
//     if (gameId.isEmpty || index == myPlayer) return 0;
//     if (playersSize == 2) return 2;

//     if (isCard) {
//       final partner = getCardPartnerPlayer();
//       if (index == partner) return 2;
//       return 0;
//     } else {
//       if (index == getPartnerPlayer()) return 0;
//       return 2;
//     }
//   }

//   int getVideoViewTurn(int index) {
//     if (gameId.isEmpty || index == myPlayer) return 0;
//     if (playersSize == 2) return 2;

//     if (isCard) {
//       final partner = getCardPartnerPlayer();
//       if (index == partner) return 2;
//       final prevPlayer = getPrevPlayerIndex(myPlayer);
//       return index == prevPlayer ? 1 : 3;
//     } else {
//       if (index == getPartnerPlayer()) return 0;
//       return 2;
//     }
//   }

//   String getFirstHint() {
//     String hint = "";
//     if (gameName.endsWith("Quiz")) {
//       return "Tap on any option that you think is the answer to the question\nSubmit if you are sure to be done\nSelected answer would be automatically submited on timeout";
//     }
//     switch (gameName) {
//       case chessGame:
//         hint = "Tap on any chess piece\nMake your move";
//         break;
//       case draughtGame:
//         hint = "Tap on any draught piece\nMake your move";
//         break;
//       case whotGame:
//         hint =
//             "Tap any card to open\nLong press any card to hide\nPlay a matching card";
//         // hint =
//         //     "Tap on any card you want to play or tap the general card if you don't have the matching card\nMake your move";
//         break;
//       case ludoGame:
//         hint = "Tap on roll dice button to roll dice\nPlay your dice value";
//         // hint =
//         //     "Tap on any start ludo piece and tap on the spot you want it to move to\nMake your move";
//         break;
//       case xandoGame:
//         hint =
//             "Tap on any grid to play till you have a complete 3 match pattern in any direction\nMake your move";
//         break;
//       case wordPuzzleGame:
//         hint =
//             "Tap on any start character and tap on the end character or start dragging from the start character to end char to match your word\nGet your word";
//         break;
//     }
//     return hint;
//   }

//   bool getIsPlaying(int index) {
//     return players.isNotEmpty &&
//         players.indexWhere((element) => element.id == myId) != -1;
//   }

//   String? getPlayerId(int index) {
//     return index < players.length ? players[index].id : null;
//   }

//   Player? getPlayer(int index) {
//     return index < players.length ? players[index] : null;
//   }

//   Widget? buildVideoView(int index) {
//     if (gameId.isEmpty || players.isEmpty) return null;
//     final playerId = getPlayerId(index);
//     if (playerId == null ||
//         (playerId == myId && _localRenderer == null) ||
//         (playerId != myId && _remoteRenderers[playerId] == null)) {
//       return null;
//     }
//     return RotatedBox(
//       quarterTurns: getVideoViewTurn(index),
//       child: RTCVideoView(
//         playerId == myId ? _localRenderer! : _remoteRenderers[playerId]!,
//         objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//         mirror: playerId == myId && isFrontCameraSelected,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     // print("details = ${gameDetails.lastOrNull}");
//     double padding = (context.screenHeight - context.screenWidth).abs() / 2;
//     bool landScape = context.isLandscape;
//     double minSize = context.minSize;

//     return PopScope(
//       canPop: false,
//       onPopInvoked: (pop) async {
//         if (isCheckoutMode) {
//           setState(() {
//             isCheckoutMode = false;
//           });
//         } else if (!paused) {
//           pause();
//         }
//       },
//       child: KeyboardListener(
//         focusNode: _focusNode,
//         autofocus: true,
//         onKeyEvent: _onKey,
//         child: Scaffold(
//           body: Stack(
//             alignment: Alignment.center,
//             children: [
//               RotatedBox(
//                 quarterTurns: getLayoutTurn(),
//                 child: Stack(
//                   children: [
//                     if (isCard) ...[
//                       ...List.generate(playersSize, (index) {
//                         final videoView = buildVideoView(index);
//                         final exemptPlayer = getExemptPlayer(index);
//                         return Positioned(
//                           top: index == 0 ||
//                                   ((index == 1 || index == 3) &&
//                                       playersSize > 2)
//                               ? 0
//                               : null,
//                           bottom: index != 0 ? 0 : null,
//                           left: playersSize > 2 && index == 1 ? null : 0,
//                           right: index < 3 ? 0 : null,
//                           child: RotatedBox(
//                             quarterTurns: getTurn(index),
//                             child: Opacity(
//                               opacity: getOverlayOpacity(index),
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     RotatedBox(
//                                       quarterTurns: getStraightTurn(index),
//                                       child: StreamBuilder<int>(
//                                           stream: currentPlayer == index
//                                               ? timerController.stream
//                                               : null,
//                                           builder: (context, snapshot) {
//                                             return Text(
//                                               exemptPlayer != null
//                                                   ? getExemptPlayerMessage(
//                                                       exemptPlayer)
//                                                   : getMessage(index),
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 14,
//                                                 color: darkMode
//                                                     ? Colors.white
//                                                     : Colors.black,
//                                               ),
//                                               textAlign: TextAlign.center,
//                                             );
//                                           }),
//                                     ),
//                                     GestureDetector(
//                                       behavior: HitTestBehavior.opaque,
//                                       onTap: () {
//                                         toggleVideoOverlayVisibility(
//                                             getPlayerId(index));
//                                       },
//                                       child: Stack(
//                                         alignment: Alignment.center,
//                                         children: [
//                                           if (videoView != null) videoView,
//                                           Container(
//                                             // height: cardHeight,
//                                             width: minSize,
//                                             alignment: Alignment.center,
//                                             margin: EdgeInsets.only(
//                                                 left: 24,
//                                                 right: 24,
//                                                 bottom: (landScape &&
//                                                             (index == 1 ||
//                                                                 index == 3) &&
//                                                             playersSize > 2) ||
//                                                         (!landScape &&
//                                                             (index == 0 ||
//                                                                 (index == 2 &&
//                                                                     playersSize >
//                                                                         2) ||
//                                                                 (index == 1 &&
//                                                                     playersSize ==
//                                                                         2)))
//                                                     ? 30
//                                                     : 8),
//                                             child: IgnorePointer(
//                                                 ignoring:
//                                                     exemptPlayer != null &&
//                                                         !finishedRound,
//                                                 child: buildBottomOrLeftChild(
//                                                     index)),
//                                           ),
//                                           if (exemptPlayer == null &&
//                                               index < playersToasts.length &&
//                                               playersToasts[index] != "") ...[
//                                             Align(
//                                               alignment: Alignment.bottomCenter,
//                                               child: RotatedBox(
//                                                 quarterTurns:
//                                                     getStraightTurn(index),
//                                                 child: AppToast(
//                                                   message: playersToasts[index],
//                                                   onComplete: () {
//                                                     playersToasts[index] = "";
//                                                     setState(() {});
//                                                   },
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       }),
//                       ...List.generate(playersSize, (index) {
//                         final mindex = (playersSize / 2).ceil();
//                         bool isEdgeTilt = gameId != "" &&
//                             playersSize > 2 &&
//                             (myPlayer == 1 || myPlayer == 3);
//                         final value = isEdgeTilt ? !landScape : landScape;
//                         final exemptPlayer = getExemptPlayer(index);
//                         return Positioned(
//                             top: index < mindex ? 0 : null,
//                             bottom: index >= mindex ? 0 : null,
//                             left: index == 0 || index == 3 ? 0 : null,
//                             right: index == 1 || index == 2 ? 0 : null,
//                             child: Container(
//                               width: value
//                                   ? padding
//                                   : playersSize > 2
//                                       ? minSize / 2
//                                       : minSize,
//                               height: value ? minSize / 2 : padding,
//                               alignment: value
//                                   ? index == 0
//                                       ? Alignment.topRight
//                                       : index == 1
//                                           ? playersSize > 2
//                                               ? Alignment.topLeft
//                                               : Alignment.bottomLeft
//                                           : index == 2
//                                               ? Alignment.bottomLeft
//                                               : Alignment.bottomRight
//                                   : index == 0
//                                       ? Alignment.bottomLeft
//                                       : index == 1
//                                           ? playersSize > 2
//                                               ? Alignment.bottomRight
//                                               : Alignment.topRight
//                                           : index == 2
//                                               ? Alignment.topRight
//                                               : Alignment.topLeft,
//                               child: RotatedBox(
//                                 quarterTurns: index == 0
//                                     ? 2
//                                     : index == 1 && playersSize > 2
//                                         ? 3
//                                         : index == 3
//                                             ? 1
//                                             : 0,
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(
//                                       left: 8.0, right: 8.0, bottom: 24),
//                                   child: Opacity(
//                                     opacity: getOverlayOpacity(index),
//                                     child: Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         RotatedBox(
//                                           quarterTurns: getStraightTurn(index),
//                                           child: SizedBox(
//                                             height: 70,
//                                             child: Text(
//                                               '${playersScores[index]}',
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 60,
//                                                   color: darkMode
//                                                       ? Colors.white
//                                                           .withOpacity(0.5)
//                                                       : Colors.black
//                                                           .withOpacity(0.5)),
//                                             ),
//                                           ),
//                                         ),
//                                         RotatedBox(
//                                           quarterTurns: getStraightTurn(index),
//                                           child: GameTimer(
//                                             timerStream: index == 1 &&
//                                                     isChessOrDraught &&
//                                                     timerController2 != null
//                                                 ? timerController2!.stream
//                                                 : timerController.stream,
//                                             time: exemptPlayer?.time,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ));
//                       }),
//                       ...List.generate(playersSize, (index) {
//                         return Positioned(
//                           top: index == 0 ||
//                                   (!landScape && index == 1 && playersSize > 2)
//                               ? 0
//                               : null,
//                           bottom: (index == 1 && playersSize == 2) ||
//                                   index == 2 ||
//                                   (!landScape && index == 3)
//                               ? 0
//                               : null,
//                           left: index == 3 || (landScape && index == 0)
//                               ? 0
//                               : null,
//                           right: (index == 1 && playersSize > 2) ||
//                                   (landScape &&
//                                       ((index == 1 && playersSize == 2) ||
//                                           index == 2))
//                               ? 0
//                               : null,
//                           child: RotatedBox(
//                             quarterTurns: index == 0
//                                 ? 2
//                                 : index == 1 && playersSize > 2
//                                     ? 3
//                                     : index == 3
//                                         ? 1
//                                         : 0,
//                             child: Container(
//                               width: (landScape &&
//                                           ((index == 1 && playersSize > 2) ||
//                                               index == 3)) ||
//                                       (!landScape &&
//                                           (index == 0 ||
//                                               index == 2 ||
//                                               (index == 1 && playersSize == 2)))
//                                   ? minSize
//                                   : padding,
//                               alignment: Alignment.center,
//                               child: Opacity(
//                                   opacity: getOverlayOpacity(index),
//                                   child: getPlayerBottomWidget(index)),
//                             ),
//                           ),
//                         );
//                       }),
//                     ] else ...[
//                       ...List.generate(
//                         playersSize,
//                         (index) {
//                           final mindex = (playersSize / 2).ceil();
//                           final videoView = buildVideoView(index);
//                           final exemptPlayer = getExemptPlayer(index);
//                           return Positioned(
//                               top: index < mindex ? 0 : null,
//                               bottom: index >= mindex ? 0 : null,
//                               left: index == 0 || index == 3 ? 0 : null,
//                               right: index == 1 || index == 2 ? 0 : null,
//                               child: Container(
//                                 width: landScape
//                                     ? padding
//                                     : playersSize > 2
//                                         ? minSize / 2
//                                         : minSize,
//                                 height: landScape ? minSize / 2 : padding,
//                                 alignment: Alignment.center,
//                                 padding: const EdgeInsets.all(4),
//                                 child: RotatedBox(
//                                   quarterTurns: index < mindex ? 2 : 0,
//                                   child: GestureDetector(
//                                     behavior: HitTestBehavior.opaque,
//                                     onTap: () {
//                                       toggleVideoOverlayVisibility(
//                                           getPlayerId(index));
//                                     },
//                                     child: Stack(
//                                       alignment: Alignment.center,
//                                       children: [
//                                         if (videoView != null) videoView,
//                                         Opacity(
//                                           opacity: getOverlayOpacity(index),
//                                           child: Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Column(
//                                                 mainAxisSize: MainAxisSize.min,
//                                                 children: [
//                                                   RotatedBox(
//                                                     quarterTurns:
//                                                         getStraightTurn(index),
//                                                     child: SizedBox(
//                                                       height: 70,
//                                                       child: Text(
//                                                         '${playersScores[index]}',
//                                                         style: TextStyle(
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                             fontSize: 60,
//                                                             color: lighterTint),
//                                                         textAlign:
//                                                             TextAlign.center,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   RotatedBox(
//                                                     quarterTurns:
//                                                         getStraightTurn(index),
//                                                     child: GameTimer(
//                                                       timerStream: index == 1 &&
//                                                               isChessOrDraught &&
//                                                               timerController2 !=
//                                                                   null
//                                                           ? timerController2!
//                                                               .stream
//                                                           : timerController
//                                                               .stream,
//                                                       time: exemptPlayer?.time,
//                                                     ),
//                                                   ),
//                                                   if ((currentPlayer == index &&
//                                                           showMessage) ||
//                                                       exemptPlayer !=
//                                                           null) ...[
//                                                     const SizedBox(height: 4),
//                                                     RotatedBox(
//                                                       quarterTurns:
//                                                           getStraightTurn(
//                                                               index),
//                                                       child: StreamBuilder<int>(
//                                                           stream:
//                                                               timerController
//                                                                   .stream,
//                                                           builder: (context,
//                                                               snapshot) {
//                                                             return Text(
//                                                               exemptPlayer !=
//                                                                       null
//                                                                   ? getExemptPlayerMessage(
//                                                                       exemptPlayer)
//                                                                   : isChessOrDraught
//                                                                       ? "Play"
//                                                                       : "Play - ${playerTime.toDurationString(false)}",
//                                                               style: TextStyle(
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                   fontSize: 14,
//                                                                   color: tint),
//                                                               textAlign:
//                                                                   TextAlign
//                                                                       .center,
//                                                             );
//                                                           }),
//                                                     ),
//                                                   ],
//                                                 ],
//                                               ),
//                                               Expanded(
//                                                 child: IgnorePointer(
//                                                   ignoring:
//                                                       exemptPlayer != null &&
//                                                           !finishedRound,
//                                                   child: Container(
//                                                     alignment:
//                                                         Alignment.bottomCenter,
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         horizontal: 20),
//                                                     child:
//                                                         buildBottomOrLeftChild(
//                                                             index),
//                                                   ),
//                                                 ),
//                                               ),
//                                               getPlayerBottomWidget(index),
//                                             ],
//                                           ),
//                                         ),
//                                         if (playersToasts[index] != "") ...[
//                                           Align(
//                                             alignment: Alignment.bottomCenter,
//                                             child: RotatedBox(
//                                               quarterTurns:
//                                                   getStraightTurn(index),
//                                               child: AppToast(
//                                                 message: playersToasts[index],
//                                                 onComplete: () {
//                                                   playersToasts[index] = "";
//                                                   setState(() {});
//                                                 },
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ));
//                         },
//                       ),
//                     ],
//                     GestureDetector(
//                         // behavior: HitTestBehavior.opaque,
//                         onTap: !isCheckoutMode
//                             ? null
//                             : () {
//                                 setState(() {
//                                   isCheckoutMode = false;
//                                 });
//                               },
//                         child: buildBody(context)),
//                   ],
//                 ),
//               ),
//               if (paused && !isCheckoutMode && pauseIndex != -1)
//                 RotatedBox(
//                   quarterTurns: getPausedGameTurn(),
//                   child: PausedGameView(
//                     context: context,
//                     reason: reason,
//                     readAboutGame: readAboutGame,
//                     game: gameName,
//                     match: match,
//                     recordId: recordId,
//                     playersScores: playersScores,
//                     users: users,
//                     players: players,
//                     playersSize: playersSize,
//                     finishedRound: finishedRound,
//                     startingRound: maxGameTime != null
//                         ? gameTime == maxGameTime
//                         : gameTime == 0,
//                     hasPlayedForAMinute: maxGameTime != null
//                         ? gameTime <= maxGameTime! - 60
//                         : gameTime >= 60,
//                     isWatch: isWatch,
//                     onStart: start,
//                     onRestart: restart,
//                     onChange: change,
//                     onLeave: (end) => leave(null, end),
//                     onConcede: concede,
//                     onPrevious: previous,
//                     onNext: next,
//                     onCheckOut: () {
//                       setState(() {
//                         isCheckoutMode = true;
//                       });
//                     },
//                     onReadAboutGame: () {
//                       if (readAboutGame) {
//                         setState(() {
//                           readAboutGame = false;
//                         });
//                       }
//                     },
//                     callMode: callMode,
//                     onToggleCall: toggleCall,
//                     isFrontCamera: isFrontCameraSelected,
//                     onToggleCamera: toggleCamera,
//                     isAudioOn: isAudioOn,
//                     onToggleMute: toggleMute,
//                     isSpeakerOn: isOnSpeaker,
//                     onToggleSpeaker: toggleSpeaker,
//                     quarterTurns: getPausedGameTurn(),
//                     pauseIndex: pauseIndex,
//                     exemptPlayers: exemptPlayers,
//                   ),
//                 ),
//               if (firstTime && !paused && !seenFirstHint) ...[
//                 Container(
//                   height: double.infinity,
//                   width: double.infinity,
//                   color: lighterBlack,
//                   padding: const EdgeInsets.all(20),
//                   alignment: Alignment.center,
//                   child: GestureDetector(
//                     behavior: HitTestBehavior.opaque,
//                     child: Center(
//                       child: Text(
//                         getFirstHint(),
//                         style:
//                             const TextStyle(color: Colors.white, fontSize: 18),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     onTap: () {
//                       setState(() {
//                         seenFirstHint = true;
//                       });
//                     },
//                   ),
//                 )
//               ],
//               // if (isCheckoutMode)
//               //   Text(
//               //     "Press back to Exit Checkout Mode",
//               //     style: context.bodySmall,
//               //   )
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   bool get wantKeepAlive => true;
// }
