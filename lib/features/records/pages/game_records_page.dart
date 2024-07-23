import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/home/tabs/games_page.dart';
import 'package:flutter/material.dart';
import '../../../shared/services.dart';
import 'package:gamesarena/features/game/models/match.dart';

import '../../../shared/widgets/action_button.dart';
import '../../game/services.dart';
import '../../game/widgets/match_list_item.dart';
import '../../game/models/game.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';

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
    myId = myId;
    getGameRecords();
  }

  void getGameRecords() async {
    Game? game;
    if (game_id != "") {
      game = await getGame(game_id);
    } else {
      game = await getGameFromPlayers(id);
      game_id = game?.game_id ?? "";
    }
    if (game != null) {
      this.game = game;
      matchesStream = readGameMatchesStream(game.game_id);
      players = game.players.split(",");
      List<String> ids = [];
      ids.addAll(players);
      users = await playersToUsers(ids);
      ids.remove(myId);
      id = ids.last;
      final opponentUsers =
          users.where((element) => element.user_id != myId).toList();
      name = opponentUsers.toStringWithCommaandAnd((user) => user.username);
    }
    setState(() {});
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
                  child: Text("Something went wrong"),
                )
              : StreamBuilder<List<Match>>(
                  stream: matchesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
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
                      return Container();
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
}
