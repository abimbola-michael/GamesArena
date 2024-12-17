import 'package:gamesarena/features/games/puzzle/word_puzzle/pages/word_puzzle_game_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../shared/widgets/app_appbar.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/constants.dart';
import '../models/player.dart';
import '../utils.dart';

class NewOfflineGamePage extends StatefulWidget {
  final String game;
  //final int playersSize;
  const NewOfflineGamePage({super.key, required this.game});

  @override
  State<NewOfflineGamePage> createState() => _NewOfflineGamePageState();
}

class _NewOfflineGamePageState extends State<NewOfflineGamePage> {
  List<User?> users = [];
  bool creatorIsMe = false;
  List<Player> players = [];
  String game = "";
  String gameState = "unstarted";
  int currentGame = 0;
  int playersSize = 2;
  List<int> sizes = [2, 3, 4];
  int selected = 0;
  List<String> onePlayerOfflineGame = [];
  @override
  void initState() {
    super.initState();
    //playersSize = widget.playersSize;
    game = widget.game;
    getGame();
  }

  void gotoGame() {
    gotoGamePage(context, game, "", "", playersSize: playersSize);
  }

  void getGame() {
    if (allPuzzleGames.contains(game) || game.endsWith("Quiz")) {
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
            username: "Player ${index + 1}",
            email: "",
            phone: "",
            time: "",
            last_seen: "",
            token: ""));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: "New Game",
      ),
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
                    "Offline $game game",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (game == "Ludo" || game == "Whot") ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16, bottom: 16),
                    child: Row(
                        children: List.generate(sizes.length, (index) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            selected = index;
                            playersSize = sizes[index];
                            getGame();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                                color: selected == index
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30)),
                            child: Text(
                              "${sizes[index]}",
                              style: TextStyle(
                                  color:
                                      selected == index ? Colors.white : tint,
                                  fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    })),
                  ),
                ],
                const SizedBox(
                  height: 20,
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
      bottomNavigationBar: Container(
        height: 50,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActionButton(
              "Cancel",
              onPressed: () {
                Navigator.of(context).pop();
              },
              height: 50,
              width: 150,
              margin: 0,
              color: darkMode ? lightestWhite : lightestBlack,
              textColor: darkMode ? white : black,
            ),
            const SizedBox(
              width: 20,
            ),
            ActionButton(
              "Start",
              onPressed: () {
                gotoGame();
              },
              height: 50,
              width: 150,
              margin: 0,
              color: Colors.blue,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
