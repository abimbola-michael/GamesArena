import 'package:gamesarena/features/games/word_puzzle/pages/word_puzzle_game_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../user/widgets/user_item.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/constants.dart';
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
  List<PlayersFormation> players_formation = [];
  List<Playing> playing = [], ready_playing = [];
  String game = "";
  String gameState = "unstarted";
  int currentGame = 0;
  int playersSize = 2;
  List<int> sizes = [2, 3, 4];
  int selected = 0;
  @override
  void initState() {
    super.initState();
    //playersSize = widget.playersSize;
    game = widget.game;
    getGame();
  }

  void gotoGame() {
    gotoGamePage(context, game, "", "", null, playersSize, null, 0);
    // Widget widget = const BatballGamePage();
    // if (game == batballGame) {
    //   widget = const BatballGamePage();
    // } else if (game == whotGame) {
    //   widget = WhotGamePage(
    //     playersSize: playersSize,
    //   );
    // } else if (game == ludoGame) {
    //   widget = LudoGamePage(
    //     playersSize: playersSize,
    //   );
    // } else if (game == draughtGame) {
    //   widget = const DraughtGamePage();
    // } else if (game == chessGame) {
    //   widget = const ChessGamePage();
    // } else if (game == xandoGame) {
    //   widget = const XandOGamePage();
    // } else if (game == wordPuzzleGame) {
    //   widget = const WordPuzzleGamePage();
    // }
    // Navigator.of(context)
    //     .pushReplacement(MaterialPageRoute(builder: ((context) => widget)));
  }

  void getGame() {
    List<int> orders = List.generate(playersSize, (index) => index + 1);
    orders.shuffle();
    playing = List.generate(
      playersSize,
      (index) => Playing(
          id: "$index",
          action: "start",
          game: game,
          order: orders[index],
          accept: true),
    );
    playing.sortList((value) => value.order, false);
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

  // void getGameFormation() {
  //   int i = 0;
  //   List<PlayersFormation> playersFormation = [];
  //   while (i < playing.length) {
  //     final user1 = users[i];
  //     final user2 = (i + 1) < playing.length ? users[i + 1] : null;
  //     final playing1 = playing[i];
  //     final playing2 = (i + 1) < playing.length ? playing[i + 1] : null;
  //     playersFormation.add(PlayersFormation(
  //         player1: playing1.id,
  //         player2: playing2?.id ?? "",
  //         player1Score: 0,
  //         player2Score: 0,
  //         user1: user1,
  //         user2: user2));
  //     i += playersSize;
  //   }
  //   players_formation = playersFormation;
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text("New Game"),
        leading: BackButton(onPressed: () {
          Navigator.of(context).pop();
        }),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                "Offline $game game",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (game == "Ludo" || game == "Whot") ...[
              Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: selected == index
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          "${sizes[index]}",
                          style: TextStyle(
                              color: selected == index ? Colors.white : tint,
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
          ]),
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
    ));
  }
}
