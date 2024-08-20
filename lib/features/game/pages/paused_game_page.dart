import 'dart:ui';

import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/widgets/action_button.dart';
import '../widgets/game_score_item.dart';
import '../models/game_info.dart';
import '../../user/models/user.dart';
import '../../../shared/utils/utils.dart';
import '../../about/utils/about_game_words.dart';
import '../../home/tabs/games_page.dart';

class PausedGamePage extends StatefulWidget {
  final BuildContext context;
  final String game;
  final List<int> playersScores;
  final List<User?>? users;
  final int playersSize;
  final bool finishedRound;
  final bool startingRound;
  final VoidCallback onStart;
  final VoidCallback onRestart;
  final void Function(String game) onChange;
  final VoidCallback onLeave;
  final VoidCallback? onConcede;
  final VoidCallback onReadAboutGame;
  final bool readAboutGame;
  final bool playing;

  final String? reason;

  const PausedGamePage({
    super.key,
    required this.readAboutGame,
    required this.game,
    required this.playersScores,
    required this.users,
    required this.playersSize,
    required this.finishedRound,
    required this.startingRound,
    required this.onStart,
    required this.onRestart,
    required this.onChange,
    required this.onLeave,
    this.onConcede,
    required this.onReadAboutGame,
    required this.context,
    this.reason,
    this.playing = false,
  });

  @override
  State<PausedGamePage> createState() => _PausedGamePageState();
}

class _PausedGamePageState extends State<PausedGamePage> {
  bool changeGameMode = false;
  bool checkoutMode = false;
  bool aboutGameMode = false;
  bool readHint = false;
  String comfirmationType = "";
  GameInfo? gameInfo;

  @override
  void initState() {
    super.initState();
    aboutGameMode = widget.readAboutGame;
    gameInfo = gamesInfo[widget.game];
  }

  String getMoreInfoOnComfirmation() {
    String message = "";
    switch (comfirmationType) {
      case "restart":
        message = "This means to start a new game from 0 - 0";
        break;
      case "change":
        message = "This means this game ends and a new game is started";
        break;
      case "leave":
        message = "This means you are out of the game";
        break;
      case "concede":
        message =
            "This means you accept that you have lost the game and your opponent wins";
        break;
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: checkoutMode
          ? Colors.transparent
          : Colors.black.withOpacity(aboutGameMode ? 0.8 : 0.5),
      alignment: Alignment.center,
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: checkoutMode ? 0 : 5.0, sigmaY: checkoutMode ? 0 : 5.0),
        child: Padding(
          padding: changeGameMode
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: ConstrainedBox(
            constraints: changeGameMode
                ? const BoxConstraints.expand()
                : const BoxConstraints(maxWidth: 450),
            child: comfirmationType != ""
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Are you sure you want to $comfirmationType game?",
                        style:
                            const TextStyle(fontSize: 30, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        getMoreInfoOnComfirmation(),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              "No",
                              onPressed: () {
                                setState(() {
                                  comfirmationType = "";
                                });
                              },
                              height: 50,
                              color: Colors.red,
                              textColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ActionButton(
                              "Yes",
                              //comfirmationType.capitalize,
                              onPressed: () {
                                if (comfirmationType == "restart") {
                                  widget.onRestart();
                                } else if (comfirmationType == "leave") {
                                  widget.onLeave();
                                } else if (comfirmationType == "change") {
                                  changeGameMode = true;
                                  //widget.onChange();
                                } else if (comfirmationType == "concede") {
                                  widget.onConcede?.call();
                                }
                                setState(() {
                                  comfirmationType = "";
                                });
                              },
                              height: 50,
                              color: Colors.blue,
                              textColor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                : checkoutMode
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: const Center(
                          child: Text("Tap to Exit Checkout Mode"),
                        ),
                        onTap: () {
                          setState(() {
                            checkoutMode = false;
                          });
                        },
                      )
                    : aboutGameMode
                        ? Stack(
                            children: [
                              Center(
                                child: ListView(
                                  shrinkWrap: true,
                                  primary: true,
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
                                child: ActionButton(
                                  "Got It",
                                  onPressed: () {
                                    widget.onReadAboutGame();
                                    setState(() {
                                      aboutGameMode = false;
                                    });
                                  },
                                  height: 50,
                                ),
                              )
                            ],
                          )
                        : changeGameMode
                            ? GamesPage(
                                currentGame: widget.game,
                                isChangeGame: true,
                                onBackPressed: () {
                                  setState(() {
                                    changeGameMode = false;
                                  });
                                },
                                gameCallback: (game) {
                                  widget.onChange(game);
                                  setState(() {
                                    changeGameMode = false;
                                  });
                                },
                              )
                            : Center(
                                child: SingleChildScrollView(
                                  primary: true,
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.finishedRound
                                              ? getWinnerMessage(
                                                  widget.playersScores,
                                                  widget.users)
                                              : "Game Paused",
                                          style: const TextStyle(
                                            fontSize: 30,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (widget.reason != null &&
                                            widget.finishedRound) ...[
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              widget.reason!.capitalize,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(
                                          height: 20,
                                        ),
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
                                                  width: 30,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Colors.white),
                                                );
                                              } else {
                                                final i = index ~/ 2;
                                                return GameScoreItem(
                                                  username: widget.users != null
                                                      ? widget.users![i]
                                                              ?.username ??
                                                          ""
                                                      : "Player ${i + 1}",
                                                  score:
                                                      widget.playersScores[i],
                                                  action: widget.users != null
                                                      ? widget.users![i]
                                                              ?.action ??
                                                          ""
                                                      : "",
                                                );
                                              }
                                            }),
                                          ),
                                        ),
                                        if (widget.finishedRound) ...[
                                          ActionButton(
                                            "Checkout",
                                            onPressed: () {
                                              setState(() {
                                                checkoutMode = true;
                                              });
                                            },
                                            width: 150,
                                            height: 50,
                                          ),
                                        ],
                                        ActionButton(
                                          widget.finishedRound
                                              ? "Continue"
                                              : widget.startingRound
                                                  ? "Start"
                                                  : "Resume",
                                          onPressed: widget.onStart,
                                          width: 150,
                                          height: 50,
                                        ),
                                        if (widget.playing &&
                                            !widget.finishedRound)
                                          ActionButton(
                                            "Concede",
                                            onPressed: () {
                                              setState(() {
                                                comfirmationType = "concede";
                                              });
                                            },
                                            width: 150,
                                            height: 50,
                                          ),
                                        if (widget.finishedRound) ...[
                                          ActionButton(
                                            "Restart",
                                            onPressed: () {
                                              setState(() {
                                                comfirmationType = "restart";
                                              });
                                            },
                                            width: 150,
                                            height: 50,
                                          ),
                                        ],
                                        // if (widget.finishedRound || widget.startingRound) ...[

                                        // ],
                                        ActionButton(
                                          "Change",
                                          onPressed: () {
                                            setState(() {
                                              comfirmationType = "change";
                                            });
                                          },
                                          width: 150,
                                          height: 50,
                                        ),
                                        ActionButton(
                                          "Leave",
                                          onPressed: () {
                                            setState(() {
                                              comfirmationType = "leave";
                                            });
                                          },
                                          width: 150,
                                          height: 50,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              aboutGameMode = true;
                                            });
                                          },
                                          child: const Text("About Game"),
                                        ),
                                      ]),
                                ),
                              ),
          ),
        ),
      ),
    );
  }
}
