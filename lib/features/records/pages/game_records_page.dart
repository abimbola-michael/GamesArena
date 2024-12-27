import 'package:gamesarena/features/game/models/game_list.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/home/tabs/games_page.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:hive_flutter/adapters.dart';
import '../../../shared/services.dart';
import 'package:gamesarena/features/game/models/match.dart';

import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../theme/colors.dart';
import '../../game/services.dart';
import '../../game/utils.dart';
import '../../game/widgets/match_list_item.dart';
import '../../game/models/game.dart';
import '../../game/widgets/players_profile_photo.dart';
import '../../game/widgets/profile_photo.dart';
import '../../players/pages/players_selection_page.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';
import 'game_profile_page.dart';

class GameRecordsPage extends StatefulWidget {
  final GameList? gameList;
  final String game_id;
  final String id;
  final String type;
  const GameRecordsPage(
      {super.key,
      required this.game_id,
      required this.id,
      required this.type,
      this.gameList});

  @override
  State<GameRecordsPage> createState() => _GameRecordsPageState();
}

class _GameRecordsPageState extends State<GameRecordsPage> {
  String name = "";
  String type = "", id = "", game_id = "";
  Game? game;
  List<Match> matches = [];
  List<User> users = [];
  List<String> players = [];
  GameList? gameList;
  Box<String>? gameListsBox;
  bool loading = false;
  //Stream<List<Match>>? matchesStream;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    id = widget.id;
    game_id = widget.game_id;
    getDetails();
  }

  Future<void> getDetails() async {
    //final matchesBox = Hive.box<String>("matches");
    gameListsBox = Hive.box<String>("gamelists");
    final gameListValue = gameListsBox!.get(game_id);
    gameList ??=
        gameListValue == null ? null : GameList.fromJson(gameListValue);
    if (gameList == null) return;
    if (gameList!.game != null &&
        gameList!.game!.groupName == null &&
        gameList!.game!.players != null &&
        gameList!.game!.users == null) {
      players = gameList!.game!.players!;

      List<User> users = await playersToUsers(players);

      gameList!.game!.users = users;
    }
    if (!mounted) return;
    setState(() {});
  }

  void loadPreviousMatches(String lastTime) async {
    //setState(() {
    loading = true;
    //});
    //lastTime,
    final matches =
        await getPreviousMatches(game_id, time: lastTime, limit: 10);
    final matchesBox = Hive.box<String>("matches");

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      matchesBox.put(match.match_id, match.toJson());
    }
    //setState(() {
    loading = false;
    //});
  }

  void gotoGameProfile() {
    if (gameList == null) return;
    context.pushTo(GameProfilePage(gameList: gameList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        middle: GestureDetector(
          onTap: gotoGameProfile,
          child: Row(
            children: [
              if (gameList?.game?.users != null)
                PlayersProfilePhoto(
                  users: gameList!.game!.users!,
                  withoutMyId: true,
                )
              else if ((gameList?.game?.groupName ?? "").isNotEmpty)
                ProfilePhoto(
                  profilePhoto: gameList!.game!.profilePhoto ?? "",
                  name: gameList!.game!.groupName!,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gameList?.game?.users != null
                          ? getOtherPlayersUsernames(gameList!.game!.users!)
                          : gameList!.game?.groupName != null
                              ? gameList!.game!.groupName!
                              : "",
                      style: TextStyle(
                        fontSize: 18,
                        color: tint,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      // body: matchesStream == null
      //     ? const Center(
      //         child: Text("Something went wrong"),
      //       )
      //     : StreamBuilder<List<Match>>(
      //         stream: matchesStream,
      //         builder: (context, snapshot) {
      //           if (snapshot.connectionState == ConnectionState.waiting) {
      //             return const Center(
      //               child: CircularProgressIndicator(),
      //             );
      //           }
      //           if (snapshot.hasError) {
      //             return const Center(
      //               child: Text("Something went wrong"),
      //             );
      //           } else if (snapshot.hasData) {
      //             matches = snapshot.data!;
      //             if (matches.isEmpty) {
      //               return const Center(
      //                 child: Text("No Match"),
      //               );
      //             } else {
      //               matches.sortList((match) => match.time_created, true);
      //             }
      //             return ListView.builder(
      //                 itemCount: matches.length,
      //                 itemBuilder: (context, index) {
      //                   return MatchListItem(
      //                     gameId: game_id,
      //                     position: index,
      //                     matches: matches,
      //                     users: users,
      //                   );
      //                 });
      //           } else {
      //             return Container();
      //           }
      //         },
      //       ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<String>("matches").listenable(),
        builder: (context, value, child) {
          final matches = value.values
              .map((map) => Match.fromJson(map))
              .where((match) => match.game_id == game_id)
              .toList();
          if (matches.isEmpty) {
            return const Center(
              child: Text("No Match"),
            );
          }

          matches.sortList((match) => match.time_created, true);
          if (gameList != null && (gameList?.unseen ?? 0) > 0) {
            gameList!.unseen = 0;
            gameListsBox!.put(game_id, gameList!.toJson());
          }
          if (matches.isNotEmpty) {
            final lastMatch = matches.last;
            if (gameList != null &&
                lastMatch.time_created != null &&
                gameList!.lastSeen != lastMatch.time_created!) {
              gameList!.lastSeen = lastMatch.time_created!;
              gameListsBox!.put(game_id, gameList!.toJson());
              updateLastSeen(game_id, lastMatch.time_created!);
            }
          }

          return ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                if (index == matches.length - 1 &&
                    gameList?.game?.firstMatchTime !=
                        matches.last.time_created! &&
                    !loading) {
                  loadPreviousMatches(matches.last.time_created!);
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MatchListItem(
                      key: Key(match.match_id ?? "$index"),
                      position: index,
                      matches: matches,
                    ),
                    if (index == matches.length - 1 && loading)
                      const CircularProgressIndicator()
                  ],
                );
              });
        },
      ),
      // players.isEmpty
      // ? null
      // :
      bottomNavigationBar: AppButton(
        title: "Play",
        onPressed: () {
          context.pushTo(
            GamesPage(
              gameId: gameList?.game_id,
              players: gameList?.game?.players,
              groupName: gameList?.game?.groupName,
            ),
          );
        },
      ),
    );
  }
}
