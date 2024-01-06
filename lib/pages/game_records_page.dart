import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/pages/tabs/games_page.dart';
import 'package:flutter/material.dart';
import '../blocs/firebase_service.dart';
import '../components/components.dart';
import 'package:gamesarena/models/match.dart';

import '../components/match_list_item.dart';
import '../models/game.dart';
import '../models/user.dart';

class GameRecordsPage extends StatefulWidget {
  final String game_id;
  final String id;
  final String type;
  const GameRecordsPage(
      {super.key, required this.game_id, required this.id, required this.type});

  @override
  State<GameRecordsPage> createState() => _GameRecordsPageState();
}

class _GameRecordsPageState extends State<GameRecordsPage> {
  String name = "";
  String type = "", id = "", game_id = "", myId = "";
  FirebaseService fs = FirebaseService();
  Game? game;
  List<Match> matches = [];
  List<User> users = [];
  List<String> players = [];
  Stream<List<Match>>? matchesStream;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    id = widget.id;
    game_id = widget.game_id;
    myId = fs.myId;
    getGameRecords();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Text(
          name,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        // title: Row(
        //   children: [
        //     CircleAvatar(
        //       radius: 20,
        //       backgroundColor:
        //           darkMode ? lightestWhite : lightestBlack,
        //       child: Text(
        //         name.firstChar ?? "",
        //         style: const TextStyle(fontSize: 30, color: Colors.blue),
        //       ),
        //     ),
        //     const SizedBox(
        //       width: 8,
        //     ),
        //     Text(
        //       name,
        //       overflow: TextOverflow.ellipsis,
        //       maxLines: 2,
        //     ),
        //   ],
        // ),
      ),
      body: Stack(
        children: [
          matchesStream == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : StreamBuilder<List<Match>>(
                  stream: matchesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Something went wrong"),
                      );
                    } else if (snapshot.hasData) {
                      matches = snapshot.data!;
                      if (matches.isEmpty) {
                        return const Center(
                          child: Text("No Match"),
                        );
                      } else {
                        matches.sortList((match) => match.time_created, true);
                      }
                      return ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            return MatchListItem(
                              gameId: game_id,
                              position: index,
                              matches: matches,
                              users: users,
                            );
                          });
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  })
        ],
      ),
      bottomNavigationBar: players.isEmpty
          ? null
          : ActionButton(
              "Play",
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: ((context) => GamesPage(
                          players: players,
                        ))));
              },
              height: 50,
              color: Colors.blue,
              half: true,
            ),
    ));
  }

  void getGameRecords() async {
    Game? game;
    if (game_id != "") {
      game = await fs.getGame(game_id);
    } else {
      game = await fs.getGameFromPlayers(id);
      game_id = game?.game_id ?? "";
    }
    if (game != null) {
      this.game = game;
      matchesStream = fs.readGameMatchesStream(game.game_id);
      players = game.players.split(",");
      List<String> ids = [];
      ids.addAll(players);
      users = await fs.playersToUsers(ids);
      ids.remove(myId);
      id = ids.last;
      final opponentUsers =
          users.where((element) => element.user_id != myId).toList();
      name = opponentUsers.toStringWithCommaandAnd((user) => user.username);
    }
    setState(() {});
  }
}
