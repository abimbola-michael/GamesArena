import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../components/action_button.dart';
import '../components/game_score_item.dart';
import '../models/game_info.dart';
import '../models/user.dart';
import '../utils/utils.dart';
import 'about_game_words.dart';

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
  final VoidCallback onChange;
  final VoidCallback onLeave;
  final VoidCallback onReadAboutGame;
  final bool readAboutGame;
  final String? reasonMessage;

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
    required this.onReadAboutGame,
    required this.context,
    this.reasonMessage,
  });

  @override
  State<PausedGamePage> createState() => _PausedGamePageState();
}

class _PausedGamePageState extends State<PausedGamePage> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: checkoutMode
          ? Colors.transparent
          : Colors.black.withOpacity(aboutGameMode ? 0.8 : 0.5),
      alignment: Alignment.center,
      child: SizedBox(
        child: comfirmationType != ""
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Are you sure you want to ${comfirmationType == "new" ? "start new game from 0 - 0" : "$comfirmationType game"}?",
                    style: const TextStyle(fontSize: 30, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          "Cancel",
                          onPressed: () {
                            setState(() {
                              comfirmationType = "";
                            });
                          },
                          height: 50,
                          color: Colors.blue,
                          textColor: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: ActionButton(
                          comfirmationType.capitalize,
                          onPressed: () {
                            if (comfirmationType == "new") {
                              widget.onRestart();
                            } else if (comfirmationType == "leave") {
                              widget.onLeave();
                            } else if (comfirmationType == "change") {
                              widget.onChange();
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
                                            fontSize: 16, color: Colors.white),
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
                                          gameInfo!.howtoplay.length, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
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
                                      ...List.generate(gameInfo!.rules.length,
                                          (index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
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
                            child: ActionButton("Got It", onPressed: () {
                              widget.onReadAboutGame();
                              setState(() {
                                aboutGameMode = false;
                              });
                            }, height: 50, half: true),
                          )
                        ],
                      )
                    : Center(
                        child: SingleChildScrollView(
                          primary: true,
                          scrollDirection: Axis.vertical,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              widget.finishedRound
                                  ? getWinnerMessage(
                                      widget.playersScores, widget.users)
                                  : "Game Paused",
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.reasonMessage != null &&
                                widget.finishedRound) ...[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  widget.reasonMessage!,
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            SizedBox(
                              //height: 180,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                    (widget.playersSize * 2) - 1, (index) {
                                  if (index.isOdd) {
                                    return const Text(
                                      '-',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 60,
                                          color: Colors.white),
                                      textAlign: TextAlign.center,
                                    );
                                  } else {
                                    final i = index ~/ 2;
                                    return GameScoreItem(
                                      username: widget.users != null
                                          ? widget.users![i]?.username ?? ""
                                          : "Player ${i + 1}",
                                      score: widget.playersScores[i],
                                      action: widget.users != null
                                          ? widget.users![i]?.action ?? ""
                                          : "",
                                    );
                                  }
                                }),
                              ),
                            ),
                            if (widget.finishedRound) ...[
                              ActionButton("Checkout", onPressed: () {
                                setState(() {
                                  checkoutMode = true;
                                });
                              }, height: 50, half: true),
                            ],
                            ActionButton(
                                widget.finishedRound
                                    ? "Continue"
                                    : widget.startingRound
                                        ? "Start"
                                        : "Resume",
                                onPressed: widget.onStart,
                                height: 50,
                                half: true),
                            if (widget.finishedRound) ...[
                              ActionButton("Restart", onPressed: () {
                                setState(() {
                                  comfirmationType = "new";
                                });
                              }, height: 50, half: true),
                            ],
                            // if (widget.finishedRound || widget.startingRound) ...[

                            // ],
                            ActionButton("Change", onPressed: () {
                              setState(() {
                                comfirmationType = "change";
                              });
                            }, height: 50, half: true),
                            ActionButton("Leave", onPressed: () {
                              setState(() {
                                comfirmationType = "leave";
                              });
                            }, height: 50, half: true),
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
    );
  }
}
