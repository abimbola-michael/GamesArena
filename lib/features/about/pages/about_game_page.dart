// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';

import '../../../shared/utils/constants.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_button.dart';
import '../../game/models/game_info.dart';
import '../utils/about_game_words.dart';

class AboutGamePage extends StatefulWidget {
  final String game;
  const AboutGamePage({
    super.key,
    required this.game,
  });

  @override
  State<AboutGamePage> createState() => _AboutGamePageState();
}

class _AboutGamePageState extends State<AboutGamePage> {
  GameInfo? gameInfo;
  @override
  void initState() {
    super.initState();
    if (widget.game.isQuiz) {
      gameInfo = quizGameInfo();
    } else {
      gameInfo = gamesInfo[widget.game];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: "About ${widget.game}",
      ),
      body: Center(
        child: ListView(
          primary: true,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(fontSize: 16),
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
                  ...List.generate(gameInfo!.howtoplay.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "${index + 1}. ${gameInfo!.howtoplay[index]}",
                        style: const TextStyle(fontSize: 16),
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
                  ...List.generate(gameInfo!.rules.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "${index + 1}. ${gameInfo!.rules[index]}",
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.left,
                      ),
                    );
                  }),
                ],
        ),
      ),
      bottomNavigationBar: AppButton(
          title: "Got It",
          onPressed: () {
            Navigator.of(context).pop();
          },
          height: 50),
    );
  }
}
