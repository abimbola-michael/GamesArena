import 'package:gamesarena/features/games/puzzle/word_puzzle/pages/word_puzzle_game_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/models/models.dart';

import '../../../shared/utils/constants.dart';
import '../utils.dart';

class NewComputerOrAloneGamePage extends StatefulWidget {
  final String game;
  final String difficultyLevel;
  final bool isComputer;
  //final int playersSize;
  const NewComputerOrAloneGamePage(
      {super.key,
      required this.game,
      required this.difficultyLevel,
      required this.isComputer});

  @override
  State<NewComputerOrAloneGamePage> createState() =>
      _NewComputerOrAloneGamePageState();
}

class _NewComputerOrAloneGamePageState
    extends State<NewComputerOrAloneGamePage> {
  List<User?> users = [];
  bool creatorIsMe = false;
  List<Player> players = [];
  String game = "";
  String gameState = "unstarted";
  int currentGame = 0;
  int playersSize = 2;
  int selected = 0;
  List<String> onePlayerOfflineGame = [];
  @override
  void initState() {
    super.initState();
    //playersSize = widget.playersSize;
    game = widget.game;
    playersSize = widget.isComputer ? 2 : 1;
    getGame();
  }

  void gotoGame() {
    gotoGamePage(context, game, "", "",
        playersSize: playersSize,
        isComputer: widget.isComputer,
        difficultyLevel: widget.difficultyLevel,
        result: true);
  }

  void getGame() {
    if (allPuzzleGames.contains(game) || game.isQuiz) {
      playersSize = 1;
    }

    List<int> orders = List.generate(playersSize, (index) => index + 1);
    orders.shuffle();
    players = List.generate(
      playersSize,
      (index) => Player(
        id: "$index",
        action: "start",
        game: game,
        order: orders[index], time: timeNow,
        // accept: true,
      ),
    );
    players.sortList((value) => value.order, false);
    users = List.generate(
        playersSize,
        (index) => User(
            user_id: "$index",
            username: index == 0
                ? widget.isComputer
                    ? "Computer"
                    : "You"
                : "You",
            email: "",
            phone: "",
            time: "",
            last_seen: "",
            tokens: []));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: "New Game"),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    "${widget.isComputer ? "Computer" : "Alone"} $game game (${widget.difficultyLevel})",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 200,
                  //width: double.infinity,
                  child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return UserItem(
                          user: user,
                          type: "",
                          onPressed: () {},
                        );
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        //height: 50,
        width: double.infinity,
        //margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AppButton(
                title: "Cancel",
                onPressed: () {
                  Navigator.of(context).pop();
                },
                bgColor: Colors.red,
              ),
            ),
            // const SizedBox(
            //   width: 20,
            // ),
            Expanded(
              child: AppButton(
                title: "Start",
                onPressed: () {
                  gotoGame();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
