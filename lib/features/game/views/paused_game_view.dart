// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/constants.dart';
import 'package:gamesarena/shared/dialogs/options_select_with_comfirmation_dialog.dart';
import 'package:gamesarena/shared/widgets/hinting_widget.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../main.dart';
import '../../../shared/dialogs/comfirmation_dialog.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/call_action_button.dart';
import '../../../theme/colors.dart';
import '../../about/utils/about_game_words.dart';
import '../../tutorials/pages/tutorials_page.dart';
import '../pages/games_page.dart';
import '../../user/models/user.dart';
import '../models/exempt_player.dart';
import '../models/game_info.dart';
import '../models/player.dart';
import '../utils.dart';
import '../widgets/game_score_item.dart';
import '../models/match.dart';

class PausedGameView extends StatefulWidget {
  final BuildContext context;
  final String game;
  final Match? match;
  final int recordId;
  final int roundId;
  final String? difficultyLevel;
  final String? exemptedRules;
  final List<String> gameRules;
  final List<int> playersScores;
  final List<User?>? users;
  final List<Player>? players;
  final int playersSize;
  final bool finishedRound;
  final bool startingRound;
  final int availablePlayersCount;

  final VoidCallback onWatch;
  final VoidCallback onRewatch;
  final VoidCallback onStart;
  final VoidCallback onRestart;
  final VoidCallback onContinue;
  final void Function(String game) onChange;
  final void Function(String difficulty) onDifficulty;
  final void Function(String exemptedRules) onExempt;

  final VoidCallback onLeave;
  final VoidCallback onClose;
  final VoidCallback onConcede;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  final VoidCallback onReadAboutGame;
  final VoidCallback onCheckOut;

  final String? callMode;
  final void Function(String? callMode) onToggleCall;
  final bool? isAudioOn;
  final VoidCallback onToggleCamera;
  final bool? isFrontCamera;
  final VoidCallback onToggleMute;
  final bool isSpeakerOn;
  final VoidCallback onToggleSpeaker;

  final bool readAboutGame;
  final bool hasPlayedForAMinute;
  final bool isWatch;
  final bool isComputer;

  final String? reason;
  final int quarterTurns;
  final List<ExemptPlayer> exemptPlayers;
  final int pauseIndex;
  final bool isWatching;
  final bool isFirstPage;
  final bool isLastPage;
  final String gameId;
  final double duration;
  final List<int>? winners;
  final double endDuration;

  const PausedGameView({
    super.key,
    required this.duration,
    required this.endDuration,
    required this.winners,
    required this.context,
    required this.game,
    required this.match,
    required this.recordId,
    required this.roundId,
    required this.difficultyLevel,
    required this.exemptedRules,
    required this.gameRules,
    required this.playersScores,
    required this.users,
    required this.players,
    required this.playersSize,
    required this.finishedRound,
    required this.startingRound,
    required this.availablePlayersCount,
    required this.onStart,
    required this.onRestart,
    required this.onContinue,
    required this.onChange,
    required this.onDifficulty,
    required this.onExempt,
    required this.onLeave,
    required this.onClose,
    required this.onConcede,
    required this.onNext,
    required this.onPrevious,
    required this.onReadAboutGame,
    required this.onCheckOut,
    this.callMode,
    required this.onToggleCall,
    required this.isAudioOn,
    required this.onToggleCamera,
    this.isFrontCamera,
    required this.onToggleMute,
    required this.isSpeakerOn,
    required this.onToggleSpeaker,
    required this.readAboutGame,
    this.hasPlayedForAMinute = false,
    this.isWatch = false,
    required this.isComputer,
    this.reason,
    required this.quarterTurns,
    required this.exemptPlayers,
    required this.pauseIndex,
    required this.isWatching,
    required this.isFirstPage,
    required this.isLastPage,
    required this.onWatch,
    required this.onRewatch,
    required this.gameId,
  });

  @override
  State<PausedGameView> createState() => _PausedGameViewState();
}

class _PausedGameViewState extends State<PausedGameView> {
  bool changeGameMode = false;
  bool checkoutMode = false;
  bool watchMode = false;

  bool aboutGameMode = false;
  bool readHint = false;
  GameInfo? gameInfo;
  ExemptPlayer? exemptPlayer;

  @override
  void initState() {
    super.initState();
    aboutGameMode = widget.readAboutGame;
    if (widget.game.isQuiz) {
      gameInfo = quizGameInfo();
    } else {
      gameInfo = gamesInfo[widget.game];
    }
  }

  bool get amAPlayer =>
      widget.players?.indexWhere((player) => player.id == myId) != -1;

  bool get showPlayGameActions =>
      widget.availablePlayersCount >= widget.playersSize &&
      ((exemptPlayer?.action != "leave" && exemptPlayer?.action != "concede") ||
          widget.finishedRound) &&
      widget.isLastPage &&
      (widget.gameId.isEmpty || (amAPlayer && widget.match?.time_end == null));

  bool itsAllZerosScores() {
    for (int i = 0; i < widget.playersScores.length; i++) {
      final score = widget.playersScores[i];
      if (score != 0) return false;
    }
    return true;
  }

  ExemptPlayer? getExemptPlayer(int player) {
    final index =
        widget.exemptPlayers.indexWhere((element) => element.index == player);
    return index != -1 ? widget.exemptPlayers[index] : null;
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

  String getPlayerUsername({String? playerId, int playerIndex = 0}) {
    final index = widget.users?.indexWhere((e) => playerId != null
            ? e?.user_id == playerId
            : (widget.players ?? []).isNotEmpty
                ? e?.user_id == widget.players![playerIndex].id
                : false) ??
        -1;

    return index != -1
        ? widget.users![index]?.user_id == myId
            ? "you"
            : widget.users![index]!.username
        : widget.playersSize == 1
            ? "you"
            : widget.isComputer
                ? playerIndex == 0
                    ? "computer"
                    : "you"
                : "Player ${playerIndex + 1}";
  }

  Future showLeaveComirmationDialog() async {
    final playersCount = widget.players != null && widget.players!.isNotEmpty
        ? widget.players!.length
        : widget.playersSize;
    if (playersCount <= 2) {
      return showComfirmationDialog("leave");
    }
    return showDialog(
        context: context,
        builder: (context) {
          return ComfirmationDialog(
              quarterTurns: widget.quarterTurns,
              title: "Do you want to leave or end game?",
              message:
                  "If you leave game others can play on but if you end game then the game ends",
              actions: const ["Leave", "End"],
              onPressed: (positive) {
                context.pop();
                showComfirmationDialog(positive ? "end" : "leave");
              });
        });
  }

  Future showExemptSelectDialog() async {
    return showDialog(
        context: context,
        builder: (context) {
          return OptionsSelectWithComfirmationDialog(
              quarterTurns: widget.quarterTurns,
              scrollDirection: Axis.vertical,
              title: "Rules Exemptions",
              message: "Select rules you would like to exempt",
              options: widget.gameRules,
              selectedOptions: stringOptionsToListValue(
                  widget.gameRules, widget.exemptedRules),
              onPressed: (options) async {
                if (options != null) {
                  widget
                      .onExempt(listOptionsToString(widget.gameRules, options));
                }

                if (!context.mounted) return;
                context.pop();
              });
        });
  }

  Future showDifficultyLevelSelectDialog() async {
    return showDialog(
        context: context,
        builder: (context) {
          return OptionsSelectWithComfirmationDialog(
              quarterTurns: widget.quarterTurns,
              scrollDirection: Axis.vertical,
              title: "Difficulty levels",
              message: "Select your prefered difficulty level",
              options: const ["Easy", "Medium", "Hard"],
              selectedOption: widget.difficultyLevel,
              onPressed: (options) async {
                if ((options ?? []).isNotEmpty) {
                  widget.onDifficulty(options!.first);
                }

                if (!context.mounted) return;
                context.pop();
              });
        });
  }

  Future showComfirmationDialog(String comfirmationType) async {
    return showDialog(
        context: context,
        builder: (context) {
          return ComfirmationDialog(
              quarterTurns: widget.quarterTurns,
              title: "Are you sure you want to $comfirmationType game?",
              message: getMoreInfoOnComfirmation(comfirmationType),
              onPressed: (positive) async {
                if (positive) {
                  switch (comfirmationType) {
                    case "restart":
                      widget.onRestart();
                      break;
                    case "rewatch":
                      widget.onRewatch();
                      break;
                    case "close":
                      widget.onClose();
                    case "leave":
                      widget.onLeave();
                      break;
                    case "change":
                      final game = await context.pushTo(
                        GamesPage(
                            gameId: widget.gameId,
                            currentGame: widget.game,
                            playersSize: widget.playersSize,
                            isCallback: true),
                      );
                      if (game != null) {
                        widget.onChange(game);
                      }
                      break;
                    case "concede":
                      widget.onConcede();
                      break;
                    case "previous":
                      widget.onPrevious();
                      break;
                    case "next":
                      widget.onNext();
                      break;
                  }
                }
                if (!context.mounted) return;
                context.pop();
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    // print("exemptedRules = ${widget.exemptedRules}");
    //widget.callMode = widget.widget.callMode;
    exemptPlayer = getExemptPlayer(widget.pauseIndex);
    final myPlayer = getMyPlayer(widget.players!);

    // print(
    //     "availablePlayersCount= ${widget.availablePlayersCount},playersSize = ${widget.playersSize}, finishedRound= ${widget.finishedRound}, exemptPlayer = $exemptPlayer, isLastPage = ${widget.isLastPage}, time_end = ${widget.match?.time_end}, amAPlayer = $amAPlayer");

    return Container(
      height: double.infinity,
      width: double.infinity,
      color: checkoutMode || watchMode
          ? Colors.transparent
          : Colors.black.withOpacity(aboutGameMode ? 0.8 : 0.5),
      alignment: Alignment.center,
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: checkoutMode || watchMode ? 0 : 5.0,
            sigmaY: checkoutMode || watchMode ? 0 : 5.0),
        child: Stack(
          children: [
            Padding(
              padding: changeGameMode
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: ConstrainedBox(
                constraints: changeGameMode
                    ? const BoxConstraints.expand()
                    : const BoxConstraints(maxWidth: 450),
                child: checkoutMode || watchMode
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                              "Tap to Exit ${watchMode ? "Watch" : "Checkout"} Mode"),
                        ),
                        onTap: () {
                          setState(() {
                            checkoutMode = false;
                            watchMode = false;
                          });
                        },
                      )
                    : aboutGameMode
                        ? Stack(
                            children: [
                              Center(
                                child: ListView(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 72, horizontal: 16),
                                  children: gameInfo == null
                                      ? []
                                      : [
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              "About Game",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Text(
                                            gameInfo!.about,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              "How to play",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          ...List.generate(
                                              gameInfo!.howtoplay.length,
                                              (index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Text(
                                                "${index + 1}. ${gameInfo!.howtoplay[index]}",
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                                textAlign: TextAlign.left,
                                              ),
                                            );
                                          }),
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              "Rules",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          ...List.generate(
                                              gameInfo!.rules.length, (index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Text(
                                                "${index + 1}. ${gameInfo!.rules[index]}",
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                                textAlign: TextAlign.left,
                                              ),
                                            );
                                          }),
                                        ],
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: AppButton(
                                  title: "Got It",
                                  onPressed: () {
                                    widget.onReadAboutGame();
                                    setState(() {
                                      aboutGameMode = false;
                                    });
                                  },
                                ),
                              )
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Record ${widget.recordId + 1} - Round ${widget.roundId + 1}",
                                            style: const TextStyle(
                                              fontSize: 30,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),

                                          Text(
                                            widget.finishedRound
                                                ? "This round: ${getMatchOutcomeMessageFromWinners(widget.winners, widget.players?.map((e) => e.id).toList() ?? [], users: widget.users, playersSize: widget.playersSize)}"
                                                : widget.startingRound
                                                    ? "New Round"
                                                    : "Ongoing Round",
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if ((widget.reason ?? "").isNotEmpty)
                                            Text(
                                              "Reason: ${widget.reason!}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          if (widget.finishedRound &&
                                              widget.playersSize > 1) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              "This record: ${getMatchOutcomeMessageFromScores(widget.playersScores, widget.players?.map((e) => e.id).toList() ?? [], users: widget.users)}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            if (widget.match != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                "Overall: ${getOverallMatchOutcomeMessage(widget.match!)}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ]
                                          ],
                                          if ((widget.difficultyLevel ?? "")
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              "Difficulty Level: ${widget.difficultyLevel}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                          if ((widget.exemptedRules ?? "")
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              "Exempted Rules: ${stringOptionsToListValue(widget.gameRules, widget.exemptedRules).join(", ")}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                          const SizedBox(height: 4),

                                          Text(
                                            widget.finishedRound
                                                ? "${widget.duration.toInt().toDurationString()} / ${widget.endDuration.toInt().toDurationString()}"
                                                : widget.duration
                                                    .toInt()
                                                    .toDurationString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),

                                          if (widget.match?.game?.groupName !=
                                              null) ...[
                                            const SizedBox(height: 20),
                                            Text(
                                              "${widget.match?.game?.groupName}",
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],

                                          const SizedBox(height: 20),
                                          SizedBox(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: List.generate(
                                                  (widget.playersSize * 2) - 1,
                                                  (index) {
                                                if (index.isOdd) {
                                                  return Container(
                                                    height: 10,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: Colors.white),
                                                  );
                                                } else {
                                                  final i = index ~/ 2;
                                                  final user =
                                                      (widget.users ?? [])
                                                              .isNotEmpty
                                                          ? widget.users![i]
                                                          : null;
                                                  final player =
                                                      (widget.users ?? [])
                                                                  .isNotEmpty &&
                                                              (widget.players ??
                                                                      [])
                                                                  .isNotEmpty &&
                                                              widget.users!
                                                                      .length ==
                                                                  widget
                                                                      .players!
                                                                      .length
                                                          ? widget.players![i]
                                                          : null;
                                                  final action = widget
                                                          .gameId.isEmpty
                                                      ? widget.pauseIndex == i
                                                          ? "pause"
                                                          : ""
                                                      : player?.action ?? "";
                                                  final exemptPlayer =
                                                      getExemptPlayer(i);
                                                  final exemptPlayerMessage =
                                                      exemptPlayer != null
                                                          ? getExemptPlayerMessage(
                                                              exemptPlayer)
                                                          : "";
                                                  final winnerMessage = widget
                                                              .winners
                                                              ?.contains(i) ??
                                                          false
                                                      ? "Winner"
                                                      : "";
                                                  final changeGameMessage = player
                                                                  ?.game !=
                                                              null &&
                                                          player!.game !=
                                                              widget.game
                                                      ? "Changed to ${player.game}"
                                                      : "";
                                                  final winnerOrExemptPlayerMessage =
                                                      winnerMessage.isNotEmpty
                                                          ? winnerMessage
                                                          : exemptPlayerMessage;
                                                  return Expanded(
                                                    child: GameScoreItem(
                                                      username:
                                                          getPlayerUsername(
                                                              playerIndex: i),
                                                      // username:
                                                      //     user?.username ??
                                                      //         "Player ${i + 1}",
                                                      profilePhoto:
                                                          user?.profile_photo,
                                                      score: widget
                                                          .playersScores[i],
                                                      overallScore: widget
                                                                      .match ==
                                                                  null ||
                                                              widget.players ==
                                                                  null
                                                          ? null
                                                          : getPlayerOverallScore(
                                                              widget.match!,
                                                              widget.players![i]
                                                                  .id),
                                                      action: widget.isLastPage
                                                          ? changeGameMessage
                                                                  .isNotEmpty
                                                              ? changeGameMessage
                                                              : winnerOrExemptPlayerMessage
                                                                      .isNotEmpty
                                                                  ? winnerOrExemptPlayerMessage
                                                                  : action
                                                          : winnerOrExemptPlayerMessage,
                                                      callMode:
                                                          player?.callMode,
                                                    ),
                                                  );
                                                }
                                              }),
                                            ),
                                          ),
                                          if (widget.isWatch) ...[
                                            AppButton(
                                              title: "Watch",
                                              onPressed: widget.onWatch,
                                              width: 150,
                                            ),
                                            if (widget.isWatching)
                                              AppButton(
                                                title: "ReWatch",
                                                onPressed: () {
                                                  showComfirmationDialog(
                                                      "rewatch");
                                                },
                                                width: 150,
                                              ),
                                          ],
                                          if (widget.finishedRound) ...[
                                            AppButton(
                                              title: "Checkout",
                                              onPressed: () {
                                                widget.onCheckOut();
                                              },
                                              width: 150,
                                            ),
                                          ],
                                          if (showPlayGameActions &&
                                              !widget.finishedRound)
                                            AppButton(
                                              title: myPlayer?.action == "start"
                                                  ? "Pause"
                                                  : widget.startingRound
                                                      ? "Start"
                                                      : "Resume",
                                              onPressed: widget.onStart,
                                              width: 150,
                                            ),

                                          if (showPlayGameActions &&
                                              widget.finishedRound) ...[
                                            AppButton(
                                              title: "Continue",
                                              onPressed: widget.onContinue,
                                              width: 150,
                                            ),
                                            if (!itsAllZerosScores())
                                              AppButton(
                                                title: "Restart",
                                                onPressed: () {
                                                  showComfirmationDialog(
                                                      "restart");
                                                },
                                                width: 150,
                                              ),
                                          ],
                                          if ((widget.finishedRound ||
                                                  widget.startingRound) &&
                                              showPlayGameActions &&
                                              widget.difficultyLevel != null)
                                            AppButton(
                                              title: "Difficulty",
                                              onPressed: () {
                                                showDifficultyLevelSelectDialog();
                                              },
                                              width: 150,
                                            ),
                                          if (showPlayGameActions &&
                                              (widget.finishedRound ||
                                                  widget.startingRound) &&
                                              widget.gameRules.isNotEmpty)
                                            AppButton(
                                              title: "Exempt",
                                              onPressed: () {
                                                showExemptSelectDialog();
                                              },
                                              width: 150,
                                            ),
                                          if (showPlayGameActions)
                                            AppButton(
                                              title: "Change",
                                              onPressed: () {
                                                showComfirmationDialog(
                                                    "change");
                                              },
                                              width: 150,
                                            ),
                                          //widget.hasPlayedForAMinute &&

                                          if ((!widget.isWatch ||
                                                  widget.isLastPage) &&
                                              showPlayGameActions &&
                                              !widget.startingRound) ...[
                                            if (!widget.finishedRound &&
                                                (exemptPlayer == null ||
                                                    (exemptPlayer!.action !=
                                                            "leave" &&
                                                        exemptPlayer!.action !=
                                                            "concede")))
                                              AppButton(
                                                title: "Concede",
                                                onPressed: () {
                                                  showComfirmationDialog(
                                                      "concede");
                                                },
                                                width: 150,
                                                bgColor: Colors.yellow,
                                                color: Colors.black,
                                              ),
                                            if ((exemptPlayer == null ||
                                                exemptPlayer!.action !=
                                                    "leave"))
                                              AppButton(
                                                title: "Leave",
                                                onPressed: () {
                                                  showComfirmationDialog(
                                                      "leave");
                                                },
                                                width: 150,
                                                bgColor: Colors.red,
                                              ),
                                          ],

                                          AppButton(
                                            title: "Close",
                                            onPressed: () {
                                              showComfirmationDialog("close");
                                            },
                                            width: 150,
                                            bgColor: Colors.red,
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!widget.isFirstPage)
                                                CallActionButton(
                                                  icon: EvaIcons
                                                      .arrow_back_outline,
                                                  bgColor: primaryColor,
                                                  onPressed: widget.onPrevious,
                                                ),
                                              if (!widget.isFirstPage &&
                                                  !widget.isLastPage)
                                                const SizedBox(width: 10),
                                              if (!widget.isLastPage)
                                                CallActionButton(
                                                  icon: EvaIcons
                                                      .arrow_forward_outline,
                                                  bgColor: primaryColor,
                                                  onPressed: widget.onNext,
                                                ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    aboutGameMode = true;
                                                  });
                                                },
                                                child: const Text(
                                                  "About Game",
                                                  // style: context.bodyMedium
                                                  //     ?.copyWith(
                                                  //         fontWeight:
                                                  //             FontWeight.bold),
                                                ),
                                              ),
                                              // const SizedBox(width: 10),
                                              TextButton(
                                                onPressed: () {
                                                  context.pushTo(TutorialsPage(
                                                    type: widget.game.isQuiz
                                                        ? "quiz"
                                                        : widget.game
                                                            .toLowerCase(),
                                                  ));
                                                },
                                                child: const Text(
                                                    "Watch Tutorial"),
                                              ),
                                            ],
                                          ),
                                          // const SizedBox(height: 100),
                                        ]),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 20),
                                child: Text(
                                  "Voice and Video Call Coming Soon. Call with other platforms like WhatsApp for now. Enjoy",
                                  style:
                                      context.bodySmall?.copyWith(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              // if (showPlayGameActions &&
                              //     widget.users != null &&
                              //     widget.users!.isNotEmpty &&
                              //     !checkoutMode &&
                              //     !watchMode &&
                              //     !aboutGameMode)
                              //   const SizedBox(height: 60),
                            ],
                          ),
              ),
            ),
            // if (showPlayGameActions &&
            //     widget.users != null &&
            //     widget.users!.isNotEmpty &&
            //     !checkoutMode &&
            //     !watchMode &&
            //     !aboutGameMode) ...[
            //   Positioned(
            //     bottom: 20,
            //     left: 0,
            //     right: 0,
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         if (widget.callMode != null)
            //           CallActionButton(
            //             icon: EvaIcons.phone_off,
            //             bgColor: Colors.red,
            //             onPressed: () {
            //               widget.onToggleCall(null);
            //             },
            //           )
            //         else
            //           CallActionButton(
            //               icon: EvaIcons.phone,
            //               onPressed: () {
            //                 widget.onToggleCall("voice");
            //               }),
            //         const SizedBox(width: 20),
            //         CallActionButton(
            //           icon: EvaIcons.video,
            //           selected: widget.callMode == "video",
            //           onPressed: () {
            //             widget.onToggleCall(widget.callMode == null ||
            //                     widget.callMode == "voice"
            //                 ? "video"
            //                 : "voice");
            //             //setState(() {});
            //           },
            //         ),
            //         if (widget.callMode != null) ...[
            //           const SizedBox(width: 20),
            //           CallActionButton(
            //               icon: EvaIcons.mic_off,
            //               selected: widget.isAudioOn == null ||
            //                   widget.isAudioOn == false,
            //               onPressed: widget.onToggleMute),
            //           if (widget.callMode == "video") ...[
            //             const SizedBox(width: 20),
            //             CallActionButton(
            //                 icon: EvaIcons.flip,
            //                 onPressed: widget.onToggleCamera),
            //             const SizedBox(width: 20)
            //           ],
            //           const SizedBox(width: 20),
            //           CallActionButton(
            //               icon: EvaIcons.speaker,
            //               selected: widget.isSpeakerOn,
            //               onPressed: widget.onToggleSpeaker),
            //         ]
            //       ],
            //     ),
            //   )
            // ],
          ],
        ),
      ),
    );
  }
}
